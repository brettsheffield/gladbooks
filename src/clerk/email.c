/*
 * email.c
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

#include "email.h"
#include "config.h"

#include <b64/cencode.h>
#include <limits.h>
#include <netdb.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <syslog.h>
#include <time.h>
#include <unistd.h>

#define SIZE 100        /* arbitrary buffer size */
#define SMTP_LINE_MAX 998
#define MIMECMD "file --mime-type"

int write_socket(int sockfd, char *expect, char *msg, ...) {
        /* TODO: Each line of characters MUST be no more than 998 characters, 
         * and SHOULD be no more than 78 characters, excluding the CRLF. 
         * see: http://tools.ietf.org/html/rfc5322#page-7 */ 

        char buf[LINE_MAX]; 
        char fmsg[SMTP_LINE_MAX];
        int nread;
        va_list args;

        /* munge varadic format args into msg */
        va_start(args, msg);
        vsnprintf(fmsg, SMTP_LINE_MAX, msg, args);
        va_end(args);
        fprintf(stderr, "%s", fmsg);
        write(sockfd, fmsg, strlen(fmsg));

        if (!expect) return 0;

        memset(&buf, 0, sizeof buf);
        nread = read(sockfd, buf, LINE_MAX);
        if (nread == -1) {
                perror("read");
                return -1;
        }
        fprintf(stderr, "%s", buf);
        if (strncmp(buf, expect, strlen(expect)) != 0) {
                printf("Expected %s, giving up\n", expect);
                return -1;
        }
        return 0;
}

