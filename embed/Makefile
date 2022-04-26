CC = gcc
LD = ld
JULIA = julia
CFLAGS= -O3

JL_SHARE = $(shell $(JULIA) -e 'print(joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia"))')
CFLAGS   += $(shell $(JL_SHARE)/julia-config.jl --cflags)
LDFLAGS  += $(shell $(JL_SHARE)/julia-config.jl --ldflags)
LDLIBS   += $(shell $(JL_SHARE)/julia-config.jl --ldlibs)

all: libfinch.a

finch.o: finch.c
	$(CC) -c $< -o $@ $(CFLAGS) $(LDFLAGS) $(LDLIBS)

libfinch.a: finch.o
	ar rcs $@ $^

clean:
	rm -f *.o *.a