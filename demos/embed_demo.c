#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

JULIA_DEFINE_FAST_TLS // only define this once, in an executable

int main(int argc, char** argv){
    finch_initialize();

    jl_function_t* dense_vector_val = finch_eval("function dense_vector_data(vec)\n\
        vec.lvl.lvl.val\n\
    end");

    jl_function_t* spmv = finch_eval("function spmv(y, A, x)\n\
        @index @loop i j y[i] += A[i, j] * x[j]\n\
    end");

    int m = 4;
    int n = 10;

    int64_t A_pos[] = {1, 6, 9, 9, 10};
    int64_t A_idx[] = {1, 3, 5, 7, 9, 3, 5, 8, 3};
    double A_val[] = {2.0, 3.0, 4.0, 5.0, 6.0, 1.0, 1.0, 1.0, 7.0};

    double x_val[] = {1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0};

    jl_value_t *y = finch_Fiber(
        finch_Solid(finch_Int64(m),
        finch_Element(finch_Float64(0.0))));

    jl_value_t *A = finch_Fiber(
        finch_Solid(finch_Int64(m),
        finch_HollowList_(finch_Int64(n), finch_Vector_Int64(A_pos, 5), finch_Vector_Int64(A_idx, 9),
        finch_Element_(finch_Float64(0.0), finch_Vector_Float64(A_val, 9)))));

    finch_print(A);

    jl_value_t *x = finch_Fiber(
        finch_Solid(finch_Int64(n),
        finch_Element_(finch_Float64(0.0), finch_Vector_Float64(x_val, n))));

    finch_print(x);

    finch_call(spmv, 3, y, A, x);

    jl_value_t *_y_val = finch_call(dense_vector_val, 1, y);
    double *y_val = jl_array_data(_y_val);

    for(int i = 0; i < m; i++){
        printf("%g, ", y_val[i]);
    }
    printf("\n");

    finch_free(_y_val);

    finch_free(y);
    finch_free(A);
    finch_free(x);

    finch_finalize();
}