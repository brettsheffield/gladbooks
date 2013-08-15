/* 
 * config.c
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
#include <errno.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <unistd.h>

#include "config.h"

/* set config defaults */
config_t config_default = {
        .daemon         = 0,
        .debug          = 0,
        .port           = 3141,
        .listenaddr     = "localhost",
        .smtpserver     = "localhost",
        .smtpport       = 25
};

config_t *config;
config_t *config_new;

db_t   *prevdb;         /* pointer to last db  */

/* store database config */
int add_db (char *value)
{
        db_t *newdb;
        char alias[LINE_MAX] = "";
        char type[LINE_MAX] = "";
        char host[LINE_MAX] = "";
        char db[LINE_MAX] = "";
        char user[LINE_MAX] = "";
        char pass[LINE_MAX] = "";

        /* mysql/ldap config lines may have 6 args, postgres has 4 */
        if (sscanf(value, "%s %s %s %s %s %s", alias, type, host, db,
                                                            user, pass) != 6)
        {
                if (sscanf(value, "%s %s %s %s", alias, type, host, db) != 4) {
                        /* config line didn't match expected patterns */
                        return -1;
                }
        }

        newdb = malloc(sizeof(struct db_t));

        if (strcmp(type, "pg") == 0) {
                newdb->alias = strndup(alias, LINE_MAX);
                newdb->type = strndup(type, LINE_MAX);
                newdb->host = strndup(host, LINE_MAX);
                newdb->db = strndup(db, LINE_MAX);
                newdb->user=NULL;
                newdb->pass=NULL;
                newdb->conn=NULL;
                newdb->next=NULL;
        }
        else if (strcmp(type, "my") == 0) {
                newdb->alias = strndup(alias, LINE_MAX);
                newdb->type = strndup(type, LINE_MAX);
                newdb->host = strndup(host, LINE_MAX);
                newdb->db = strndup(db, LINE_MAX);
                newdb->user = strndup(user, LINE_MAX);
                newdb->pass = strndup(pass, LINE_MAX);
                newdb->conn=NULL;
                newdb->next=NULL;
        }
        else if (strcmp(type, "tds") == 0) {
                newdb->alias = strndup(alias, LINE_MAX);
                newdb->type = strndup(type, LINE_MAX);
                newdb->host = strndup(host, LINE_MAX);
                newdb->db = strndup(db, LINE_MAX);
                newdb->user = strndup(user, LINE_MAX);
                newdb->pass = strndup(pass, LINE_MAX);
                newdb->conn=NULL;
                newdb->next=NULL;
        }
        else if (strcmp(type, "ldap") == 0) {
                newdb->alias = strndup(alias, LINE_MAX);
                newdb->type = strndup(type, LINE_MAX);
                newdb->host = strndup(host, LINE_MAX);
                newdb->db = strndup(db, LINE_MAX);
                newdb->user = strlen(user) == 0 ? NULL:strndup(user,LINE_MAX);
                newdb->pass = strlen(pass) == 0 ? NULL:strndup(pass,LINE_MAX);
                newdb->conn=NULL;
                newdb->next=NULL;
        }
        else {
                fprintf(stderr, "Invalid database type\n");
                return -1;
        }

        if (prevdb != NULL) {
                /* update ->next ptr in previous db
                 * to point to new */
                prevdb->next = newdb;
        }
        else {
                /* no previous db, 
                 * so set first ptr in config */
                config_new->dbs = newdb;
        }
        prevdb = newdb;
        return 0;
}

/* free config memory */
void free_config()
{
        config_new = NULL;
        free(config->listenaddr);
        free(config->smtpserver);
}

/* free keyvalue struct */
void free_keyval(keyval_t *h)
{
        keyval_t *tmp;

        while (h != NULL) {
                free(h->key);
                free(h->value);
                tmp = h;
                h = h->next;
                free(tmp);
        }
}

