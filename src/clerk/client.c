/*
 * client.c
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

#include "client.h"

#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>

int client_connect(char *host, char *service, int *sock)
{
        struct addrinfo hints, *servinfo, *p;
        int rv;
        int sockfd;

        memset(&hints, 0, sizeof hints);
        hints.ai_family = AF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;

        if ((rv = getaddrinfo(host, service, &hints, &servinfo)) != 0)
        {
                /* lookup failure */
                fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
                freeaddrinfo(servinfo);
                return -1;
        }

        /* try each address in turn */
        for(p = servinfo; p != NULL; p = p->ai_next) {
                /* create socket */
                if ((sockfd = socket(p->ai_family, p->ai_socktype,
                p->ai_protocol)) == -1)
                {
                        perror("socket");
                        continue;
                }
                /* open connection */
                if (connect(sockfd, p->ai_addr, p->ai_addrlen) == -1) {
                        close(sockfd);
                        perror("connect");
                        continue;
                }
                break;
        }

        if (p == NULL) {
                fprintf(stderr, "failed to connect\n");
                freeaddrinfo(servinfo);
                return -1;
        }
        
        freeaddrinfo(servinfo);

        *sock = sockfd;

        return 0;
}
