#include "client.h"

#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>

int client_connect(char *host, char *service)
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
                printf("connected.\n");
                break;
        }

        if (p == NULL) {
                fprintf(stderr, "failed to connect\n");
                return -1;
        }

        return 0;
}
