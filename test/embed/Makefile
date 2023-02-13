CC = gcc
LD = ld
JULIA = julia
CFLAGS= -g -O0

JL_SHARE = $(shell $(JULIA) -e 'print(joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia"))')
CFLAGS   += $(shell $(JL_SHARE)/julia-config.jl --cflags) -I../../embed
LDFLAGS  += $(shell $(JL_SHARE)/julia-config.jl --ldflags) -L../../embed
LDLIBS   += $(shell $(JL_SHARE)/julia-config.jl --ldlibs) -lfinch

all: test_embed_simple test_embed_not_initialized test_embed_not_rooted

test_embed_simple: test_embed_simple.o
	$(CC) $^ -o $@ $(CFLAGS) $(LDFLAGS) $(LDLIBS)

test_embed_not_initialized: test_embed_not_initialized.o
	$(CC) $^ -o $@ $(CFLAGS) $(LDFLAGS) $(LDLIBS)

test_embed_not_rooted: test_embed_not_rooted.o
	$(CC) $^ -o $@ $(CFLAGS) $(LDFLAGS) $(LDLIBS)

*.o: *.c
	$(CC) -c $< -o $@ $(CFLAGS)

clean:
	rm -f *.o test_embed_simple test_embed_not_initialized test_embed_not_rooted