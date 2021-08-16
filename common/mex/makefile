# Build stand-alone binaries from the sources, i.e., without matlab
# bindings. main() usually contains some tests that can be run.
#
#verbose=0: only output from the unit_tests
#verbose=1: some information from the algorithms
#verbose=2: much information

# For production code also use -DNDEBUG to turn off assert

CC = gcc

UNAME := $(shell uname)

# -march=native makes it slower on the MBP

FLAGS = -g -W -Wpointer-arith -Wcast-qual -Wcast-align -Wall -Wwrite-strings -Wwrite-strings -fno-common -Wmissing-prototypes -Wstrict-prototypes -fshort-enums -Wshadow -Wnested-externs --std=c99 -O3 -Dverbose=1
# FLAGS += -DNDEBUG

oktarget = 0
ifeq ($(UNAME), Linux)
oktarget = 1
FLAGS += -Werror
FLAGS += -march=native
endif

ifeq ($(UNAME), Darwin)
  oktarget = 1
# compiles with warnings, PRIu64t macros in inttypes.h can fix
FLAGS +=
endif

ifeq ($(oktarget), 0)
  $(error No supported platform detected)
else
  $(info --> $(UNAME) detected)
endif

all: gaussianInt2 blit3 com3 mlfit mlfit1 mlfit1sn mlfitN conv1 imshift fwhm1d

blit3: blit3.c
	$(CC) $(FLAGS) gaussianInt2.o -Dstandalone `pkg-config gsl --cflags` blit3.c -lm -o blit3
	$(CC) $(FLAGS) gaussianInt2.o `pkg-config gsl --cflags` blit3.c -lm  -c -o blit3.o

fwhm1d: fwhm1d.c
	$(CC) -Wall -g  `pkg-config gsl --cflags` fwhm1d.c `pkg-config gsl --libs` -lm -o fwhm1d

com3: com3.c
	$(CC) $(FLAGS) -Dstandalone `pkg-config gsl --cflags --libs` com3.c -lm -o com3
	$(CC) $(FLAGS) `pkg-config gsl --cflags --libs` com3.c -lm -c -o com3.o

mlfit: mlfit.c
	$(CC) $(FLAGS) `pkg-config gsl --cflags --libs` mlfit.c -lm -c -o mlfit.o

mlfit1: mlfit1.c mlfit blit3 gaussianInt2
	$(CC) $(FLAGS) mlfit1.c mlfit.o blit3.o gaussianInt2.o -lm -o mlfit1sn `pkg-config --libs --cflags gsl` -o mlfit1

mlfit1sn: mlfit1sn.c mlfit
	$(CC) $(FLAGS) -Dstandalone  mlfit1sn.c mlfit.o gaussianInt2.o blit3.o -lm -o mlfit1sn `pkg-config --libs --cflags gsl` -o mlfit1sn

mlfitN: mlfitN.c mlfit
	$(CC) $(FLAGS) mlfitN.c mlfit.o blit3.o gaussianInt2.o -lm -o mlfitN `pkg-config --libs --cflags gsl` -o mlfitN

gaussianInt2:
	$(CC) $(FLAGS) `pkg-config gsl --cflags --libs` gaussianInt2.c -lm -c -o gaussianInt2.o

gaussianInt2_ut:
	$(CC) $(FLAGS) `pkg-config gsl --cflags --libs` gaussianInt2.c gaussianInt2_ut.c -lm -o gaussianInt2_ut

conv1: conv1.c
	$(CC) $(FLAGS) `pkg-config gsl --cflags --libs`  conv1.c -lpthread -c -o conv1.o
	$(CC) $(FLAGS) -Dstandalone `pkg-config gsl --cflags --libs` conv1.c -lpthread -o conv1

imshift: imshift.c
	$(CC) $(FLAGS)  `pkg-config gsl --cflags --libs` imshift.c conv1.o -lpthread -o imshift

clean:
	rm blit3
	rm com3
	rm mlfit1sn
	rm *.o

test:
	./com3
	./blit3
	./mlfit1
	./mlfit1sn
	./mlfitN

valgrind:
	valgrind ./com3
	printf 'done: com3. Press any key to continue with blit3\n'
	read _
	valgrind ./blit3
	printf 'done: blit3. Press any key to continue\n'
	read _
	valgrind ./mlfit1
	printf 'done: mlfit1. Press any key to continue\n'
	read _
	valgrind ./mlfit1sn
	printf 'done: mlfit1sn. Press any key to continue\n'
	read _
	valgrind ./mlfitN
	printf 'done: mlfitN. Press any key to continue\n'
	read _
	valgrind ./imshift
	printf 'done: mlfitN. Press any key to continue\n'
	read _
	printf 'Nothing more to test'

readtif:
	$(CC) $(FLAGS)  `pkg-config --cflags libtiff-4` readtif.c `pkg-config --libs libtiff-4` -o readtif
