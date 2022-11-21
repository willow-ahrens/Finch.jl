CC = gcc
LD = ld
JULIA = /usr/local/Cellar/julia/1.8.2/bin/julia #  /Users/adadima/mit/commit/julia/usr/bin/julia-debug
CFLAGS= -O3

JL_SHARE = $(shell $(JULIA) -e 'print(joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia"))')
CFLAGS   += $(shell $(JL_SHARE)/julia-config.jl --cflags) -fPIC -g #need fPIC to include with shared objects
LDFLAGS  += $(shell $(JL_SHARE)/julia-config.jl --ldflags)
LDLIBS   += $(shell $(JL_SHARE)/julia-config.jl --ldlibs)

all: libfinch.a

finch.o: finch.c
	$(CC) -c $< -o $@ $(CFLAGS)

libfinch.a: finch.o
	ar rcs $@ $^

clean:
	rm -f *.o *.a