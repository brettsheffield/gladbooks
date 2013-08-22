/*
 * batch.c
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
#include "batch.h"
#include "config.h"
#include "email.h"
#include "handler.h"
#include "scheduler.h"
#include <libgen.h>
#include <limits.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <time.h>
#include <unistd.h>

int batch_at(int conn, char *command)
{
        char *batchcmd = NULL;
        char *strctime;
        int ret;
        int year, month, day;
        int hour, minute, second;
        long interval = 0;
        struct itimerspec ts;
        struct sigevent evp;
        struct tm *event;
        time_t now;
        time_t then;
        timer_t timerid;

        if (sscanf(command, "AT %4d-%2d-%2d %2d:%2d:%2d %m[^\n]", 
        &year, &month, &day, &hour, &minute, &second, &batchcmd) != 7)
        {
                chat(conn, "ERROR: Invalid syntax\n");
                return 0;
        }
        
        now = time(NULL);
        event = malloc(sizeof (struct tm));
        event->tm_year = year - 1900;
        event->tm_mon = month - 1;
        event->tm_mday = day;
        event->tm_hour = hour;
        event->tm_min = minute;
        event->tm_sec = second;
        interval = difftime(mktime(event), time(NULL));

        if (interval < 0) {
                chat(conn, "ERROR: time has past\n");
                return 0;
        }

        then = mktime(event);
        strctime = ctime(&then);

        chat(conn, "Scheduling job\n");
        chat(conn, "Date/Time:    %s\n", strctime);
        chat(conn, "Command: %s\n", batchcmd);
        chat(conn, "Delay: %lis\n", interval);
        chat(conn, CLERK_RESP_OK);

        /* schedule the command */
        syslog(LOG_DEBUG, "batch sees scheduler process %i", sched_proc);
        //signal(SIGUSR1, handle_usr1); // TODO: handle signal
        evp.sigev_value.sival_ptr = &timerid;
        evp.sigev_notify = SIGEV_SIGNAL;
        evp.sigev_signo = SIGUSR1;

        ret = timer_create(CLOCK_REALTIME, &evp, &timerid);
        if (ret)
                perror("timer_create()");

        ts.it_interval.tv_sec = interval;
        ts.it_interval.tv_nsec = 0;
        ts.it_value.tv_sec = interval;
        ts.it_value.tv_nsec = 0;
        ret = timer_settime(timerid, 0, &ts, NULL);
        if (ret)
                perror("timer_settime()");
        
        chat(conn, "TIMER %i set\n", timerid);

        free(batchcmd);
        free(event);

        return 0;
}

int batch_cancel(int conn, char *command)
{
        long int timerid;

        if (sscanf(command, "CANCEL %li", &timerid) != 1) {
                chat(conn, "ERROR: Invalid syntax\n");
                return 0;
        }

        if (timer_delete((timer_t) timerid) == -1) {
                chat(conn, "ERROR: Invalid timer id\n");
                return 0;
        }

        chat(conn, CLERK_RESP_OK);

        return 0;
}

int batch_mail(int conn, char *command)
{
        char instance[63] = "";
        int business = 0;
        row_t *rows = NULL;
        row_t *row = NULL;
        row_t *rr = NULL;
        int rowc;
        int count = 0;
        int flags = 0;
        char *sql;
        char *email = NULL;
        char *file;
        char *filename;
        char *tmp = NULL;
        smtp_recipient_t *r = NULL;
        smtp_header_t *h = NULL;
        smtp_attach_t *a = NULL;

        if (sscanf(command, "MAIL %[^.].%i\n", instance, &business) != 2) {
                chat(conn, "ERROR: Invalid syntax\n");
                return 0;
        }

        chat(conn, "Sending email batch for instance '%s', business '%i' ... ",
                instance, business);

        db_connect(config->dbs);

        /* verify instance and business exist */
        asprintf(&sql, "SELECT * FROM instance WHERE id='%s';", instance);
        rowc = batch_fetch_rows(NULL, 0, sql, &rows);
        free(sql);
        if (rowc == 0) {
                chat(conn, "ERROR: instance '%s' does not exist\n", instance);
                db_disconnect(config->dbs);
                return 0;
        }
        rows = NULL;
        asprintf(&sql, "SELECT * FROM business WHERE id='%i';", business);
        rowc = batch_fetch_rows(instance, 0, sql, &rows);
        free(sql);
        if (rowc == 0) {
                chat(conn, "ERROR: business '%s.%i' does not exist\n",
                        instance, business);
                db_disconnect(config->dbs);
                return 0;
        }
        rows = NULL;

        chat(conn, CLERK_RESP_OK);

        /* lock emaildetail table */
        batch_exec_sql(instance, business,
                "BEGIN WORK; LOCK TABLE emaildetail IN EXCLUSIVE MODE");

        /* fetch emails to send */
        rowc = batch_fetch_rows(instance, business, 
                "SELECT * FROM email_unsent", &rows);

        row = rows;
        while (row != NULL) {
                /* get id of email */
                email = db_field(row, "email")->fvalue;
                if (email == NULL) continue;
                
                /* loop through recipients */
                asprintf(&sql, "SELECT * FROM emailrecipient WHERE email=%s", 
                        email);
                rowc = batch_fetch_rows(instance, business, sql, &rr);
                free(sql);
                if (rowc == 0) { /* skip email with no recipients */
                        syslog(LOG_DEBUG, "Skipping email with no recipients");
                        row = row->next;
                        continue;
                }
                flags = 0;
                while (rr != NULL) {
                        if (strcmp(db_field(rr, "is_to")->fvalue, "t") == 0)
                                flags += EMAIL_TO;
                        if (strcmp(db_field(rr, "is_cc")->fvalue, "t") == 0)
                                flags += EMAIL_CC;
                        add_recipient(&r, "",
                                db_field(rr, "emailaddress")->fvalue, flags);
                        rr = rr->next;
                }

                /* loop through headers */
                asprintf(&sql, "SELECT * FROM emailheader WHERE email=%s", 
                        email);
                rowc = batch_fetch_rows(instance, business, sql, &rr);
                free(sql);
                while (rr != NULL) {
                        add_header(&h, db_field(rr, "header")->fvalue,
                                db_field(rr, "value")->fvalue);
                        rr = rr->next;
                }

                /* loop through attachments */
                asprintf(&sql, "SELECT * FROM emailpart WHERE email=%s", 
                        email);
                rowc = batch_fetch_rows(instance, business, sql, &rr);
                free(sql);
                while (rr != NULL) {
                        file = db_field(rr, "file")->fvalue;
                        tmp = strdup(file);
                        filename = basename(tmp);
                        add_attach(&a, file, filename);
                        free(tmp);
                        rr = rr->next;
                }

                /* send email */
                /* FIXME: this will quietly crash if db_field returns NULL */
                if (send_email(
                        db_field(row, "sendername")->fvalue, 
                        db_field(row, "sendermail")->fvalue, 
                        db_field(row, "body")->fvalue, 
                        r, h, a) == 0)
                {
                        /* update email with sent time */
                        asprintf(&sql, "SELECT email_sent(%s);", email);
                        chat(conn, "sql: %s\n", sql);
                        batch_exec_sql(instance, business, sql);
                        free(sql);
                        count++;
                }

                free_recipient(r); r = NULL;
                free_header(h); h = NULL;
                free_attach(a); a = NULL;

                row = row->next;
        }
        /* commit changes and unlock emaildetail table */
        batch_exec_sql(instance, business, "COMMIT WORK;");
        db_disconnect(config->dbs);

        chat(conn, "%i/%i emails sent\n", count, rowc);

        return 0;
}

