#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

JULIA_DEFINE_FAST_TLS // only define this once, in an executable

int main(int argc, char** argv){

    finch_initialize();

    jl_value_t* x = finch_Cint(42);

    finch_free(x);

    finch_exec("println(%s)", x);

    finch_finalize();

    return 0;
}