#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

JULIA_DEFINE_FAST_TLS // only define this once, in an executable

int main(int argc, char** argv){
    finch_initialize();

    jl_value_t* q = finch_Int64(1);
    finch_free(q);
    finch_free(q);

    jl_function_t* spmv = finch_eval("function spmv(y, A, x)\n\
        @finch @loop i j y[i] += A[i, j] * x[j]\n\
    end");

    int m = 4;
    int n = 10;

    int64_t A_pos[] = {1, 6, 9, 9, 10};
    int64_t A_idx[] = {1, 3, 5, 7, 9, 3, 5, 8, 3};
    double A_val[] = {2.0, 3.0, 4.0, 5.0, 6.0, 1.0, 1.0, 1.0, 7.0};

    double x_val[] = {1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0};

    jl_value_t* y = finch_exec("@fiber d(e(0.0))");

    jl_value_t* A = finch_exec("Fiber(Dense(SparseList(Element(0.0, %s), %s, %s, %s), %s))",
        finch_Vector_Float64(A_val, 9),
        finch_Int64(n),
        finch_Vector_Int64(A_pos, 5),
        finch_Vector_Int64(A_idx, 9),
        finch_Int64(m));

    finch_exec("println(%s)", A);

    jl_value_t *x = finch_exec("Fiber(Dense(Element(0.0, %s), %s))", finch_Vector_Float64(x_val, n), finch_Int64(n));

    finch_exec("println(%s)", x);

    finch_call(spmv, y, A, x);

    jl_value_t *y_val = finch_exec("%s.lvl.lvl.val", y);

    double *y_data = jl_array_data(y_val);

    for(int i = 0; i < m; i++){
        printf("%g, ", y_data[i]);
    }
    printf("\n");

    finch_finalize();

    return 0;
}