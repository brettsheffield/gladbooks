/*
 * server.c
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

#include "lockfile.h"
#include "server.h"

#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <syslog.h>
#include <unistd.h>

int p = 0;
int hits = 0;

int server_start(char *host, char *service, int daemonize, int *pid)
{
        struct addrinfo hints, *servinfo;
        struct sockaddr_storage their_addr;
        socklen_t addr_size;
        int status;
        int yes=1;
        int errsv;
        int conn;
        int havelock = 0;
        int lockfd;
        char buf[sizeof(long)];

        memset(&hints, 0, sizeof hints);           /* zero memory */
        hints.ai_family = AF_UNSPEC;               /* ipv4/ipv6 agnostic */
        hints.ai_socktype = SOCK_STREAM;           /* TCP stream sockets */
        hints.ai_flags = AI_PASSIVE;               /* ips we can bind to */

        /* obtain lockfile */
        if ((havelock = obtain_lockfile(&lockfd)) != 0)
                exit(havelock);

        if ((status = getaddrinfo(NULL, service, &hints, &servinfo)) != 0){
                fprintf(stderr, "getaddrinfo error: %s\n",
                        gai_strerror(status));
                freeaddrinfo(servinfo);
                return -1;
        }

        /* get a socket */
        sock = socket(servinfo->ai_family, servinfo->ai_socktype,
                servinfo->ai_protocol);

        /* reuse socket if already in use */
        setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int));

        /* bind to a port */
        bind(sock, servinfo->ai_addr, servinfo->ai_addrlen);

        freeaddrinfo(servinfo);

        /* listening */
        if (listen(sock, BACKLOG) != 0) {
                errsv = errno;
                fprintf(stderr, "ERROR: %s\n", strerror(errsv));
                return -1;
        }

        memset(&their_addr, 0, sizeof(their_addr));
        memset(&addr_size, 0, sizeof(addr_size));

        /* daemonize */
        if (daemonize) {
                p = fork();
                if (p == -1) {
                        /* fork() failed */
                        errsv = errno;
                        fprintf(stderr, "ERROR: %s\n", strerror(errsv));
                        return -1;
                }
                else if (p !=0) {
                        /* parent process returns pid to caller */
                        *pid = p;
                        return 0;
                }
                /* create new session */
                if (setsid() == -1) {
                        errsv = errno;
                        fprintf(stderr, "ERROR: %s\n", strerror(errsv));
                        return -1;
                }

                /* change working directory */
                if (chdir("/") == -1) {
                        errsv = errno;
                        fprintf(stderr, "ERROR: %s\n", strerror(errsv));
                        return -1;
                }

                /* set umask */
                umask(0);

                /* open syslog */
                openlog(PROGRAM, LOG_CONS|LOG_PID, LOG_DAEMON);

                /* redirect st{in,out,err} */
                close(STDIN_FILENO);
                close(STDOUT_FILENO);
                close(STDERR_FILENO);
                if (open("/dev/null", O_RDONLY) == -1) {
                        syslog(LOG_ERR, "Failed to redirect stdin");
                        _exit(EXIT_FAILURE);
                }
                if (open("/dev/null", O_WRONLY) == -1) {
                        syslog(LOG_ERR, "Failed to redirect stdout");
                        _exit(EXIT_FAILURE);
                }
                if (open("/dev/null", O_RDWR) == -1) {
                        syslog(LOG_ERR, "Failed to redirect stderr");
                        _exit(EXIT_FAILURE);
                }
                syslog(LOG_DEBUG, "Daemon started");
        }

        /* write pid to lockfile */
        snprintf(buf, sizeof(long), "%ld\n", (long) getpid());
        if (write(lockfd, buf, strlen(buf)) != strlen(buf)) {
                fprintf(stderr, "Error writing to pidfile\n");
                exit(EXIT_FAILURE);
        }

        for (;;) {
                conn = accept(sock, (struct sockaddr *)&their_addr,&addr_size);
                /* fork to handle connection */
                p = fork();
                if (p == -1) {
                        /* fork() failed */
                        errsv = errno;
                        fprintf(stderr, "ERROR: %s\n", strerror(errsv));
                        return -1;
                }
                else if (p == 0) {
                        /* child */
                        close(sock); /* children don't listen */
                        write(conn, "OK\n", 3);
                        close(conn);
                        exit(EXIT_SUCCESS);
                }
                close(conn); /* parent closes connection */
                ++hits; /* increment hit counter */
        }

        return 0;
}

int server_stop()
{
        return kill(p, SIGTERM);
}

int server_hits()
{
        return hits;
}

