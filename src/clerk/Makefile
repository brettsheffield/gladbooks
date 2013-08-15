# Makefile for clerkd
#
# this file is part of GLADBOOKS
# 
# Copyright (c) 2012, 2013 Brett Sheffield <brett@gladserv.com>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program (see the file COPYING in the distribution).
# If not, see <http://www.gnu.org/licenses/>.

CC=gcc
CFLAGS=-g -Wall -Werror
PROGRAM=clerkd
TESTPROGRAM=${PROGRAM}_test
INSTALLDIR=/usr/local/bin
LIBS=-lb64
TESTOBJECTS=test.o args_test.o client_test.o config_test.o email_test.o server_test.o
MAINOBJECTS=args.o client.o config.o email.o handler.o help.o lockfile.o server.o signals.o
OBJECTFILES=${TESTOBJECTS} ${MAINOBJECTS}

${PROGRAM}: ${MAINOBJECTS} main.o
	${CC} ${CFLAGS} -o ${PROGRAM} ${MAINOBJECTS} main.o ${LIBS}

${TESTPROGRAM}: ${PROGRAM} ${OBJECTFILES}
	${CC} ${CFLAGS} -o ${TESTPROGRAM} ${OBJECTFILES} ${LIBS}

main.o: main.c main.h
	${CC} ${CFLAGS} -c main.c

args.o: args.c args.h
	${CC} ${CFLAGS} -c args.c

client.o: client.c client.h
	${CC} ${CFLAGS} -c client.c

config.o: config.c config.h
	${CC} ${CFLAGS} -c config.c

email.o: email.c email.h
	${CC} ${CFLAGS} -c email.c

handler.o: handler.c handler.h
	${CC} ${CFLAGS} -c handler.c

help.o: help.c help.h
	${CC} ${CFLAGS} -c help.c

lockfile.o: lockfile.c lockfile.h
	${CC} ${CFLAGS} -c lockfile.c

server.o: server.c server.h
	${CC} ${CFLAGS} -c server.c

signals.o: signals.c signals.h
	${CC} ${CFLAGS} -c signals.c

test.o: test.c test.h
	${CC} ${CFLAGS} -c test.c

.PHONY: test clean

clean:
	rm ${OBJECTFILES} main.o ${PROGRAM} ${TESTPROGRAM}

test:
	make clean || true
	make ${TESTPROGRAM} && valgrind -q ./${TESTPROGRAM} || true

leakcheck: test
	valgrind -v --leak-check=full --show-reachable=yes --track-origins=yes ./clerkd_test

install: ${PROGRAM}
	cp ${PROGRAM} ${INSTALLDIR}
