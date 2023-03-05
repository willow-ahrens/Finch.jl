#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

JULIA_DEFINE_FAST_TLS // only define this once, in an executable

int main(int argc, char** argv){

    jl_value_t* x = finch_Cint(42);

    finch_exec("println(%s)", x);

    finch_initialize();

    finch_finalize();

    return 0;
}