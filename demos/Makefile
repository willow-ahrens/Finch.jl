CC = gcc
LD = ld
JULIA = julia
CFLAGS= -g -O0

JL_SHARE = $(shell $(JULIA) -e 'print(joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia"))')
CFLAGS   += $(shell $(JL_SHARE)/julia-config.jl --cflags) -I../embed
LDFLAGS  += $(shell $(JL_SHARE)/julia-config.jl --ldflags) -L../embed
LDLIBS   += $(shell $(JL_SHARE)/julia-config.jl --ldlibs) -lfinch

all: embed_demo sssp

embed_demo: embed_demo.o
	$(CC) $^ -o $@ $(CFLAGS) $(LDFLAGS) $(LDLIBS)

embed_demo.o: embed_demo.c
	$(CC) -c $< -o $@ $(CFLAGS)

sssp: sssp.o
	$(CC) $^ -o $@ $(CFLAGS) $(LDFLAGS) $(LDLIBS)

sssp.o: sssp.c
	$(CC) -c $< -o $@ $(CFLAGS)

clean:
	rm -f *.o embed_demo