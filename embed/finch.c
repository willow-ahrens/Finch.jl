#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

//JULIA_DEFINE_FAST_TLS // only define this once, in an executable (not in a shared library) if you want fast code.

jl_value_t* refs;
jl_function_t* Finch;
jl_function_t* setindex;
jl_function_t* delete;
jl_datatype_t* reft;

/* required: setup the Julia context */
extern void finch_initialize(){
    jl_init();
    refs = jl_eval_string("refs = IdDict()");
    Finch = jl_eval_string("\
        #using Pkg;\n\
        #Pkg.add(\"Finch\");\n\
        using Finch;\n\
        Finch\
    ");
    setindex = jl_get_function(jl_base_module, "setindex");
    delete = jl_get_function(jl_base_module, "delete!");
    reft = (jl_datatype_t*)jl_eval_string("Base.RefValue{Any}");
}

void finch_root(jl_value_t* var){
    // Protect `var` until we add its reference to `refs`.
    JL_GC_PUSH1(&var);
    // Wrap `var` in `RefValue{Any}` and push to `refs` to protect it.
    jl_value_t* rvar = jl_new_struct(reft, var);
    JL_GC_POP();
    jl_call3(setindex, refs, rvar, rvar);
}

jl_value_t* finch_eval(const char* prg){
    jl_value_t* res = jl_eval_string(prg);
    finch_root(res);
    return res;
}

jl_value_t* finch_call(jl_function_t* func, int argc, ...){
    va_list argl;
    jl_value_t* argv[argc];
    va_start(argl, argc);
    for(int i = 0; i < argc; i++){
        argv[i] = va_arg(argl, jl_value_t*);
    }
    va_end(argl);
    jl_value_t* res = jl_call(func, argv, argc);
    finch_root(res);
    return res;
}

void finch_free(jl_value_t* var){
    jl_value_t* rvar = jl_new_struct(reft, var);
    jl_call2(delete, refs, rvar);
}

void finch_finalize(){
    /* strongly recommended: notify Julia that the
         program is about to terminate. this allows
         Julia time to cleanup pending write requests
         and run all finalizers
    */
    jl_atexit_hook(0);
}

/*
csr_matrix = jl_eval_string("function csr_matrix(m, n, pos, idx, val)\
    Fiber(\
        SolidLevel(m,\
        HollowLevel(n, pos, idx,\
        Element{0.0}(val))))
end");

dense_vector = jl_eval_string("function dense_vector(m, val)\
    Fiber(\
        SolidLevel(m,\
        Element{0.0}(val))))
end");

spmv_kernel = jl_eval_string("function spmv(y, A, x)\
    @index @loop i j y[i] += A[i, j] * x[i]\
    (y,)
end");

A = jl_call(csr_matrix, m, n, A_pos, A_idx, A_val);
x = jl_call(dense_vector, n, x_val);
y = jl_call(dense_vector, m, y_val);

jl_call(kernel, y, A, x)

jl_value_t* jl_ptr_to_vector(jl_value_t* type, void* ptr, int len, int owns){
    jl_value_t* arr_type = jl_apply_array_type(type, 1)
    jl_value_t* res = jl_ptr_to_array_1d(arr_type, ptr, len, owns);
}

jl_value_t* array_type = jl_apply_array_type((jl_value_t*)jl_uint8_type, 1);
jl_value_t *a = jl_ptr_to_array_1d(array_type, c, 10, 0);
jl_value_t *s = jl_call1(jl_get_function(jl_base_module, "String"), a);

res = jlx_detuple(jlx_call(spmv, y, A, x), &y)

jl_call(kernel, [a, b, c], 3)

extern jl_value_t* finch_name(const char* str){
    jl_value_t* sym = *jl_symbol(*str);
    JL_GC_PUSH1(&sym);
    jl_value_t* res = jl_call1(Name, jl_symbol(*sym))

    root(res);

    JL_GC_POP();
    return res
}

extern jl_value_t* finch_access(jl_value_t* tns, const jl_value_t** idxs, int n_idxs){
    jl_value_t* args[1 + n_idxs];
    args[1] = tns;
    for (i = 0; i < n_idxs; i++) {
        args[1 + i] = idx[i];
    }

    jl_value_t* res = jl_call(Access, args, 1 + n_idxs);

    root(res);
    for (i = 0; i < n_idx; i++) {
        finch_free(idxs[i]);
    }
    return res
}

void finch_finalize(){
    jl_atexit_hook(0);
}
*/

/*
finch_vector(* c){
    n = strlen(c);
    jl_value_t* array_type = jl_apply_array_type((jl_value_t*)jl_uint8_type, 1);
    jl_value_t *a = jl_ptr_to_array_1d(array_type, c, 10, 0);
    jl_value_t *s = jl_call1(jl_get_function(jl_base_module, "String"), a);
}


i// This functions shall be executed only once, during the initialization.
jl_value_t* refs = jl_eval_string("refs = IdDict()");
jl_function_t* setindex = jl_get_function(jl_base_module, "setindex!");
jl_datatype_t* reft = (jl_datatype_t*)jl_eval_string("Base.RefValue{Any}");

...

// `var` is the variable we want to protect between function calls.
jl_value_t* var = 0;

...

// `var` is a `Float64`, which is immutable.
var = jl_eval_string("sqrt(2.0)");

// Protect `var` until we add its reference to `refs`.
JL_GC_PUSH1(&var);

// Wrap `var` in `RefValue{Any}` and push to `refs` to protect it.
jl_value_t* rvar = jl_new_struct(reft, var);
JL_GC_POP();

jl_call3(setindex, refs, rvar, rvar);
*/