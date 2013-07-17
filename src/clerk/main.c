/*
 * main.c - Gladbooks clerk daemon
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

#include "args.h"
#include "main.h"
#include "server.h"
#include "signals.h"

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/types.h>

extern int g_signal;

int main(int argc, char **argv)
{
        int pid = 0;

        /* set up signal handlers */
        if (sighandlers() == -1) {
                fprintf(stderr, "Failed to set up signals. Exiting.\n");
                exit(EXIT_FAILURE);
        }

        /* check commandline args */
        if (process_args(argc, argv) == -1)
                exit(EXIT_FAILURE);

        /* TODO: pull settings from config file */
        return server_start("::1", "3141", 1, &pid);
}
