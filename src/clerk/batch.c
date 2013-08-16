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
#include "handler.h"
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int batch_mail(int conn, char *command)
{
        char instance[63] = "";
        int business = 0;
        row_t *rows = NULL;
        int rowc;
        int count = 0;
        char *sql;

        if (sscanf(command, "MAIL %[^.].%i\n", instance, &business) != 2) {
                chat(conn, "ERROR: Invalid syntax\n");
                return 0;
        }
        /* TODO: verify instance and business exist */

        chat(conn, CLERK_RESP_OK);

        db_connect(config->dbs);

        /* lock emaildetail table */
        batch_exec_sql(instance, business,
                "BEGIN WORK; LOCK TABLE emaildetail IN EXCLUSIVE MODE");

        /* fetch emails to send */
        rowc = batch_fetch_rows(instance, business, 
                "SELECT * FROM email_unsent", &rows);

        chat(conn, "%i rows fetched\n", rowc);

        row_t *r = rows;
        while (r != NULL) {
                chat(conn, "Sending email\n");

                /* id of email */
                char *email = NULL;
                email = db_field(r, "email")->fvalue;
                if (email == NULL) continue;
                chat(conn, "ID: %s\n", email);
                
                /* TODO: send email */

                /* update email with sent time */
                asprintf(&sql, "SELECT email_sent(%s);", email);
                chat(conn, "sql: %s\n", sql);
                batch_exec_sql(instance, business, sql);
                free(sql);
                
                count++;
                r = r->next;
        }
        /* commit changes and unlock emaildetail table */
        batch_exec_sql(instance, business, "COMMIT WORK;");
        db_disconnect(config->dbs);

        chat(conn, "%i emails sent\n", count);

        return 0;
}

int batch_run(int conn)
{
        /* TODO: check for jobs in clerk table */
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
        db_fetch_all(config->dbs, execsql, NULL, rows, &rowc);
        free(execsql);

        return rowc;
}

/* prepend search path to sql, so we're in the correct schema */
char * prepend_search_path(char *instance, int business, char *sql)
{
        char *newsql;

        asprintf(&newsql,
                "SET search_path = gladbooks_%s_%i,gladbooks_%s,gladbooks;%s",
                instance, business, instance, sql);

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
