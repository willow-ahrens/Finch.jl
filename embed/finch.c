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
    setindex = jl_get_function(jl_base_module, "setindex!");
    delete = jl_get_function(jl_base_module, "delete!");
    reft = (jl_datatype_t*)jl_eval_string("Base.RefValue{Any}");
}

jl_value_t* finch_root(jl_value_t* var){
    // Protect `var` until we add its reference to `refs`.
    JL_GC_PUSH1(&var);
    // Wrap `var` in `RefValue{Any}` and push to `refs` to protect it.
    jl_value_t* rvar = jl_new_struct(reft, var);
    JL_GC_POP();
    jl_call3(setindex, refs, rvar, rvar);
    return var;
}

void finch_free(jl_value_t* var){
    jl_value_t* rvar = jl_new_struct(reft, var);
    jl_call2(delete, refs, rvar);
}

jl_value_t* finch_eval(const char* prg){
    jl_value_t* res = jl_eval_string(prg);
    if (jl_exception_occurred()){
        printf("%s \n", jl_typeof_str(jl_exception_occurred()));
        exit(1);
    }
    return finch_root(res);
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
    if (jl_exception_occurred()){
        printf("%s \n", jl_typeof_str(jl_exception_occurred()));
        exit(1);
    }
    return finch_root(res);
}

jl_value_t* finch_consume_vector(jl_datatype_t* type, void* ptr, int len){
    jl_value_t* arr_type = jl_apply_array_type((jl_value_t*)type, 1);
    jl_value_t* res = (jl_value_t*) jl_ptr_to_array_1d(arr_type, ptr, len, 1);
    return finch_root(res);
}

jl_value_t* finch_mirror_vector(jl_datatype_t* type, void* ptr, int len){
    jl_value_t* arr_type = jl_apply_array_type((jl_value_t*)type, 1);
    jl_value_t* res = (jl_value_t*) jl_ptr_to_array_1d(arr_type, ptr, len, 0);
    return finch_root(res);
}


void finch_finalize(){
    /* strongly recommended: notify Julia that the
         program is about to terminate. this allows
         Julia time to cleanup pending write requests
         and run all finalizers
    */
    jl_atexit_hook(0);
}