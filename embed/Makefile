CC = gcc
LD = ld
JULIA = julia
CFLAGS= -O3

JL_SHARE = $(shell $(JULIA) -e 'print(joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia"))')
CFLAGS   += $(shell $(JL_SHARE)/julia-config.jl --cflags) -fPIC #need fPIC to include with shared objects
LDFLAGS  += $(shell $(JL_SHARE)/julia-config.jl --ldflags)
LDLIBS   += $(shell $(JL_SHARE)/julia-config.jl --ldlibs)

FINCH_EMBED_PATH := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

all: libfinch.a

finch.o: finch.c
	$(CC) -c $< -o $@ $(CFLAGS) -D FINCH_EMBED_PATH=\"$(FINCH_EMBED_PATH)\"

libfinch.a: finch.o
	ar rcs $@ $^

clean:
	rm -f *.o *.a