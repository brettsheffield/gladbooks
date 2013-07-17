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
#include "minunit.h"

#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

char *test_client()
{
        int sock = 0;
        ssize_t len;
        char buf[LINE_MAX] = "";

        mu_assert("Client connecting to server", 
                client_connect("localhost", "3141", &sock) == 0);

        len = read(sock, &buf, LINE_MAX);
        mu_assert("Read from socket", len > 0);
        mu_assert("Expect OK", strcmp(buf, "OK") == 0);

        return 0;
}
