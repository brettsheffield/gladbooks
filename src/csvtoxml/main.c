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

void check_args(int argc, char **argv)
{
        if (argc == 4) {
                if (strcmp(argv[1], "--order") != 0) {
                        usage(EXIT_FAILURE);
                }
                orderspec = argv[2];
                filename = argv[3];
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

int main(int argc, char **argv)
{
        int fd;
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

        check_args(argc, argv);

        /* open file for reading */
        fd = open(filename, O_RDONLY);
        if (fd == -1) {
                perror("open()");
                _exit(EXIT_FAILURE);
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
                if (c[0] == '"') {
                        /* start/end quoted field */
                        quot = (len == 0) ? 1 : 0;
                }
                else if ((((quot == 0) && (c[0] == ',')) 
                || (c[0] == '\n') || (size == 0)) && (len > 0)) {
                        /* unquoted comma or newline - end field, start new */
                        fieldname = getfieldname(flds);
                        if (fieldname != NULL) {
                                /* store fields in remapped order */
                                nfld[map[flds]] = xmlNewNode(NULL, BAD_CAST fieldname);
                                free(fieldname);
                                nval = xmlNewText(BAD_CAST f);
                                xmlAddChild(nfld[map[flds]], nval);
                        }
                        flds++;

                        if (c[0] == '\n') {
                                lines++;
                                flds = 0;

                                /* append the fields in mapped order to row */
                                for (i=0; i<=4; i++) {
                                        xmlAddChild(nrow, nfld[i]);
                                }

                                /* now append the row */
                                xmlAddChild(n, nrow);
                        }
                        len = 0;
                }
                else {
                        f[len] = c[0];
                        len++;
                        if (len > LINE_MAX) {
                                fprintf(stderr, "Line length overrun\n");
                                _exit(EXIT_FAILURE);
                        }
                        f[len] = '\0';
                }
        }
        close(fd);

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
        fprintf(stderr, "usage: csvtoxml [--order <orderspec>] <filename>\n");
        _exit(status);
}
