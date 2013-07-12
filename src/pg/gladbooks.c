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
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <syslog.h>
#include <unistd.h>

#include "gladbooks.h"
#include "string.h"

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

Datum test(PG_FUNCTION_ARGS)
{
        char *ref = text_to_char(PG_GETARG_TEXT_P(0));

        /* log something, and return */
        openlog("GLADBOOKS", LOG_PID, LOG_DAEMON);
        setlogmask(LOG_UPTO(LOG_DEBUG));
        syslog(LOG_DEBUG, "Invoice: %s", ref);
        closelog();
        PG_RETURN_INT32(8080);
}

Datum write_salesinvoice_tex(PG_FUNCTION_ARGS)
{
        char *filename;
        char *tex = NULL;
        char *docmeta;
        char *ref;
        char line[LINE_MAX];
        char *l;
        int f;
        FILE *fd;

        /* Will that be the five minute argument, or the full half hour? */
        char *spooldir = text_to_char(PG_GETARG_TEXT_P(0));
        char *template = text_to_char(PG_GETARG_TEXT_P(1));
        char *orgcode = text_to_char(PG_GETARG_TEXT_P(2));
        int32 invoicenum = PG_GETARG_INT32(3);
        char *taxpoint = text_to_char(PG_GETARG_TEXT_P(4));
        char *issued = text_to_char(PG_GETARG_TEXT_P(5));
        char *due = text_to_char(PG_GETARG_TEXT_P(6));
        char *ponumber = text_to_char(PG_GETARG_TEXT_P(7));
        char *subtotal = text_to_char(PG_GETARG_TEXT_P(8));
        char *tax = text_to_char(PG_GETARG_TEXT_P(9));
        char *total = text_to_char(PG_GETARG_TEXT_P(10));
        char *lineitems = text_to_char(PG_GETARG_TEXT_P(11));
        char *taxes = text_to_char(PG_GETARG_TEXT_P(12));
        char *customer = text_to_char(PG_GETARG_TEXT_P(13));

        openlog("GLADBOOKS", LOG_PID, LOG_DAEMON);
        setlogmask(LOG_UPTO(LOG_DEBUG));
        syslog(LOG_DEBUG, "write_salesinvoice_tex()");

        asprintf(&ref, "SI/%s/%04i", orgcode, (int)invoicenum);

        /* open & read template */
        fd = fopen(template, "r");
        if (fd == NULL) {
                int errsv = errno;
                elog(ERROR, "Error opening template '%s': %s", template,
                        strerror(errsv));
                return -1;
        }

        syslog(LOG_DEBUG, "template opened");

        asprintf(&docmeta, "\t{%s}\n\t{%s}\n\t{%s}\n\t{%s}\n\t{%s}\n", 
                taxpoint, issued, due, ref, ponumber);

        /* TODO: make sure we quote any LaTeX characters properly */

        syslog(LOG_DEBUG, "about to process lines");
        while (fgets(line, LINE_MAX, fd) != NULL) {
                l = replaceall(line, "{{{DOCMETA}}}", texquote(docmeta));
                l = replaceall(l, "{{{CUSTOMERTABLE}}}", texquote(customer));
                l = replaceall(l, "{{{DUEDATE}}}", due);
                l = replaceall(l, "{{{SUBTOTAL}}}", subtotal);
                l = replaceall(l, "{{{TAX}}}", tax);
                l = replaceall(l, "{{{TOTAL}}}", total);
                l = replaceall(l, "{{{LINEITEMS}}}", texquote(lineitems));
                l = replaceall(l, "{{{TAXES}}}", texquote(taxes));

                tex = process_template_line(tex, l);
                free(l);
        }
        syslog(LOG_DEBUG, "lines processed");

        free(docmeta);

        /* close file */
        fclose(fd);

        /* build filename from invoice ref */
        size_t len = strlen(spooldir) + strlen(ref) + 6;
        filename = palloc(len + 1);
        char *iref = replaceall(ref, "/", "-");
        snprintf(filename, len, "%s/%s.tex", spooldir, iref);
        free(iref);

        /* log the temp filename back to the pg console */
        elog(INFO, "%s", filename);

        /* create and open file for writing */
        umask(022);
        f = creat(filename, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);

        syslog(LOG_DEBUG, "about to write .tex");

        /* speak friend, and enter */
        write(f, tex, strlen(tex));

        /* close file */
        close(f);

        /* create pdf */
        xelatex(filename, spooldir);
        
        pfree(filename);

        syslog(LOG_DEBUG, "all done");

        closelog();

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

/* TODO - quoting of latex special characters */
char * texquote(char *raw)
{
        char * s;

        s = replaceall(raw, "%", "\%");

        return s;
}

/* execute xelatex to create pdf, waiting for it to finish */
int xelatex(char *filename, char *spooldir)
{
        char **environ;
        char *env_args[] = { "TEXINPUTS=/var/spool/gladbooks/:", NULL };
        char *outputdir;
        char *command;
        char outputdirswitch[] = "-output-directory=";
        int len;

        len = strlen(outputdirswitch) + strlen(spooldir) + 1;
        outputdir = palloc(len + 1);
        snprintf(outputdir, len, "%s%s", outputdirswitch, spooldir);

        elog(INFO, "switch: %s, spool: %s", outputdir, spooldir);

        environ = env_args;

        syslog(LOG_DEBUG, "generating pdf");
        umask(022);

        len = strlen("xelatex -interaction=batchmode ") 
                        + strlen(outputdir) + strlen(filename) + 2;
        command = palloc(len + 1);
        snprintf(command, len, "xelatex -interaction=batchmode %s %s",
                outputdir, filename);
        syslog(LOG_DEBUG, "command: %s", command);
        system(command);

        pfree(command);
        pfree(outputdir);

        return 0;
}
