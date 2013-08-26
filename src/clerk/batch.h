/*
 * batch.h
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

#ifndef __GLADBOOKS_BATCH_H__
#define __GLADBOOKS_BATCH_H__ 1

#include <gladdb/db.h>

/* Pass command on to scheduler */
int batch_schedule(int conn, char *command);

/* Execute some SQL on an open db connection */
int batch_exec_sql(char *instance, int business, char *sql);

/* Execute some SQL on an open db connection and
 * populate **rows with the results */
int batch_fetch_rows(char *instance, int business, char *sql, row_t **rows);

/* perform a batch mail run for a specified instance and business */
int batch_mail(int conn, char *command);

/* perform a batch mail run for every business in every instance */
int batch_mail_all(int conn);

/* TODO: not implemented - check for jobs in clerk table and execute */
int batch_run(int conn);

/* Write something to the open socket */
int chat(int conn, char *msg, ...);

/* prepend search path to sql, so we're in the correct schema */
char * prepend_search_path(char *instance, int business, char *sql);

#endif /* __GLADBOOKS_BATCH_H__ */