int send_email(char *sendername, char *sendermail, char *msg, 
        smtp_recipient_t *r, smtp_header_t* headers, smtp_attach_t *attach)
{
        int sockfd;
        int retval = -1;
        struct addrinfo hints, *servinfo, *p;
        int rv;
        FILE *fin;
        char *header_to = NULL;
        char *header_cc = NULL;
        char *smtpport = "";
        char *boundary;

        syslog(LOG_DEBUG, "send_email()");

        memset(&hints, 0, sizeof hints);
        hints.ai_family = AF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;

        asprintf(&smtpport, "%li", config->smtpport);
        if ((rv = getaddrinfo(config->smtpserver, smtpport, &hints,
                &servinfo))
        != 0)
        {
                /* lookup failure */
                syslog(LOG_ERR, "getaddrinfo: %s\n", gai_strerror(rv));
                free(smtpport);
                return -1;
        }
        free(smtpport);

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
                syslog(LOG_ERR, "failed to connect");
                return -1;
        }
        
        syslog(LOG_DEBUG, "connected to smtp server");

        /* see http://tools.ietf.org/html/rfc2821 */

        /* wait for 220 from server */
        if (write_socket(sockfd, "220", NULL) != 0) {
                syslog(LOG_DEBUG, "ERROR: 220 not received");
                goto close_socket;
        }
        if (write_socket(sockfd, "250", "HELO localhost\r\n") != 0) {
                syslog(LOG_DEBUG, "ERROR: 250 expected for HELO");
                goto close_socket;
        }
        if (write_socket(sockfd,
                "250", "MAIL FROM: %s <%s>\r\n", sendername, sendermail) != 0) 
        {
                syslog(LOG_DEBUG, "ERROR: 250 expected for MAIL");
                goto close_socket;
        }

        /* loop through recipients */
        int recipients = 0;
        while (r != NULL) {
                if (r->email == NULL)
                        break;
                if (write_socket(sockfd,"250","RCPT TO: %s <%s>\r\n",
                        r->name, r->email)) 
                {
                        syslog(LOG_DEBUG, "ERROR: 250 expected for RCPT");
                        goto close_socket;
                }
                recipients++;
                if (r->flags & EMAIL_TO) /* build To: header */
                        append_header(&header_to, "To", r);
                if (r->flags & EMAIL_CC) /* build Cc: header */
                        append_header(&header_cc, "Cc", r);
                r = r->next;
        }
        if (recipients == 0) {
                syslog(LOG_DEBUG, "ERROR: No recipients");
                goto close_socket; /* Noone to send to */
        }

        if (write_socket(sockfd, "354", "DATA\r\n") != 0) {
                syslog(LOG_DEBUG, "ERROR: 354 expected for DATA");
                goto close_socket;
        }

        /* send headers */
        if (write_socket(sockfd, NULL, "From: %s <%s>\r\n",
                sendername, sendermail) !=0) 
        {
                syslog(LOG_DEBUG, "ERROR: From header");
                goto close_socket;
        }
                
        /* drop trailing commas from destination headers and write to socket */
        if (header_to) {
                *(header_to + strlen(header_to) - 1) = 0;
                write_socket(sockfd, NULL, "%s\r\n", header_to);
                free(header_to);
        }
        if (header_cc) {
                *(header_cc + strlen(header_cc) - 1) = 0;
                write_socket(sockfd, NULL, "%s\r\n", header_cc);
                free(header_cc);
        }

        /* any other headers */
        while (headers != NULL) {
                write_socket(sockfd, NULL, "%s: %s\r\n", headers->header,
                        headers->value);
                headers = headers->next;
        }

        /* set up for multipart MIME if we're attaching files */
        if (attach) {
                boundary = boundary_string(BOUNDARY_LENGTH);
                write_socket(sockfd, NULL, "MIME-Version: 1.0\r\n");
                write_socket(sockfd, NULL,
                  "Content-Type: multipart/mixed; boundary="
                  "%s\r\n\r\n", boundary);
                write_socket(sockfd, NULL,
                  "This is a message with multiple parts in MIME format.\r\n");
        }

        /* plaintext message body */
        write_socket(sockfd, NULL, "Content-Type: text/plain\r\n");
        write_socket(sockfd, NULL, "\r\n%s\r\n", msg);

        if (attach) write_socket(sockfd, NULL, "--%s\r\n", boundary);

        /* loop through attachments */
        syslog(LOG_DEBUG, "attachments");
        while (attach != NULL) {
                write_socket(sockfd, NULL, "--%s\r\n", boundary);

                char *mimetype;
                mimetype = mime_type(attach->filepath);
                write_socket(sockfd, NULL,
                    "Content-Type: %s; "
                    "charset=UTF-8; name=\"%s\"\r\n", 
                    mimetype, attach->filename);
                free(mimetype);

                write_socket(sockfd, NULL,
                    "Content-Disposition: attachment; "
                    "filename=\"%s\";\r\n", attach->filename);

                write_socket(sockfd, NULL, 
                    "Content-Transfer-Encoding: base64\r\n\r\n");

                /* open attachment for reading */
                fin = fopen(attach->filepath, "r");
                if (fin == NULL) {
                        syslog(LOG_ERR, "error opening attachment '%s'", 
                                attach->filepath);
                        return -1;
                }

                /* base64 encode attachment and write to socket */
                encode64(fin, sockfd);

                /* close input file */
                fclose(fin);

                /* get next attachment */
                attach = attach->next;

                /* final boundary - note two trailing hyphens */
                if (!attach) {
                        write_socket(sockfd, NULL, "--%s--\r\n",boundary);
                        free(boundary);
                }
        }

        /* lone period signals end of body */
        write_socket(sockfd, NULL, ".\r\n");
        write_socket(sockfd, "250", "QUIT\r\n");

        retval = 0;
        syslog(LOG_DEBUG, "Email sent");

close_socket:

        close(sockfd); /* close socket */

        freeaddrinfo(servinfo);

        return retval;
}

void encode64(FILE* infile, int outsock)
{
        /* set up a destination buffer large enough to hold the encoded data */
        int size = SIZE;
        char* input = (char*)malloc(size);
        char* encoded = (char*)malloc(2*size); /* ~4/3 x input */

        /* we need an encoder and decoder state */
        base64_encodestate es;

        /* store the number of bytes encoded by a single call */
        int cnt = 0;
        
        /* initialise the encoder state */
        base64_init_encodestate(&es);

        /* gather data from the input, encode, and send it to the output */
        while (1)
        {
                cnt = fread(input, sizeof(char), size, infile);
                if (cnt == 0) break;
                cnt = base64_encode_block(input, cnt, encoded, &es);
                /* write encoded bytes to socket */
                write(outsock, encoded, cnt);
        }
        /* since we have reached the end of the input file, we know that 
           there is no more input data; finalise the encoding */
        cnt = base64_encode_blockend(encoded, &es);

        /* write the last bytes to the socket */
        write(outsock, encoded, cnt);
        
        free(encoded);
        free(input);
}

