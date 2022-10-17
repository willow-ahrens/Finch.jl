CC = gcc
LD = ld
JULIA = julia
CFLAGS= -g -O0

JL_SHARE = $(shell $(JULIA) -e 'print(joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia"))')
CFLAGS   += $(shell $(JL_SHARE)/julia-config.jl --cflags) -I../embed -fPIC #need fPIC to include with shared objects
LDFLAGS  += $(shell $(JL_SHARE)/julia-config.jl --ldflags) -L../embed -shared -all_load
LDLIBS   += $(shell $(JL_SHARE)/julia-config.jl --ldlibs) -lfinch

all: libembedbenchmarks.so

libembedbenchmarks.so: embed_benchmarks.o ../embed/libfinch.a
	$(CC) $^ -o $@ $(CFLAGS) $(LDFLAGS) $(LDLIBS)

embed_benchmarks.o: embed_benchmarks.c
	$(CC) -c $< -o $@ $(CFLAGS)

clean:
	rm -f *.o libembedbenchmarks.so