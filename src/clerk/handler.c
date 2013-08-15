/*
 * handler.c
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

#include "handler.h"
#include "batch.h"

#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void handle_connection(int conn)
{
        char buf[LINE_MAX] = "";
        size_t bytes = 0;
        int ok = 0;

        chat(conn, GREET_STRING);

        do {
                bytes = read(conn, buf, LINE_MAX);
                ok = handle_command(conn, buf);
        } while ((bytes > 0) && (ok == 0));
        close(conn);
        _exit(EXIT_SUCCESS);
}

int handle_command(int conn, char *command)
{
        if (strncmp(command, CLERK_CMD_NOOP, strlen(CLERK_CMD_NOOP)) == 0) {
                chat(conn, CLERK_RESP_OK);
        }
        else if (strncmp(command, CLERK_CMD_RUN, strlen(CLERK_CMD_RUN)) == 0) {
                chat(conn, CLERK_RESP_OK);
                return batch_run(conn);
        }
        else if (strncmp(command,CLERK_CMD_QUIT,strlen(CLERK_CMD_QUIT)) == 0) {
                chat(conn, CLERK_RESP_BYE);
                return 1;
        }
        else {
                chat(conn, CLERK_RESP_ERROR);
        }
        return 0;
}
