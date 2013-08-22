/*
 * scheduler.c
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
#include "scheduler.h"
#include <signal.h>
#include <stdlib.h>
#include <syslog.h>
#include <time.h>
#include <unistd.h>

int start_scheduler()
{
        sched_proc = fork();
        if (sched_proc == -1) {
                /* failed to fork */
                return -1;
        }
        else if (sched_proc == 0) {
                scheduler();
        }
        return 0;
}

void scheduler()
{
        /* set up signal handlers */
        signal(SIGTERM, handle_term);
        signal(SIGUSR1, handle_usr1);

        /* wait for signal */
        pause();
}

void handle_term(int signum)
{
        syslog(LOG_DEBUG, "Stopping Scheduler.");
        _exit(EXIT_SUCCESS);
}

void handle_usr1(int signum)
{
        syslog(LOG_DEBUG, "Scheduler received SIGUSR1");
}
