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
jl_function_t* println;
jl_function_t* displayln;
jl_function_t* getproperty;
jl_datatype_t* reft;

jl_function_t* Fiber;
jl_function_t* HollowList;
jl_function_t* HollowListLevel;
jl_function_t* Solid;
jl_function_t* Element;
jl_function_t* ElementLevel;

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
    println = (jl_function_t*)jl_eval_string("println");
    displayln = (jl_function_t*)jl_eval_string("(obj) -> (display(obj); println())");
    getproperty = (jl_function_t*)jl_eval_string("getproperty");

    Fiber = (jl_function_t*)jl_eval_string("(lvl) -> Finch.Fiber(lvl)");
    HollowList = (jl_function_t*)jl_eval_string("(m, lvl) -> Finch.HollowList(m, lvl)");
    HollowListLevel = (jl_function_t*)jl_eval_string("(m, pos, idx, lvl) -> Finch.HollowList(m, pos, idx, lvl)");
    Solid = (jl_function_t*)jl_eval_string("(m, lvl) -> Finch.Solid(m, lvl)");
    Element = (jl_function_t*)jl_eval_string("(default) -> Finch.Element{default}()");
    ElementLevel = (jl_function_t*)jl_eval_string("(default, val) -> Finch.Element{default}(val)");
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

void finch_print(jl_value_t* obj){
    jl_call1(println, obj);
}
void finch_display(jl_value_t* obj){
    jl_call1(displayln, obj);
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

jl_value_t* finch_get(jl_value_t* obj, const char *property){
    char tokens[strlen(property)];
    strcpy(tokens, property);
    jl_value_t *res = 0;
    int first = 1;
    char *token = strtok(tokens, ".");
    while (token != NULL){
        if(strlen(token) != 0){
            res = finch_call(getproperty, 2, obj, jl_symbol(token));
            if (!first) {
                finch_free(obj);
            }
            first = 0;
            obj = res;
        }
        token = strtok(NULL, ".");
    }
    return obj;
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



jl_value_t* finch_Int64(int64_t x){
    return finch_root(jl_box_int64(x));
}

jl_value_t* finch_Int32(int32_t x){
    return finch_root(jl_box_int32(x));
}

jl_value_t* finch_Float64(double x){
    return finch_root(jl_box_float64(x));
}

jl_value_t* finch_Vector_Float64(double *ptr, int len){
    return finch_mirror_vector(jl_float64_type, (void*)ptr, len);
}

jl_value_t* finch_Vector_Int64(int64_t *ptr, int len){
    return finch_mirror_vector(jl_int64_type, (void*)ptr, len);
}

jl_value_t* finch_Fiber(jl_value_t* lvl){
    jl_value_t *res = finch_root(jl_call1(Fiber, lvl));
    finch_free(lvl);
    return res;
}

jl_value_t* finch_HollowList(jl_value_t *n, jl_value_t* lvl){
    jl_value_t *res = finch_root(jl_call2(HollowList, n, lvl));
    finch_free(n);
    finch_free(lvl);
    return res;
}

jl_value_t* finch_HollowListLevel(jl_value_t *n, jl_value_t *pos, jl_value_t *idx, jl_value_t* lvl){
    jl_value_t* args[] = {n, pos, idx, lvl};
    jl_value_t *res = finch_root(jl_call(HollowListLevel, args, 4));
    finch_free(n);
    finch_free(pos);
    finch_free(idx);
    finch_free(lvl);
    return res;
}

jl_value_t* finch_Solid(jl_value_t *n, jl_value_t* lvl){
    jl_value_t *res = finch_root(jl_call2(Solid, n, lvl));
    finch_free(n);
    finch_free(lvl);
    return res;
}

jl_value_t* finch_Element(jl_value_t *fill){
    jl_value_t *res = finch_root(jl_call1(Element, fill));
    finch_free(fill);
    return res;
}

jl_value_t* finch_ElementLevel(jl_value_t *fill, jl_value_t *val){
    jl_value_t *res = finch_root(jl_call2(ElementLevel, fill, val));
    finch_free(fill);
    finch_free(val);
    return res;
}