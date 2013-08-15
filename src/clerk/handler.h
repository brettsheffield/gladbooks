/*
 * handler.h
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

#ifndef __GLADBOOKS_HANDLER_H__
#define __GLADBOOKS_HANDLER_H__ 1

int handle_command(int conn, char *command);
void handle_connection(int conn);

#define GREET_STRING "Gladbooks Clerk Daemon\n"

#define CLERK_CMD_NOOP "NOOP"
#define CLERK_CMD_QUIT "QUIT"
#define CLERK_CMD_RUN "RUN"
#define CLERK_CMD_MAIL "MAIL"
#define CLERK_CMD_BAD "BADCOMMAND"
#define CLERK_RESP_OK "OK\n"
#define CLERK_RESP_ERROR "ERROR\n"
#define CLERK_RESP_BYE "BYE\n"

#endif /* __GLADBOOKS_HANDLER_H__ */
