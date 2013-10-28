/*
 * csvtoxml - plugin for Gladbooks
 *
 * this file is part of GLADBOOKS
 *
 * Copyright (c) 2012, 2013 Brett Sheffield <brett@gladbooks.com>
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
#include "main.h"
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <libxml/parser.h>
#include <libxml/xmlschemas.h>

#define format_hsbc "Date,Type,Description,Paid out,Paid in,Balance"
#define BANK_UNKNOWN -1
#define BANK_HBOS 0
#define BANK_HSBC 1

/* order in which to expect columns
 * provided by --orderspec <orderspec>
 * 0 = transactdate
 * 1 = description
 * 2 = paymenttype
 * 3 = debit
 * 4 = credit
 * any other integer = ignore
 */

char *orderspec = "0,1,2,3,4";
int map[5];
char *filename;
int bank = -1;
int fd;

void check_args(int argc, char **argv)
{
        if (argc == 4) {
                if (strcmp(argv[1], "--order") != 0) {
                        usage(EXIT_FAILURE);
                }
                orderspec = argv[2];
                filename = argv[3];
        }
        else if (argc == 3) {
                filename = argv[2];
                if (strcmp(argv[1], "--auto") == 0) {
                        /* automatically figure out format */
                        bank = guess_format();
                }
                if ((strcmp(argv[1], "--hbos") == 0) || (bank == 0)) {
                        orderspec="0,3,2,1,4";
                        bank = 0;
                }
                else if ((strcmp(argv[1], "--hsbc") == 0) || (bank == 1)) {
                        orderspec="0,2,1,4,3";
                        bank = 1;
                }
                else {
                        usage(EXIT_FAILURE);
                }
        }
        else if (argc != 2) {
                usage(EXIT_FAILURE);
        }
        else {
                filename = argv[1];
        }
        if (setorderspec(orderspec) == -1) {
                fprintf(stderr, "invalid orderspec");
                usage(EXIT_FAILURE);
        }
}

int flattenxml(xmlDocPtr doc, char **xml, int pretty)
{
        xmlChar *xmlbuff;
        int buffersize;

        xmlDocDumpFormatMemoryEnc(doc, &xmlbuff, &buffersize, "UTF-8", pretty);
        *xml = malloc(snprintf(NULL, 0, "%s", (char *) xmlbuff) + 1);
        sprintf(*xml, "%s", (char *) xmlbuff);

        xmlFree(xmlbuff);

        return 0;
}

char *getfieldname(int field)
{
        char *fieldname = NULL;

        if ((field < 0) || (field > 4)) return NULL;
        switch (map[field]) {
        case 0:
                asprintf(&fieldname, "transactdate");
                break;
        case 1:
                asprintf(&fieldname, "description");
                break;
        case 2:
                asprintf(&fieldname, "paymenttype");
                break;
        case 3:
                asprintf(&fieldname, "debit");
                break;
        case 4:
                asprintf(&fieldname, "credit");
                break;
        default:
                fieldname = NULL;
                break;
        }

        return fieldname;
}

/* make an intelligent guess about the format of the file 
 -1 = unknown
  0 = HBOS TRN
  1 = HSBC
*/
int guess_format()
{
        ssize_t size = LINE_MAX;
        char buf[LINE_MAX];
        char *nl;
        bank = BANK_UNKNOWN;
        int cols = 0;
        char *ptr;
        
        fd = open(filename, O_RDONLY);
        if (fd == -1) {
                perror("open()");
                _exit(EXIT_FAILURE);
        }

        size = read(fd, buf, LINE_MAX);
        if (size == -1) {
                perror("read()");
                _exit(EXIT_FAILURE);
        }

        if (size > 0) {
                nl = memchr(buf, '\n', size);
                if (memchr(buf, '\n', size) != NULL) { /* newline found */
                        if (strncmp(buf, format_hsbc, nl - buf - 1) == 0) {
                                bank = BANK_HSBC;
                        }
                        else {
                                /* count columns */
                                for (ptr = buf; ptr < nl; ptr++) {
                                        if (strncmp(ptr, ",", 1) == 0)
                                                cols ++;
                                }
                                if (cols == 7) {
                                        /* 7 cols, assume HBOS TRN for now */
                                        bank = BANK_HBOS;
                                }
                        }
                }
        }

        switch (bank) {
        case BANK_HBOS:
                lseek(fd, 0, SEEK_SET); /* rewind to start */
                break;
        case BANK_HSBC:
                lseek(fd, nl-buf+1, SEEK_SET); /* skip to second line */
                break;
        case BANK_UNKNOWN:
                close(fd);
                break;
        }

        return bank;
}

