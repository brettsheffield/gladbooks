CC=gcc
CFLAGS=-g -Wall -Werror
PROGRAM=clerkd
LIBS=-lb64

${PROGRAM}: main.o
	${CC} ${CFLAGS} -o ${PROGRAM} main.o ${LIBS}

main.o: main.c main.h
	${CC} ${CFLAGS} -c main.c

