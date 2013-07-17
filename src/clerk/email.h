/*
 * email.h
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

#ifndef __GLADBOOKS_EMAIL_H__
#define __GLADBOOKS_EMAIL_H__ 1

#include <stdio.h>

/* file attachments */
typedef struct smtp_attach_t {
        char *filepath; /* path to file */
        char *filename; /* attach file as */
        struct smtp_attach_t *next;
} smtp_attach_t;

/* recipient flags */
#define EMAIL_BCC 0x0
#define EMAIL_TO  0x1
#define EMAIL_CC  0x2

typedef struct smtp_recipient_t {
        char *name;             /* display name */
        char *email;            /* email address */
        unsigned char flags;    /* bitmask */
        struct smtp_recipient_t *next;
} smtp_recipient_t;

/* smtp headers */
typedef struct smtp_header_t {
        char *header;
        char *value;
        struct smtp_header_t *next;
} smtp_header_t;

/* add_attach() - append to struct */
int add_attach(smtp_attach_t **a, char *filepath, char *filename);

/* add_header() - append to struct */
int add_header(smtp_header_t **h, char *header, char *value);

/* add_recipient() - append a new email recipient to struct
 *  r           - struct to append to
 *  name        - display name of email recipient
 *  email       - email address
 *  flags       - recipient flags
 */
int add_recipient(smtp_recipient_t **r, char *name, char* email,
        unsigned char flags);

/* append_header() - build smtp header */
int *append_header(char **header, char *headstring, smtp_recipient_t *r);

/* encode64() - base64 encode file and output to socket 
 *  infile      - file to encode
 *  outsock     - socket for output
 */
void encode64(FILE* infile, int outsock);

/* free_attach() - free struct */
void free_attach(smtp_attach_t *a);

/* free_header() - free struct */
void free_header(smtp_header_t *h);

/* free_recipient() - free struct */
void free_recipient(smtp_recipient_t *r);

/* mime_type() - determine mime type of file */
char *mime_type(char *filepath);

/* send_email() - send email
 *  sender      - envelope sender (also used for From header)
 *  subject     - text of Subject header
 *  r           - linked list of recipients
 *  headers     - linked list of additional headers
 *  attach      - linked list of file attachments
 */
int send_email(char *sender, char * subject, char *msg, smtp_recipient_t *r,
        smtp_header_t* headers, smtp_attach_t *attach);

/* 
 * write_socket() - write to a socket and check the response
 *  sockfd       - socket to write to
   expect       - unless NULL, read from socket and check we get this
 *  msg          - string to write
 *  ...          - any format args to msg
 * return: 0 = success, -1 on error
 */
int write_socket(int sockfd, char *expect, char *msg, ...);

#endif /* __GLADBOOKS_EMAIL_H__ */
