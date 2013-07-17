/*
 * server_test.c
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

#include "server_test.h"
#include "server.h"
#include "minunit.h"

#include <signal.h>
#include <sys/types.h>
#include <unistd.h>

int pid = 0;

char *test_server_start()
{
        mu_assert("Starting server", server_start("::1","3141",1,&pid) == 0);
        mu_assert("Ensure we have pid for daemon", pid > 0);
        mu_assert("Verify pid is valid", kill(pid, 0) == 0);

        return 0;
}

char *test_server_stop()
{
        mu_assert("Stopping server", server_stop() == 0);
        return 0;
}
