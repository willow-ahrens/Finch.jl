#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

int main(int argc, char** argv){
    finch_initialize();
    int foo[] = {0, 1, 1, 2, 3, 5, 8, 13};
    jl_value_t* foo_2 = finch_consume_vector(jl_int32_type, foo, 8);
    jl_function_t* println = finch_eval("println");
    finch_free(finch_call(println, 1, foo_2));
    finch_free(println);
    finch_free(foo_2);

    jl_function_t* csr_matrix = finch_eval("function csr_matrix(m, n, pos, idx, val)\
        Fiber(\
            SolidLevel(m,\
            HollowLevel(n, pos, idx,\
            Element{0.0}(val))))\
    end");

    finch_finalize();
}