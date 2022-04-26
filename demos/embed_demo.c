#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

int main(int argc, char** argv){
    finch_initialize();
    jl_function_t* csr_matrix = finch_eval("function csr_matrix(m, n, pos, idx, val)\
        Fiber(\
            SolidLevel(m,\
            HollowLevel(n, pos, idx,\
            Element{0.0}(val))))\
    end");

    finch_finalize();
}