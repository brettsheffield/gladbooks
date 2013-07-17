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

#define _GNU_SOURCE

#include "args.h"
#include "config.h"
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
        int ret;
        char *service;

        /* set up signal handlers */
        if (sighandlers() == -1) {
                fprintf(stderr, "Failed to set up signals. Exiting.\n");
                exit(EXIT_FAILURE);
        }

        /* check commandline args */
        if (process_args(argc, argv) == -1)
                exit(EXIT_FAILURE);

        /* read config */
        if (read_config(DEFAULT_CONFIG) != 0) {
                fprintf(stderr, "Failed to read config. Exiting.\n");
                exit(EXIT_FAILURE);
        }

        asprintf(&service, "%li", config->port);
        ret = server_start(config->listenaddr, service, config->daemon, &pid);
        free(service);

        return ret;
}
