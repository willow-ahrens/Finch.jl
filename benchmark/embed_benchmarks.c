#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>
#include <time.h>

JULIA_DEFINE_FAST_TLS // only define this once, in an executable

int hello(int a){
    return a + 1;
}

int m = 4;
int n = 10;

int64_t A_pos[] = {1, 6, 9, 9, 10};
int64_t A_idx[] = {1, 3, 5, 7, 9, 3, 5, 8, 3};
double A_val[] = {2.0, 3.0, 4.0, 5.0, 6.0, 1.0, 1.0, 1.0, 7.0};

double x_val[] = {1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0};

jl_function_t* spmv;
jl_value_t *y;
jl_value_t *A;
jl_value_t *x;

void benchmarks_initialize(){
    finch_initialize();

    spmv = finch_eval("function spmv(y, A, x)\n\
        @finch @loop i j y[i] += A[i, j] * x[j]\n\
    end");

    y = finch_Fiber(
        finch_Dense(finch_Int64(m),
        finch_Element(finch_Float64(0.0))));

    A = finch_Fiber(
        finch_Dense(finch_Int64(m),
        finch_SparseListLevel(finch_Int64(n), finch_Vector_Int64(A_pos, 5), finch_Vector_Int64(A_idx, 9),
        finch_ElementLevel(finch_Float64(0.0), finch_Vector_Float64(A_val, 9)))));

    x = finch_Fiber(
        finch_Dense(finch_Int64(n),
        finch_ElementLevel(finch_Float64(0.0), finch_Vector_Float64(x_val, n))));
}

long benchmark_spmv(int evals){
    struct timespec tic;
    struct timespec toc;
    clock_gettime(CLOCK_REALTIME, &tic);
    for(int i = 0; i < evals; i++) {
        finch_call(spmv, y, A, x);
    }
    clock_gettime(CLOCK_REALTIME, &toc);
    long elapsed = (toc.tv_sec - tic.tv_sec) * 1000000000 +
                (toc.tv_nsec - tic.tv_nsec);
    return elapsed;
}

void benchmarks_finalize() {
    finch_finalize();
}