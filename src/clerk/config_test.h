/* 
 * config_test.h
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

#ifndef __GLADBOOKS_CONFIG_TEST_H__
#define __GLADBOOKS_CONFIG_TEST_H__ 1

#include "config.h"

char *test_config_skip_comment();
char *test_config_skip_blank();
char *test_config_invalid_line();
char *test_config_open_success();
char *test_config_open_fail();
char *test_config_defaults();
char *test_config_set();

#endif /* __GLADBOOKS_CONFIG_TEST_H__ */
