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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int batch_mail(int conn, char *command)
{
        char *sql = "";
        char instance[63] = "";
        int business = 0;
        row_t *rows = NULL;
        int rowc;

        if (sscanf(command, "MAIL %[^.].%i\n", instance, &business) != 2) {
                chat(conn, "ERROR: Invalid syntax\n");
                return 0;
        }
        /* TODO: verify instance and business exist */

        chat(conn, CLERK_RESP_OK);

        /* fetch emails to send */
        asprintf(&sql, "SELECT * FROM email"); /* TODO: create view */
        rowc = batch_fetch_rows(instance, business, sql, rows);
        free(sql);

        row_t *r = rows;
        while (r != NULL) {
                
                /* TODO: send email */

                /* TODO: update email with sent time */
                
                r = r->next;
        }

        return 0;
}

int batch_run(int conn)
{
        /* TODO: check for jobs in clerk table */
        return 0;
}

int batch_fetch_rows(char *instance, int business, char *sql, row_t *rows)
{
        int rowc = 0;
        char *execsql;

        /* prepend search path to sql, so we're in the correct schema */
        asprintf(&execsql,
                "SET search_path = gladbooks_%s_%i,gladbooks_%s,gladbooks;%s",
                instance, business, instance, sql);
        db_connect(config->dbs);
        db_fetch_all(config->dbs, execsql, NULL, &rows, &rowc);
        db_disconnect(config->dbs);

        free(execsql);

        return rowc;
}

int chat(int conn, char *msg)
{
        return write(conn, msg, strlen(msg));
}