void fixupField(char (*f)[LINE_MAX], int bank, int fld)
{
        if ((bank == BANK_HBOS) && (fld == 0)) {
                /* fix HBOS date field */
                (*f)[10] = '\0';
                (*f)[9] = (*f)[7];
                (*f)[8] = (*f)[6];
                (*f)[7] = '-';
                (*f)[6] = (*f)[5];
                (*f)[6] = (*f)[4];
                (*f)[4] = '-';
        }
        else if ((bank == BANK_HBOS) && ((fld == 1)||(fld == 4))) {
                /* strip leading spaces from HBOS debits and credits */
                sscanf(*f, "%s", *f);
        }
        else if (((bank == BANK_HSBC) && (fld == 1))
        || ((bank == BANK_HBOS) && (fld == 2)))
        {
                strcpy(*f, "1");
        }
}

int main(int argc, char **argv)
{
        ssize_t size = 1;
        char c[1];
        char f[LINE_MAX] = ""; /* field */
        int lines = 0;
        int quot = 0;
        int len = 0;
        int flds = 0;
        xmlNodePtr n = NULL;
        xmlNodePtr nrow = NULL;
        xmlNodePtr nval = NULL;
        xmlDocPtr doc;
        char *xml;
        char *fieldname;
        xmlNodePtr nfld[5] = { NULL, NULL, NULL, NULL, NULL };
        int i;
        int lspace = 0;
        char *amount;

        check_args(argc, argv);

        /* open file for reading, if not already */
        if (fd == 0) {
                fd = open(filename, O_RDONLY);
                if (fd == -1) {
                        perror("open()");
                        _exit(EXIT_FAILURE);
                }
        }

        /* start building xml document */
        doc = xmlNewDoc(BAD_CAST "1.0");
        n = xmlNewNode(NULL, BAD_CAST "resources");
        xmlDocSetRootElement(doc, n);

        /* read file one character at a time */
        while (size == 1) {
                size = read(fd, c, 1);
                if ((size == 1) && (flds == 1) && (len == 1))
                        nrow = xmlNewNode(NULL, BAD_CAST "bank");
                if ((size == 0) && (f[len] != '\n'))
                        c[0] = '\n';
                        
                if (c[0] == '"') {
                        /* start/end quoted field */
                        quot = (len == 0) ? 1 : 0;
                }
                else if ((((quot == 0) && (c[0] == ',')) 
                || (c[0] == '\n') || (size == 0)) && (len > 0)) {
                        /* unquoted comma or newline - end field, start new */
                        fieldname = getfieldname(flds);
                        if (fieldname != NULL) {
                                if (lspace > 0) { 
                                        /* we have a name and data */
                                        fixupField(&f, bank, flds);

                                        /* HBOS hack */
                                        if ((bank == 0) && ((flds == 1) || (flds == 4))) {
                                                if (flds == 1) {
                                                        amount = strdup(f);
                                                }
                                                else if (flds == 4) {
                                                        /* change debit to credit */
                                                        nval = xmlNewText(BAD_CAST amount);
                                                        if (strcmp(f, "D") == 0) {
                                                                nfld[3] = NULL;
                                                                nfld[4] = xmlNewNode(NULL, BAD_CAST "credit");
                                                                xmlAddChild(nfld[4], nval);
                                                        }
                                                        else {
                                                                nfld[3] = xmlNewNode(NULL, BAD_CAST "debit");
                                                                nfld[4] = NULL;
                                                                xmlAddChild(nfld[3], nval);
                                                        }
                                                        free(amount);
                                                }
                                        }
                                        else {
                                                /* store fields in remapped order */
                                                nfld[map[flds]] = xmlNewNode(NULL, BAD_CAST fieldname);
                                                nval = xmlNewText(BAD_CAST f);
                                                xmlAddChild(nfld[map[flds]], nval);
                                        }
                                }
                                else {
                                        nfld[map[flds]] = NULL;
                                }
                                free(fieldname);
                        }
                        flds++;

                        if (c[0] == '\n') {
                                lines++;
                                flds = 0;

                                /* append the fields in mapped order to row */
                                for (i=0; i<=4; i++) {
                                        if (nfld[i] != NULL)
                                                xmlAddChild(nrow, nfld[i]);
                                }

                                /* now append the row */
                                xmlAddChild(n, nrow);
                                nrow = NULL;
                        }
                        len = 0;
                        lspace = 0;
                }
                else {
                        f[len] = c[0];
                        len++;
                        if (c[0] != ' ')
                                lspace++; /* keep track of last non-whitespace char */
                        if (len > LINE_MAX) {
                                fprintf(stderr, "Line length overrun\n");
                                _exit(EXIT_FAILURE);
                        }
                        f[len] = '\0';
                }
        }
        close(fd);

        /* if last line of the file didn't end in a newline, append it now */
        if (nrow != NULL )
                xmlAddChild(n, nrow);

        flattenxml(doc, &xml, 1);
        printf("%s", xml);

        xmlFreeDoc(doc);
        xmlCleanupParser();
        free(xml);

        return 0;
}

int setorderspec(char *orderspec)
{
        return sscanf(orderspec, "%i,%i,%i,%i,%i",
                &map[0], &map[1], &map[2], &map[3], &map[4]);
}

void usage(int status)
{
        fprintf(stderr, "usage: csvtoxml [--order <orderspec> | --hsbc | --hbos ] <filename>\n");
        _exit(status);
}

