/*
 * scheduler.c
 *
 * this file is part of GLADBOOKS
 *
 * Copyright (c) 2012, 2013 Brett Sheffield <brett@gladserv.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program (see the file COPYING in the distribution).
 * If not, see <http://www.gnu.org/licenses/>.
 */

#define _GNU_SOURCE
#include "scheduler.h"
#include "handler.h"
#include <signal.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/ipc.h>
#include <sys/msg.h>
#include <sys/types.h>
#include <syslog.h>
#include <time.h>
#include <unistd.h>

int msqid;
struct sched_timer *tlist = NULL;
struct sched_timer *tlast = NULL;
int nexttimer = 0;

int start_scheduler()
{
        sched_proc = fork();
        if (sched_proc == -1) {
                /* failed to fork */
                return -1;
        }
        else if (sched_proc == 0) {
                scheduler();
        }
        return 0;
}

void scheduler()
{
        key_t key;
        struct sched_msgbuf msgin;
        pid_t pid = getpid();
        size_t size = sizeof(struct sched_msgbuf)-sizeof(long);

        /* set up signal handlers */
        signal(SIGTERM, stop_scheduler);
        signal(SIGUSR1, handle_usr1);

        /* create/connect to message queue */
        key = ftok(IPCENTER_QUEUE, 'a');
        msqid = msgget(key, 0666 | IPC_CREAT);

        for (;;) {
                /* check for messages */
                msgrcv(msqid, &msgin, size, pid, 0);

                /* process command */
                schedule_command(msgin);

                /* inform client we're done */
                send_reply(msgin.info.pid, "EOF");
        }
}

int send_reply(long mtype, char *msg, ...)
{
        char fmsg[LINE_MAX];
        va_list args;
        struct sched_msgbuf *msgout;
        pid_t pid = getpid();
        size_t size = sizeof(struct sched_msgbuf)-sizeof(long);

        va_start(args, msg);
        vsnprintf(fmsg, LINE_MAX, msg, args);
        va_end(args);

        msgout = calloc(1, sizeof(struct sched_msgbuf));
        msgout->mtype = mtype;
        msgout->info.pid = pid;
        strcpy(msgout->info.command, fmsg);

        msgsnd(msqid, msgout, size, 0);

        free(msgout);

        return 0;
}

void handle_term(int signum)
{
        stop_scheduler();
}

void stop_scheduler()
{
        syslog(LOG_DEBUG, "Stopping Scheduler.");
        msgctl(msqid, IPC_RMID, NULL); /* remove message queue */
        _exit(EXIT_SUCCESS);
}

void handle_usr1(int signum)
{
        syslog(LOG_DEBUG, "Scheduler received SIGUSR1");
}

int schedule_command(struct sched_msgbuf msg)
{
        if (strncmp(msg.info.command,CLERK_CMD_AT,strlen(CLERK_CMD_AT)) == 0) {
                return schedule_at(msg);
        }
        else if (strncmp(msg.info.command, CLERK_CMD_TIMER,
        strlen(CLERK_CMD_TIMER)) == 0)
        {
                return schedule_timer(msg);
        }
        else if (strncmp(msg.info.command, CLERK_CMD_CANCEL,
        strlen(CLERK_CMD_CANCEL)) == 0)
        {
                return schedule_cancel(msg);
        }
        else if (strncmp(msg.info.command, CLERK_CMD_LIST,
        strlen(CLERK_CMD_LIST)) == 0)
        {
                return schedule_list(msg);
        }

        return -1;
}

int schedule_at(struct sched_msgbuf msg)
{
        char *strctime;
        int ret;
        long interval = 0;
        struct itimerspec ts;
        struct sigevent evp;
        time_t then;
        timer_t timerid;
        struct tm *event;
        char *batchcmd;
        int year, month, day;
        int hour, minute, second;

        if (sscanf(msg.info.command, "AT %4d-%2d-%2d %2d:%2d:%2d %m[^\r\n]",
        &year, &month, &day, &hour, &minute, &second, &batchcmd) != 7)
        {
                send_reply(msg.info.pid, "ERROR: Invalid syntax");
                return 0;
        }

        event = malloc(sizeof (struct tm));
        event->tm_year = year - 1900;
        event->tm_mon = month - 1;
        event->tm_mday = day;
        event->tm_hour = hour;
        event->tm_min = minute;
        event->tm_sec = second;
        interval = difftime(mktime(event), time(NULL));

        if (interval < 0) {
                send_reply(msg.info.pid, "ERROR: time has past");
                return -1;
        }

        then = mktime(event);
        strctime = ctime(&then);

        syslog(LOG_DEBUG, "Scheduling job");
        syslog(LOG_DEBUG, "Date/Time:    %s", strctime);
        syslog(LOG_DEBUG, "Command: %s", batchcmd);
        syslog(LOG_DEBUG, "Delay: %lis", interval);

        /* schedule the command */
        evp.sigev_value.sival_ptr = &timerid;
        evp.sigev_notify = SIGEV_SIGNAL;
        evp.sigev_signo = SIGUSR1;

        ret = timer_create(CLOCK_REALTIME, &evp, &timerid);
        if (ret) {
                send_reply(msg.info.pid, "Could not create timer.");
                return -1;
        }

        ts.it_interval.tv_sec = 0;
        ts.it_interval.tv_nsec = 0;
        ts.it_value.tv_sec = interval;
        ts.it_value.tv_nsec = 0;
        ret = timer_settime(timerid, 0, &ts, NULL);
        if (ret) {
                send_reply(msg.info.pid, "Could not arm timer.");
                return -1;
        }
        
        send_reply(msg.info.pid, "TIMER %i set.", 
                set_sched_timer(timerid, batchcmd));

        return 0;
}

