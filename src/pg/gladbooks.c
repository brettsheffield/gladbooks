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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <syslog.h>
#include <unistd.h>

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1(test);
PG_FUNCTION_INFO_V1(create_salesinvoice_tex);

Datum test(PG_FUNCTION_ARGS)
{
        /* log something, and return */
        openlog("GLADBOOKS", LOG_PID, LOG_DAEMON);
        setlogmask(LOG_UPTO(LOG_DEBUG));
        syslog(LOG_DEBUG, "test");
        closelog();
        PG_RETURN_INT32(8080);
}

Datum create_salesinvoice_tex(PG_FUNCTION_ARGS)
{
        text *sometext = PG_GETARG_TEXT_P(0);
        char *filename;
        char *charred;
        size_t len;
        int f;

        /* pg TEXT args aren't null terminated - make a char we can use */
        len = VARSIZE(sometext)-VARHDRSZ;
        charred = palloc(len + 1);
        memcpy(charred, VARDATA(sometext), len);
        charred[len] = 0;

        /* get temp filename */
        asprintf(&filename, "/tmp/XXXXXXXX");
        filename = mktemp(filename);

        /* log the temp filename back to the pg console */
        elog(INFO, "%s", filename);

        /* create and open file for writing */
        f = creat(filename, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
        free(filename);

        /* speak friend, and enter */
        write(f, charred, strlen(charred));

        /* fix permissions */
        if (fchmod(f, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)) {
                elog(ERROR, "Couldn't set file permissions");
        }

        /* close file */
        close(f);

        PG_RETURN_INT32(0);
}