/* perform a batch mail run for every business in every instance */
int batch_mail_all(int conn)
{
        char *bus;
        char *command;
        char *inst;
        char *sql;
        int rowc;
        row_t *business = NULL;
        row_t *instance = NULL;

        db_connect(config->dbs);

        /* fetch list of instances */
        asprintf(&sql,
                "SELECT * FROM instance WHERE id NOT IN ('default', 'test');");
        rowc = batch_fetch_rows(NULL, 0, sql, &instance);
        free(sql);
        if (rowc == 0) {
                chat(conn, "No instances found.  Stopping batch run.\n");
                db_disconnect(config->dbs);
                return 0;
        }
        while (instance != NULL) {
                /* find businesses for this instance */
                inst = db_field(instance, "id")->fvalue;
                asprintf(&sql, "SELECT * FROM business;");
                rowc = batch_fetch_rows(inst, 0, sql, &business);
                free(sql);
                if (rowc > 0) {
                        /* perform mail run for each business */
                        while (business != NULL) {
                                bus = db_field(business, "id")->fvalue;
                                asprintf(&command, "MAIL %s.%s", inst, bus);
                                batch_mail(conn, command);
                                free(command);
                                business = business->next;
                        }
                }
                instance = instance->next;
        }

        db_disconnect(config->dbs);

        return 0;
}

int batch_run(int conn)
{
        /* TODO: check for jobs in clerk table */
        return 0;
}

int batch_timer(int conn, char *command)
{
        long int timerid;
        struct itimerspec ts;

        if (sscanf(command, "TIMER %li", &timerid) != 1) {
                chat(conn, "ERROR: Invalid syntax\n");
                return 0;
        }

        if (timer_gettime((timer_t) timerid, &ts) == -1) {
                chat(conn, "ERROR: Invalid timer id\n");
                return 0;
        }

        chat(conn, CLERK_RESP_OK);

        chat(conn, "Timer %li set to run in %lds\n",
                timerid, ts.it_value.tv_sec);

        return 0;
}

int batch_exec_sql(char *instance, int business, char *sql)
{
        char *execsql;

        execsql = prepend_search_path(instance, business, sql);
        db_exec_sql(config->dbs, execsql);
        free(execsql);

        return 0;
}

int batch_fetch_rows(char *instance, int business, char *sql, row_t **rows)
{
        int rowc = 0;
        char *execsql;

        execsql = prepend_search_path(instance, business, sql);
        syslog(LOG_DEBUG, "batch_fetch_rows: %s", execsql);
        db_fetch_all(config->dbs, execsql, NULL, rows, &rowc);
        free(execsql);

        return rowc;
}

/* prepend search path to sql, so we're in the correct schema */
char * prepend_search_path(char *instance, int business, char *sql)
{
        char *newsql;

        if (instance && business > 0) {
        asprintf(&newsql,
                "SET search_path=gladbooks_%s_%i,gladbooks_%s,gladbooks;%s",
                instance, business, instance, sql);
        }
        else if (instance) {
                asprintf(&newsql,
                "SET search_path=gladbooks_%s,gladbooks;%s", instance, sql);
        }
        else {
                asprintf(&newsql, "SET search_path=gladbooks;%s", sql);
        }

        return newsql;
}

int chat(int conn, char *msg, ...)
{
        char fmsg[LINE_MAX];
        va_list args;

        va_start(args, msg);
        vsnprintf(fmsg, LINE_MAX, msg, args);
        va_end(args);

        return write(conn, fmsg, strlen(fmsg));
}
