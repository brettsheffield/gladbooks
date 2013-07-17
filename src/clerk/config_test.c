/* 
 * config_test.c - unit tests for config.c
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

#include "config_test.h"
#include "config.h"
#include "minunit.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


/* process_config_line() must return 1 if line is a comment */
char *test_config_skip_comment()
{
        mu_assert("Ensure comments are skipped by config parser",
                process_config_line("# This line is a comment\n") == 1);
        return 0;
}

/* process_config_line() must return 1 if line is blank */
char *test_config_skip_blank()
{
        mu_assert("Ensure blank lines are skipped by config parser",
                process_config_line(" \t \n") == 1);
        return 0;
}

/* process_config_line() must return -1 if line is invalid */
char *test_config_invalid_line()
{
        mu_assert("Ensure invalid lines return error",
                process_config_line("gibberish") == -1);
        return 0;
}

/* test opening config file */
char *test_config_open_success()
{
        FILE *fd;

        fd = open_config("test.conf");
        mu_assert("Open test.conf for reading", fd != NULL);
        fclose(fd);
        return 0;
}

/* ensure failing to open config returns an error */
char *test_config_open_fail()
{
        mu_assert("Ensure failure to open file returns error", 
                read_config("fake.conf") == 1);
        return 0;
}

/* test default value of debug = 0 */
char *test_config_defaults()
{
        set_config_defaults();
        mu_assert("Ensure default debug=0", config->debug == 0);
        mu_assert("Ensure default port=3141", config->port == 3141);
        mu_assert("Ensure default daemon=0", config->daemon == 0);
        mu_assert("Ensure default listenaddr=localhost", 
                strcmp(config->listenaddr, "localhost") == 0);
        mu_assert("Ensure default smtpserver=localhost", 
                strcmp(config->smtpserver, "localhost") == 0);
        mu_assert("Ensure default smtpport=25", config->smtpport == 25);
        return 0;
}

/* ensure config values are read from file */ 
char *test_config_set()
{
        read_config("test.conf");
        mu_assert("Ensure debug is set from config", config->debug == 1);
        mu_assert("Ensure port is set from config", config->port == 3000);
        mu_assert("Ensure daemon is set from config", config->daemon == 1);
        mu_assert("Ensure listenaddr is set from config", 
                strcmp(config->listenaddr, "::1") == 0);
        mu_assert("Ensure smtpserver is set from config", 
                strcmp(config->smtpserver, "::1") == 0);
        mu_assert("Ensure smtpport is set from config",config->smtpport == 465);
        return 0;
}
