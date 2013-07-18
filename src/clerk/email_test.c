/*
 * email_test.c
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

#include "email_test.h"
#include "email.h"
#include "config.h"
#include "minunit.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

char *test_email()
{
        int ret;
        int sv[2];
        ssize_t len;
        char buf[8196] = "";
        smtp_recipient_t *r = NULL;
        smtp_header_t *h = NULL;
        smtp_attach_t *a = NULL;

        /* create a pair of connected sockets */
        if (socketpair(AF_UNIX, SOCK_STREAM, 0, sv) == -1) {
                perror("socketpair");
        }

        /* test write_socket() function by writing and reading from socket */
        ret = write_socket(sv[0], NULL, "MAIL FROM: %s\r\n", "<>");
        mu_assert("test write_socket() - write", ret == 0);

        /* now read back the result */
        len = read(sv[1], &buf, sizeof(buf));
        if (len == -1) perror("read");
        mu_assert("test write_socket() - read",
                strcmp(buf, "MAIL FROM: <>\r\n") == 0);

        close(sv[0]); close(sv[1]); /* close sockets */

        /* set smtp port to something useful */
        config->smtpport = 25;

        add_recipient(&r, "First Contact", "null@gladserv.com", EMAIL_TO);
        add_recipient(&r, "Second Contact", "null@gladserv.com", EMAIL_TO);

        add_header(&h, "Organisation", "Blogge Ltd");

        add_attach(&a, "/var/spool/gladbooks/SI-TESTACCT-0001.pdf",
                "SI-TESTACCT-0001.pdf");

        mu_assert("Send test email", send_email("null@example.com",
                "test", "Test message", r, h, a) == 0);

        free_recipient(r);
        free_header(h);
        free_attach(a);

        return 0;
}

char *test_email_append_header()
{
        smtp_recipient_t *r = NULL;
        char *header = NULL;

        add_recipient(&r, "First Contact", "one@example.com", EMAIL_TO);
        add_recipient(&r, "Second Contact", "two@example.com", EMAIL_TO);

        append_header(&header, "To", r);
        append_header(&header, "To", r->next);

        fprintf(stderr, "\n%s\n", header);
        mu_assert("append_header()",
                strcmp(header, "To: First Contact <one@example.com>, Second Contact <two@example.com>,") == 0);

        free(header);

        free_recipient(r);

        return 0;
}

char *test_email_add_header()
{
        smtp_header_t *h = NULL;

        add_header(&h, "Organisation", "Blogge Ltd");
        mu_assert("add_header() - header",
                strcmp(h->header, "Organisation") == 0);
        mu_assert("add_header() - value",
                strcmp(h->value, "Blogge Ltd") == 0);

        free_header(h);

        return 0;
}

char *test_email_boundary_string()
{
        char *boundary;

        boundary = boundary_string(32);
        printf("%s\n", boundary);
        mu_assert("boundary_string() - check length", strlen(boundary) == 32);
        free(boundary);

        return 0;
}
