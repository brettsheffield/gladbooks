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

int batch_exec_sql(char *instance, int business, char *sql);
int batch_fetch_rows(char *instance, int business, char *sql, row_t **rows);
int batch_mail(int conn, char *command);
int batch_run(int conn);
int chat(int conn, char *msg, ...);
char * prepend_search_path(char *instance, int business, char *sql);

#endif /* __GLADBOOKS_BATCH_H__ */
