/*
 * test.c
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "test.h"
#include "args_test.h"
#include "client_test.h"
#include "config_test.h"
#include "email_test.h"
#include "server_test.h"
 
int tests_run = 0;

static void printline(char *c, int len)
{
        for (; len > 1; len--)
                printf("%s", c);
        printf("\n");
}

static char * all_tests()
{
        /* close stderr to keep output tidy */
        close(2);
        /* run the tests */
        printline("*", 80);
        printf("Running tests\n");
        printline("*", 80);
        mu_run_test(test_email_boundary_string);
        mu_run_test(test_email_add_header);
        mu_run_test(test_email_append_header);
        mu_run_test(test_server_start);
        mu_run_test(test_client);
        mu_run_test(test_server_stop);
        mu_run_test(test_args);
        mu_run_test(test_config_skip_comment);
        mu_run_test(test_config_skip_blank);
        mu_run_test(test_config_invalid_line);
        mu_run_test(test_config_open_success);
        mu_run_test(test_config_open_fail);
        mu_run_test(test_config_defaults);
        mu_run_test(test_config_set);
        mu_run_test(test_email);
        printline("*", 80);

        free_config();
        return 0;
}
 
int main(int argc, char **argv)
{
        char *result = all_tests();
        if (result != 0) {
                printline("*", 80);
                printf("FIXME: %s\n", result);
                printline("*", 80);
        }
        else {
                printf("ALL TESTS PASSED\n");
        }
        printf("Tests run: %d\n", tests_run);
 
        return result != 0;
}
