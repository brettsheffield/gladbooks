# 
# csvtoxml - plugin for Gladbooks
# 
# this file is part of GLADBOOKS
# 
# Copyright (c) 2012, 2013 Brett Sheffield <brett@gladbooks.com>
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
# 

CC=gcc -g -Wall -Werror
OBJECTS=main.o
PROGRAM=csvtoxml
LIBS=-lxml2
INCLUDES=-I/usr/include/libxml2
INSTALLDIR=/usr/local/bin

${PROGRAM}: ${OBJECTS}
	${CC} ${INCLUDES} -o ${PROGRAM} ${OBJECTS} ${LIBS}

main.o: main.h main.c
	${CC} ${INCLUDES} -c main.c ${LIBS}

.PHONY: clean install

clean:
	rm *.o ${PROGRAM}

install: ${PROGRAM}
	cp ${PROGRAM} ${INSTALLDIR}
