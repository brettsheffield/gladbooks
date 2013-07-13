CC=gcc
CFLAGS=-g -Wall -Werror
PROGRAM=clerkd
TESTPROGRAM=${PROGRAM}_test
LIBS=
TESTOBJECTS=test.o server_test.o
MAINOBJECTS=server.o
OBJECTFILES=${TESTOBJECTS} ${MAINOBJECTS}

${PROGRAM}: ${MAINOBJECTS} main.o
	${CC} ${CFLAGS} -o ${PROGRAM} ${MAINOBJECTS} main.o ${LIBS}

${TESTPROGRAM}: ${OBJECTFILES}
	${CC} ${CFLAGS} -o ${TESTPROGRAM} ${OBJECTFILES} ${LIBS}

main.o: main.c main.h
	${CC} ${CFLAGS} -c main.c

server.o: server.c server.h
	${CC} ${CFLAGS} -c server.c

test.o: test.c test.h
	${CC} ${CFLAGS} -c test.c

.PHONY: test clean

clean:
	rm ${OBJECTFILES} main.o ${PROGRAM} ${TESTPROGRAM}

test:
	make clean || true
	make ${TESTPROGRAM} && ./${TESTPROGRAM} || true
