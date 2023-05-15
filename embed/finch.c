#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

//JULIA_DEFINE_FAST_TLS // only define this once, in an executable (not in a shared library) if you want fast code.

#define FINCH_ASSERT(check, message, ...) {\
    if(!check){\
        fprintf(stderr, "Error in %s at line %d: " message "\n", __func__, __LINE__, ##__VA_ARGS__);\
        exit(1);\
    }\
}

int finch_is_initialized = 0;

jl_function_t* Finch;
jl_function_t* root_object;
jl_function_t* is_rooted_pointer;
jl_function_t* free_object;
jl_function_t* escape_object;
jl_function_t* open_scope;
jl_function_t* close_scope;
jl_function_t* exec_function;
jl_function_t* showerror;
jl_function_t* catch_backtrace;
jl_datatype_t* reft;

jl_function_t* Fiber;
jl_function_t* SparseList;
jl_function_t* SparseListLevel;
jl_function_t* Dense;
jl_function_t* Element;
jl_function_t* ElementLevel;
jl_function_t* Ragged;
jl_function_t *SparseTriangle;

int finch_call_begin_ = 0;
int finch_call_end_ = 0;

/* required: setup the Julia context */
extern void finch_initialize(){
    if(finch_is_initialized){
        return;
    }
    jl_init();
    FINCH_ASSERT(!jl_exception_occurred(), "Could not initialize Julia");
    
    jl_eval_string("\
        scopes = [IdDict()];\n\
        refs = IdDict();\n\
    ");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not eval Julia string");

    Finch = jl_eval_string("\
        using Pkg\n\
        Pkg.activate(\""FINCH_EMBED_PATH"\", io=devnull)\n\
        Pkg.develop(path=\""FINCH_EMBED_PATH"/..\", io=devnull)\n\
        Pkg.instantiate()\n\
        using Finch;\n\
        using Printf;\n\
        Finch\n\
    ");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not find Finch module");

    root_object = jl_eval_string("\
        function root_object(ptr, rvar)\n\
            if !haskey(refs, ptr)\n\
                last(scopes)[ptr] = rvar\n\
                refs[ptr] = length(scopes)\n\
            end\n\
            nothing\n\
        end\n\
    ");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not eval root_object");

    is_rooted_pointer = jl_eval_string("\
        function is_rooted_pointer(ptr)\n\
            return haskey(refs, ptr)\n\
        end\n\
    ");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not eval is_rooted_pointer");

    free_object = jl_eval_string("\
        function free_object(ptr)\n\
            if haskey(refs, ptr)\n\
                d = pop!(refs, ptr)\n\
                delete!(scopes[d], ptr)\n\
            end\n\
            nothing\n\
        end\n\
    ");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not eval free_object");

    escape_object = jl_eval_string("\
        function escape_object(ptr)\n\
            if length(scopes) > 1\n\
                if ptr in last(scopes)\n\
                    refs[ptr] -= 1\n\
                    rvar = delete!(scopes[end], ptr)\n\
                    scopes[end - 1][ptr] = rvar\n\
                end\n\
            end\n\
            nothing\n\
        end\n\
    ");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not eval escape_object");

    open_scope = jl_eval_string("\
        function open_scope()\n\
            push!(scopes, Set())\n\
            nothing\n\
        end\n\
    ");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not eval open_scope");

    close_scope = jl_eval_string("\
        function close_scope()\n\
            for (ptr, rvar) in pairs(pop!(scopes))\n\
                pop!(refs, ptr)\n\
            end\n\
            nothing\n\
        end\n\
    ");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not eval close_scope");

    exec_function = jl_eval_string("\
        exec_functions = Dict{String, Any}()\n\
        function exec_function(proc)\n\
            return get(exec_functions, proc) do\n\
                fmt = Printf.Format(proc)\n\
                args = [gensym(Symbol(:arg, n)) for n in 1:length(fmt.formats)]\n\
                proc = Printf.format(fmt, (\"var$(repr(string(arg)))\" for arg in args)...)\n\
                body = Meta.parse(\"begin $proc end\")\n\
                eval(quote\n\
                    function $(gensym(:exec))($(args...))\n\
                        $body\n\
                    end\n\
                end)\n\
            end\n\
        end\n\
    ");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not eval exec_function");

    showerror = (jl_function_t*)jl_eval_string("Base.showerror");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not find showerror");
    catch_backtrace = (jl_function_t*)jl_eval_string("Base.catch_backtrace");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not find catch_backtrace");
    reft = (jl_datatype_t*)jl_eval_string("Base.RefValue{Any}");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not find RefValue{Any}");

    finch_is_initialized = 1;
}

jl_value_t* finch_root(jl_value_t* var){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    // Protect `var` until we add its reference to `refs`.
    JL_GC_PUSH1(&var);
    // Wrap `var` in `RefValue{Any}` and push to `refs` to protect it.
    jl_value_t* rvar = jl_new_struct(reft, var);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not construct RefValue{Any}(*var)");
    jl_value_t* ptr;
    {
        ptr = jl_box_voidpointer((void*)var);
        JL_GC_PUSH1(&ptr);
        jl_call2(root_object, ptr, rvar);
        JL_GC_POP();
    }
    JL_GC_POP();
    FINCH_ASSERT(!jl_exception_occurred(), "Could not root variable");
    return var;
}

int is_rooted(jl_value_t* var){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    int8_t res;
    jl_value_t* ptr = jl_box_voidpointer((void*)var);
    JL_GC_PUSH1(&ptr);
    jl_value_t* ret = jl_call1(is_rooted_pointer, ptr);
    {
        JL_GC_PUSH1(&ret);
        res = jl_unbox_bool(ret);
        JL_GC_POP();
    }
    JL_GC_POP();
    FINCH_ASSERT(!jl_exception_occurred(), "Could not check if variable is rooted");
    return (int)res;
}

