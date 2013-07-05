/* 
 * gladbooks.c - gladbooks postgresql functions
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
#include <postgres.h>
#include <fmgr.h>
#include <utils/geo_decls.h>

#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <syslog.h>
#include <unistd.h>

#include "string.h"

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1(test);
PG_FUNCTION_INFO_V1(write_salesinvoice_tex);

char * process_template_line(char *tex, char *line);
char * text_to_char(text *txt);

Datum test(PG_FUNCTION_ARGS)
{
        /* log something, and return */
        openlog("GLADBOOKS", LOG_PID, LOG_DAEMON);
        setlogmask(LOG_UPTO(LOG_DEBUG));
        syslog(LOG_DEBUG, "test");
        closelog();
        PG_RETURN_INT32(8080);
}

Datum write_salesinvoice_tex(PG_FUNCTION_ARGS)
{
        openlog("GLADBOOKS", LOG_PID, LOG_DAEMON);
        setlogmask(LOG_UPTO(LOG_DEBUG));
        syslog(LOG_DEBUG, "write_salesinvoice_tex()");

        char *filename;
        char *tfile;
        char *tex = NULL;
        char *docmeta;
        char *ref;
        char line[LINE_MAX];
        char *l;
        int f;
        FILE *fd;

        /* Will that be the five minute argument, or the full half hour? */
        char *orgcode = text_to_char(PG_GETARG_TEXT_P(0));
        int32 invoicenum = PG_GETARG_INT32(1);
        char *taxpoint = text_to_char(PG_GETARG_TEXT_P(2));
        char *issued = text_to_char(PG_GETARG_TEXT_P(3));
        char *due = text_to_char(PG_GETARG_TEXT_P(4));
        char *ponumber = text_to_char(PG_GETARG_TEXT_P(5));
        char *subtotal = text_to_char(PG_GETARG_TEXT_P(6));
        char *tax = text_to_char(PG_GETARG_TEXT_P(7));
        char *total = text_to_char(PG_GETARG_TEXT_P(8));
        char *lineitems = text_to_char(PG_GETARG_TEXT_P(9));
        char *taxes = text_to_char(PG_GETARG_TEXT_P(10));
        char *customer = text_to_char(PG_GETARG_TEXT_P(11));


        asprintf(&ref, "SI/%s/%04i", orgcode, (int)invoicenum);

        /* open & read template */
        /*FIXME: remove hardcoded path */
        asprintf(&tfile, "/home/bacs/dev/gladbooks-ui/tex/template.tex");
        fd = fopen(tfile, "r");
        if (fd == NULL) {
                int errsv = errno;
                elog(ERROR, "Error opening template '%s': %s", tfile,
                        strerror(errsv));
                free(tfile);
                return -1;
        }

        syslog(LOG_DEBUG, "template opened");

        asprintf(&docmeta, "\t{%s}\n\t{%s}\n\t{%s}\n\t{%s}\n\t{%s}\n", 
                taxpoint, issued, due, ref, ponumber);

        syslog(LOG_DEBUG, "about to process lines");
        while (fgets(line, LINE_MAX, fd) != NULL) {
                l = replaceall(line, "{{{DOCMETA}}}", docmeta);
                l = replaceall(l, "{{{CUSTOMERTABLE}}}", customer);
                l = replaceall(l, "{{{DUEDATE}}}", due);
                l = replaceall(l, "{{{SUBTOTAL}}}", subtotal);
                l = replaceall(l, "{{{TAX}}}", tax);
                l = replaceall(l, "{{{TOTAL}}}", total);
                l = replaceall(l, "{{{LINEITEMS}}}", lineitems);
                l = replaceall(l, "{{{TAXES}}}", taxes);

                tex = process_template_line(tex, l);
                free(l);
        }
        syslog(LOG_DEBUG, "lines processed");

        free(docmeta);

        /* close file */
        fclose(fd);

        /* get temp filename */
        asprintf(&filename, "/tmp/XXXXXXXX");
        filename = mktemp(filename);

        /* log the temp filename back to the pg console */
        elog(INFO, "%s", filename);

        /* create and open file for writing */
        f = creat(filename, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
        free(filename);

        syslog(LOG_DEBUG, "about to write .tex");

        /* speak friend, and enter */
        write(f, tex, strlen(tex));

        syslog(LOG_DEBUG, ".tex written, fixing perms");
        /* fix permissions */
        if (fchmod(f, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)) {
                elog(ERROR, "Couldn't set file permissions");
        }

        /* close file */
        close(f);

        closelog();

        syslog(LOG_DEBUG, "all done");

        PG_RETURN_INT32(0);
}

char * process_template_line(char *tex, char *line)
{
        char *tmp;

        if (tex != NULL) {
                tmp = strdup(tex);
                free(tex);
                asprintf(&tex, "%s\n%s", tmp, line);
                free(tmp);
        }
        else {
                asprintf(&tex, "%s", line);
        }
        *(tex + strlen(tex) - 1) = '\0';

        return tex;
}

/* pg TEXT args aren't null terminated - make a char we can use 
 * we're using palloc, so we can rely on postgres to clean up after us
 */
char * text_to_char(text *txt)
{
        size_t len;
        char *charred;

        len = VARSIZE(txt)-VARHDRSZ;
        charred = palloc(len + 1);
        memcpy(charred, VARDATA(txt), len);
        charred[len] = 0;

        return charred;
}
