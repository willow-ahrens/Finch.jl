#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

JULIA_DEFINE_FAST_TLS // only define this once, in an executable

int main(int argc, char** argv){
    finch_initialize();

    jl_function_t* print_tensor = finch_eval("function print_tensor(A)\n\
        println(FiberArray(A))\n\
    end\n\
    ");
    jl_function_t* println = finch_eval("println");
    jl_function_t* empty_dense_vector = finch_eval("function empty_dense_vector(m)\n\
        Fiber(\n\
            Solid(m,\n\
            Element{0.0}()))\n\
    end");
    jl_function_t* dense_vector = finch_eval("function dense_vector(m, val)\n\
        Fiber(\n\
            Solid(m,\n\
            Element{0.0}(val)))\n\
    end");
    jl_function_t* dense_vector_val = finch_eval("function dense_vector_data(vec)\n\
        vec.lvl.lvl.val\n\
    end");
    jl_function_t* csr_matrix = finch_eval("function csr_matrix(m, n, pos, idx, val)\n\
        Fiber(\n\
            Solid(m,\n\
            HollowList(n, pos, idx,\n\
            Element{0.0}(val))))\n\
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

    jl_value_t *_m = finch_root(jl_box_int64(m));
    jl_value_t *_n = finch_root(jl_box_int64(n));

    jl_value_t *_y = finch_call(empty_dense_vector, 1, _m);

    jl_value_t *_A_pos = finch_mirror_vector(jl_int64_type, A_pos, 5);
    jl_value_t *_A_idx = finch_mirror_vector(jl_int64_type, A_idx, 9);
    jl_value_t *_A_val = finch_mirror_vector(jl_float64_type, A_val, 9);
    jl_value_t *_A = finch_call(csr_matrix, 5, _m, _n, _A_pos, _A_idx, _A_val);
    finch_free(finch_call(print_tensor, 1, _A));

    jl_value_t *_x_val = finch_mirror_vector(jl_float64_type, x_val, n);
    jl_value_t *_x = finch_call(dense_vector, 2, _n, _x_val);
    finch_free(finch_call(print_tensor, 1, _x));

    finch_free(finch_call(spmv, 3, _y, _A, _x));

    finch_free(finch_call(print_tensor, 1, _y));

    jl_value_t *_y_val = finch_call(dense_vector_val, 1, _y);
    double *y_val = jl_array_data(_y_val);

    for(int i = 0; i < m; i++){
        printf("%g, ", y_val[i]);
    }
    printf("\n");

    finch_free(_m);
    finch_free(_n);

    finch_free(_y);
    finch_free(_y_val);
    finch_free(_A_pos);
    finch_free(_A_idx);
    finch_free(_A_val);
    finch_free(_A);
    finch_free(_x_val);
    finch_free(_x);

    finch_finalize();
}