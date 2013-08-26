/*
 * scheduler.h
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

#ifndef __GLADBOOKS_SCHEDULER_H__
#define __GLADBOOKS_SCHEDULER_H__ 1

#include <limits.h>
#include <time.h>

#define IPCENTER_QUEUE "/tmp/ipcenter"

struct sched_msgbuf {
        long mtype; /* pid of destination */
        struct sched_info {
                long pid; /* pid of sender */
                char command[LINE_MAX];
        } info;
};

struct sched_timer {
        int     id;
        timer_t timerid;
        char    *command;
        struct sched_timer *next;
};

int start_scheduler();
void stop_scheduler();
void scheduler();
void handle_term(int signum);
void handle_usr1(int signum);
int send_reply(long mtype, char *msg, ...);

/* Schedule a batch command to run at a specific time */
int schedule_at(struct sched_msgbuf msg);

/* Cancel a scheduled batch run */
int schedule_cancel(struct sched_msgbuf msg);

/* handle incoming commands */
int schedule_command(struct sched_msgbuf msg);

/* Report status on a scheduled batch run */
int schedule_timer(struct sched_msgbuf msg);

/* List all timers */
int schedule_list(struct sched_msgbuf msg);

/* return ptr to struct with timer details for id */
timer_t get_sched_timer(int id);

/* store timer details */
int set_sched_timer(timer_t timerid, char *command);

/* delete timer from list */
void del_sched_timer(int id);

int sched_proc; /* pid of scheduler */

#endif /* __GLADBOOKS_SCHEDULER_H__ */