int schedule_timer(struct sched_msgbuf msg)
{
        struct itimerspec ts;
        int id;
        struct sched_timer *timer;

        if (!tlist) {
                send_reply(msg.info.pid, "ERROR: No timers set.");
                return -1;
        }

        if (sscanf(msg.info.command, "TIMER %i", &id) != 1) {
                send_reply(msg.info.pid, "ERROR: Invalid syntax");
                return -1;
        }

        timer = get_sched_timer(id);
        if (!timer) {
                send_reply(msg.info.pid, "ERROR: Timer not found.");
                return -1;
        }

        if (timer_gettime(timer->timerid, &ts) == -1) {
                send_reply(msg.info.pid, "ERROR: Invalid timer id");
                return -1;
        }

        send_reply(msg.info.pid, "TIMER %i, Command: '%s' (%lds remaining)",
                timer->id, timer->command, ts.it_value.tv_sec);

        return 0;
}

int schedule_cancel(struct sched_msgbuf msg)
{
        int id;
        struct sched_timer *timer;

        if (!tlist) {
                send_reply(msg.info.pid, "ERROR: No timers set.");
                return -1;
        }

        if (sscanf(msg.info.command, "CANCEL %i", &id) != 1) {
                send_reply(msg.info.pid, "ERROR: Invalid syntax");
                return -1;
        }

        timer = get_sched_timer(id);
        if (!timer) {
                send_reply(msg.info.pid, "ERROR: Timer not found.");
                return -1;
        }

        if (timer_delete(timer->timerid) == -1) {
                send_reply(msg.info.pid, "ERROR: Invalid timer id");
                return -1;
        }

        syslog(LOG_DEBUG, "TIMER %i cancelled", id);

        del_sched_timer(id);

        send_reply(msg.info.pid, "TIMER %i cancelled.", id);

        return 0;
}

timer_t get_sched_timer(int id)
{
        struct sched_timer *timer;

        timer = tlist;
        while (timer != NULL) {
                if (timer->id == id) break;
                timer = timer->next;
        }

        return timer;
}

int set_sched_timer(timer_t timerid, char *command)
{
        struct sched_timer *timer;

        timer = malloc(sizeof(struct sched_timer));
        timer->timerid = timerid;
        timer->command = command;
        timer->next = NULL;
        timer->id = nexttimer++;
        if (tlast)
                tlast->next = timer;
        else
                tlist = timer;
        tlast = timer;

        syslog(LOG_DEBUG, "TIMER %i set", timer->id);

        return timer->id;
}

void del_sched_timer(int id)
{
        struct sched_timer *timer;

        timer = tlist;
        while (timer != NULL) {
                syslog(LOG_DEBUG, "Inspecting timer %i", timer->id);
                if (timer->next) {
                        if (timer->next->id == id) {
                                timer->next = timer->next->next;
                        }
                }
                if (timer->id == id) break;
                timer = timer->next;
        }
        if ((timer->id == 0) && (timer->next)) {
                tlist = timer->next;
        }
        free(timer);
        timer = NULL;
        syslog(LOG_DEBUG, "TIMER %i deleted", id);
}


int schedule_list(struct sched_msgbuf msg)
{
        struct sched_timer *timer;

        if (!tlist) {
                send_reply(msg.info.pid, "No timers set.");
                return 0;
        }
        
        send_reply(msg.info.pid, "TIMER LIST");

        timer = tlist;
        while (timer != NULL) {
                send_reply(msg.info.pid, 
                        "TIMER %i, '%s'", timer->id, timer->command);
                timer = timer->next;
        }
        return 0;
}