int add_recipient(smtp_recipient_t **r, char *name, char* email,
        unsigned char flags)
{
        smtp_recipient_t *new_r = calloc(1, sizeof(smtp_recipient_t));
        smtp_recipient_t *tmp_r = NULL;
        new_r->name = strdup(name);
        new_r->email = strdup(email);
        new_r->flags = flags;
        new_r->next = NULL;

        if (*r == NULL) {
                *r = new_r;
        }
        else {
                tmp_r = *r;
                while (tmp_r->next != NULL) {
                        tmp_r = tmp_r->next;
                }
                tmp_r->next = new_r;
        }

        return 0;
}

int *append_header(char **header, char *headstring, smtp_recipient_t *r)
{
        char *mail = NULL;
        int len = 0;

        asprintf(&mail, "%s <%s>,", r->name, r->email);
        if (*header == NULL) {
                *header = malloc(strlen(mail) + strlen(headstring) + 3);
                len = strlen(headstring) + strlen(mail) + 3;
                snprintf(*header, len, "%s: %s", headstring, mail);
        }
        else {
                *header = realloc(*header, strlen(mail) + strlen(*header) + 2);
                len = strlen(*header) + strlen(mail) + 2;
                snprintf(*header + strlen(*header), len, " %s", mail);
        }
        free(mail);

        return 0;
}

void free_recipient(smtp_recipient_t *r)
{
        smtp_recipient_t *tmp;

        while (r != NULL) {
                free(r->name);
                free(r->email);
                tmp = r;
                r = r->next;
                free(tmp);
        }
        r = NULL;
}

void free_header(smtp_header_t *h)
{
        smtp_header_t *tmp;

        while (h != NULL) {
                free(h->header);
                free(h->value);
                tmp = h;
                h = h->next;
                free(tmp);
        }
        h = NULL;
}

int add_header(smtp_header_t **h, char *header, char *value)
{
        smtp_header_t *new_h = calloc(1, sizeof(smtp_header_t));
        smtp_header_t *tmp_h = NULL;
        new_h->header = strdup(header);
        new_h->value = strdup(value);
        new_h->next = NULL;

        if (*h == NULL) {
                *h = new_h;
        }
        else {
                tmp_h = *h;
                while (tmp_h->next != NULL) {
                        tmp_h = tmp_h->next;
                }
                tmp_h->next = new_h;
        }

        return 0;
}

void free_attach(smtp_attach_t *a)
{
        smtp_attach_t *tmp;

        while (a != NULL) {
                free(a->filepath);
                free(a->filename);
                tmp = a;
                a = a->next;
                free(tmp);
        }
        a = NULL;
}

int add_attach(smtp_attach_t **a, char *filepath, char *filename)
{
        smtp_attach_t *new_a = calloc(1, sizeof(smtp_attach_t));
        smtp_attach_t *tmp_a = NULL;
        new_a->filepath = strdup(filepath);
        new_a->filename = strdup(filename);
        new_a->next = NULL;

        if (*a == NULL) {
                *a = new_a;
        }
        else {
                tmp_a = *a;
                while (tmp_a->next != NULL) {
                        tmp_a = tmp_a->next;
                }
                tmp_a->next = new_a;
        }

        return 0;
}

char *mime_type(char *filepath)
{
        char *mimetype;
        char *command;
        char *buf;
        FILE *f;

        /* TODO: check for errors */

        asprintf(&command, "%s %s", MIMECMD, filepath);
        f = popen(command, "r");
        mimetype = malloc(100);
        buf = malloc(100);
        fscanf(f, "%s %s\n", buf, mimetype);
        pclose(f);
        free(buf);
        free(command);

        return mimetype;
}

char *boundary_string(int len)
{
        char *str;
        int i;
        unsigned int r;
        char *digest =
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

        srand((unsigned)time(NULL)); /* seed random */
        str = malloc(len + 1); /* allocate string */

        for(i=0; i<len; i++) {
                r = rand() % strlen(digest);
                str[i] = digest[r];
        }

        str[i] = '\0'; /* null terminate string */

        return str;
}