void finch_free(jl_value_t* var){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    jl_value_t* ptr = jl_box_voidpointer((void*)var);
    JL_GC_PUSH1(&ptr);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not construct RefValue{Any}(*var)");
    jl_call1(free_object, ptr);
    JL_GC_POP();
    FINCH_ASSERT(!jl_exception_occurred(), "Could not free variable");
}

jl_value_t* finch_escape(jl_value_t* var){
    jl_value_t* ptr = jl_box_voidpointer((void*)var);
    JL_GC_PUSH1(&ptr);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not construct RefValue{Any}(*var)");
    jl_call1(escape_object, ptr);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not escape variable");
    JL_GC_POP();
    return var;
}

void finch_scope_open(){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    jl_call0(open_scope);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not open scope");
}

void finch_scope_close(){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    jl_call0(close_scope);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not close scope");
}

jl_value_t* finch_eval(const char* prg){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    jl_value_t *res = NULL;
    JL_TRY {
        const char filename[] = "none";
        jl_value_t *ast = jl_parse_all(prg, strlen(prg),
                filename, strlen(filename), 1);
        JL_GC_PUSH1(&ast);
        res = jl_toplevel_eval_in(jl_main_module, ast);
        JL_GC_POP();
        jl_exception_clear();
    }
    JL_CATCH {
        jl_value_t* bt = jl_call0(catch_backtrace);
        JL_GC_PUSH1(&bt);
        {
            jl_value_t* err = jl_current_exception();
            JL_GC_PUSH1(&err);
            jl_call3(showerror, jl_stderr_obj(), err, bt);
            JL_GC_POP();
        }
        JL_GC_POP();
        fprintf(stderr, "\n");
        FINCH_ASSERT(0, "Could not evaluate program");
    }
    return finch_root(res);
}

jl_function_t* finch_exec_function(const char* proc){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    jl_value_t* proc_arg = finch_root(jl_cstr_to_string(proc));
    jl_value_t* res = finch_call(exec_function, proc_arg);
    finch_free(proc_arg);
    return res;
}


jl_value_t *finch_call_(jl_function_t *f, jl_value_t **args) {
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    jl_value_t *v;
    jl_task_t *ct = jl_current_task;
    FINCH_ASSERT((args[0] == finch_call_begin), "pointer error")
    int nargs = 1;
    while(args[nargs] != finch_call_end){
        nargs++;
    }
    JL_TRY {
        jl_value_t **argv;
        JL_GC_PUSHARGS(argv, nargs);
        argv[0] = (jl_value_t*)f;
        for (int i = 1; i < nargs; i++){
            argv[i] = args[i];
            FINCH_ASSERT((argv[i] != NULL), "Argument %d is NULL", i);
            FINCH_ASSERT(is_rooted(argv[i]), "Argument %d is not rooted", i);
        }
        size_t last_age = ct->world_age;
        ct->world_age = jl_get_world_counter();
        v = jl_apply(argv, nargs);
        ct->world_age = last_age;
        JL_GC_POP();
        jl_exception_clear();
    }
    JL_CATCH {
        jl_value_t* bt = jl_call0(catch_backtrace);
        JL_GC_PUSH1(&bt);
        {
            jl_value_t* err = jl_current_exception();
            JL_GC_PUSH1(&err);
            jl_call3(showerror, jl_stderr_obj(), err, bt);
            JL_GC_POP();
        }
        JL_GC_POP();
        fprintf(stderr, "\n");
        FINCH_ASSERT(0, "Could not call function");
    }
    return finch_root(v);
}

jl_value_t* finch_consume_vector(jl_datatype_t* type, void* ptr, int len){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    jl_value_t* arr_type = jl_apply_array_type((jl_value_t*)type, 1);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not construct vector type");
    jl_value_t* res = (jl_value_t*) jl_ptr_to_array_1d(arr_type, ptr, len, 1);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not consume vector");
    return finch_root(res);
}
jl_value_t* finch_mirror_vector(jl_datatype_t* type, void* ptr, int len){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    jl_value_t* arr_type = jl_apply_array_type((jl_value_t*)type, 1);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not construct vector type");
    jl_value_t* res = (jl_value_t*) jl_ptr_to_array_1d(arr_type, ptr, len, 0);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not mirror vector");
    return finch_root(res);
}


void finch_finalize(){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    /* strongly recommended: notify Julia that the
         program is about to terminate. this allows
         Julia time to cleanup pending write requests
         and run all finalizers
    */
    jl_atexit_hook(0);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not finalize Julia");
}

jl_value_t* finch_Int64(int64_t x){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    return finch_root(jl_box_int64(x));
}

jl_value_t* finch_Int32(int32_t x){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    return finch_root(jl_box_int32(x));
}

jl_value_t* finch_Cint(int x){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    if(sizeof(int) == sizeof(uint32_t)){
        return finch_Int32(x);
    } else if (sizeof(int) == sizeof(uint64_t)){
        return finch_Int64(x);
    } else {
        FINCH_ASSERT(0, "C has a weird int size");
    }
}

jl_value_t* finch_Float32(float x){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    return finch_root(jl_box_float32(x));
}
jl_value_t* finch_Float64(double x){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    return finch_root(jl_box_float64(x));
}

jl_value_t* finch_Vector_Float64(double *ptr, int len){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    return finch_mirror_vector(jl_float64_type, (void*)ptr, len);
}

jl_value_t* finch_Vector_Int64(int64_t *ptr, int len){
    FINCH_ASSERT(finch_is_initialized, "finch uninitialized before use");
    return finch_mirror_vector(jl_int64_type, (void*)ptr, len);
}