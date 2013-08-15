/*
 * client_test.c
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

#include "client_test.h"
#include "client.h"
#include "handler.h"
#include "minunit.h"

#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

char *test_client()
{
        int sock = 0;
        char buf[LINE_MAX + 1] = "";
        size_t len = 0;

        /* connect */
        mu_assert("Client connecting to server", 
                client_connect("localhost", "3141", &sock) == 0);
        mu_assert("Read from socket", read(sock, &buf, LINE_MAX) > 0);
        mu_assert("Expect greeting", strcmp(buf, GREET_STRING) == 0);

        /* NOOP */
        mu_assert("Send " CLERK_CMD_NOOP,
                write(sock, CLERK_CMD_NOOP "\n", strlen(CLERK_CMD_NOOP) + 1)
                != -1);
        len = read(sock, &buf, LINE_MAX);
        buf[len] = '\0';
        mu_assert("Read from socket", len > 0);
        mu_assert("Expect OK", strcmp(buf, CLERK_RESP_OK) == 0);

        /* Invalid command */
        mu_assert("Send invalid command",
                write(sock, CLERK_CMD_BAD, strlen(CLERK_CMD_BAD))
                != -1);

        len = read(sock, &buf, LINE_MAX);
        buf[len] = '\0';
        mu_assert("Read from socket", len > 0);
        mu_assert("Expect ERROR", strcmp(buf, CLERK_RESP_ERROR) == 0);

        /* QUIT */
        mu_assert("Send " CLERK_CMD_QUIT,
                write(sock, CLERK_CMD_QUIT "\n", strlen(CLERK_CMD_QUIT) + 1)
                != -1);
        len = read(sock, &buf, LINE_MAX);
        buf[len] = '\0';
        mu_assert("Read from socket", len > 0);
        mu_assert("Expect BYE", strcmp(buf, CLERK_RESP_BYE) == 0);


        return 0;
}
