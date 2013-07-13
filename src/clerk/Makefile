CC=gcc
CFLAGS=-g -Wall -Werror
PROGRAM=clerkd
TESTPROGRAM=${PROGRAM}_test
LIBS=
TESTOBJECTS=test.o client_test.o server_test.o
MAINOBJECTS=client.o server.o
OBJECTFILES=${TESTOBJECTS} ${MAINOBJECTS}

${PROGRAM}: ${MAINOBJECTS} main.o
	${CC} ${CFLAGS} -o ${PROGRAM} ${MAINOBJECTS} main.o ${LIBS}

${TESTPROGRAM}: ${OBJECTFILES}
	${CC} ${CFLAGS} -o ${TESTPROGRAM} ${OBJECTFILES} ${LIBS}

main.o: main.c main.h
	${CC} ${CFLAGS} -c main.c

client.o: client.c client.h
	${CC} ${CFLAGS} -c client.c

server.o: server.c server.h
	${CC} ${CFLAGS} -c server.c

test.o: test.c test.h
	${CC} ${CFLAGS} -c test.c

.PHONY: test clean

clean:
	rm ${OBJECTFILES} main.o ${PROGRAM} ${TESTPROGRAM}

test:
	make clean || true
	make ${TESTPROGRAM} && valgrind -q ./${TESTPROGRAM} || true


leakcheck:
	valgrind -v --leak-check=full --show-reachable=yes ./clerkd_test
