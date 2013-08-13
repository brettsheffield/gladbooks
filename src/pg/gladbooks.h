/* 
 * gladbooks.h - gladbooks postgresql functions
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
#ifndef __GLADBOOKS_H_
#define __GLADBOOKS_H_ 1

char * process_template_line(char *tex, char *line);
char * text_to_char(text *txt);
char * texquote(char *raw);
int xelatex(char *filename, char *spooldir, char *configdir);

PG_FUNCTION_INFO_V1(test);
PG_FUNCTION_INFO_V1(create_business_dirs);
PG_FUNCTION_INFO_V1(write_salesinvoice_tex);

#endif /*__GLADBOOKS_H_ */
