# Makefile for gladbooks
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
PKGLIBDIR=`pg_config --pkglibdir`
INCLUDES=-I`pg_config --includedir-server`
LIBNAME=gladbooks
SPOOLDIR=/var/spool/${LIBNAME}
CONFIGDIR=/etc/${LIBNAME}/conf.d

${LIBNAME}.so: ${LIBNAME}.c ${LIBNAME}.h string.o
	gcc ${CFLAGS} -fpic ${INCLUDES} -c ${LIBNAME}.c
	gcc ${CFLAGS} -shared -o ${LIBNAME}.so ${LIBNAME}.o string.o

string.o: string.c string.h
	gcc ${CFLAGS} -fpic -c string.c

.PHONY: clean install

clean:
	rm ${LIBNAME}.so ${LIBNAME}.o string.o

install: gladbooks.so | ${SPOOLDIR} ${CONFIGDIR}
	ln -sf `pwd`/${LIBNAME}.so ${PKGLIBDIR}

${SPOOLDIR}: 
	mkdir -p ${SPOOLDIR}
	chown -R postgres.postgres ${SPOOLDIR}
	chmod -R 0755 ${SPOOLDIR}
	
${CONFIGDIR}: 
	mkdir -p ${CONFIGDIR}
	chown -R postgres.postgres ${CONFIGDIR}
	chmod -R 0755 ${CONFIGDIR}
	