/* open config file for reading */
FILE *open_config(char *configfile)
{
        FILE *fd;

        fd = fopen(configfile, "r");
        if (fd == NULL) {
                int errsv = errno;
                fprintf(stderr, "ERROR: %s\n", strerror(errsv));
        }
        return fd;
}

/* check config line and handle appropriately */
int process_config_line(char *line)
{
        long i = 0;
        char key[LINE_MAX] = "";
        char value[LINE_MAX] = "";
        static char *multi = NULL;
        char *tmp = NULL;

        if (line[0] == '#')
                return 1; /* skipping comment */
        
        if (multi != NULL) {
                /* we're processing a multi-line config here */
                if (strncmp(line, "end", 3) == 0) {
                        tmp = strdup(multi);
                        free(multi);
                        multi = NULL;
                        i = process_config_line(tmp);
                        free(tmp);
                        return i;
                }
                else {
                        /* another bit; tack it on */
                        tmp = strdup(multi);
                        free(multi);
                        asprintf(&multi, "%s%s", tmp, line);
                        free(tmp);
                        *(multi + strlen(multi) - 1) = '\0';
                        return 0;
                }
        }
        else if (sscanf(line, "%[a-zA-Z0-9]", value) == 0) {
                return 1; /* skipping blank line */
        }
        else if (sscanf(line, "%s %li", key, &i) == 2) {
                /* process long integer config values */
                if (strcmp(key, "debug") == 0) {
                        return set_config_long(&config_new->debug,
                                                "debug", i, 0, 1);
                }
                else if (strcmp(key, "port") == 0) {
                        return set_config_long(&config_new->port, 
                                                "port", i, 1, 65535);
                }
                else if (strcmp(key, "smtpport") == 0) {
                        return set_config_long(&config_new->smtpport, 
                                                "smtpport", i, 1, 65535);
                }
                else if (strcmp(key, "daemon") == 0) {
                        return set_config_long(&config_new->daemon, 
                                                "port", i, 0, 1);
                }
        }
        else if (sscanf(line, "%s %[^\n]", key, value) == 2) {
                if (strcmp(key, "begin") == 0) {
                        /* multi-line config - cat the bits together and
                         * call this function again */
                        asprintf(&multi, "%s ", value);
                        return 0;
                }
                else if (strcmp(key, "listenaddr") == 0) {
                        return asprintf(&config->listenaddr, "%s", value);
                }
                else if (strcmp(key, "smtpserver") == 0) {
                        return asprintf(&config->smtpserver, "%s", value);
                }
                else if (strcmp(key, "db") == 0) {
                        return add_db(value);
                }

                else {
                        fprintf(stderr, "unknown config directive '%s'\n", 
                                                                        key);
                }
        }

        return -1; /* syntax error */
}

/* read config file into memory */
int read_config(char *configfile)
{
        FILE *fd;
        char line[LINE_MAX];
        int lc = 0;
        int retval = 0;

        set_config_defaults();
        config_new = &config_default;

        /* open file for reading */
        fd = open_config(configfile);
        if (fd == NULL)
                return 1;

        /* read in config */
        while (fgets(line, LINE_MAX, fd) != NULL) {
                lc++;
                if (process_config_line(line) < 0) {
                        printf("Error in line %i of %s.\n", lc, configfile);
                        retval = 1;
                }
        }

        /* close file */
        fclose(fd);

        /* if config parsed okay, make active */
        if (retval == 0)
                config = config_new;

        /* set syslog mask */
        setlogmask(LOG_UPTO((config->debug) ? LOG_DEBUG : LOG_INFO));
        
        return retval;
}

/* set config defaults if they haven't been set already */
int set_config_defaults()
{
        config = &config_default;

        return 0;
}

/* set config value if long integer is between min and max */
int set_config_long(long *confset, char *keyname, long i, long min, long max)
{
        if ((i >= min) && (i <= max)) {
                *confset = i;
        }
        else {
                fprintf(stderr,"ERROR: invalid %s value\n", keyname);
                return -1;
        }
        return 0;
}
