#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

int finch_call_begin_;
int finch_call_end_;

//JULIA_DEFINE_FAST_TLS // only define this once, in an executable (not in a shared library) if you want fast code.

#define FINCH_ASSERT(check, message, ...) {\
    if(!check){\
        fprintf(stderr, "Error in %s: " message "\n", __func__, ##__VA_ARGS__);\
        exit(1);\
    }\
}

jl_function_t* Finch;
jl_function_t* root_object;
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

int finch_call_begin_ = 0;
int finch_call_end_ = 0;

/* required: setup the Julia context */
extern void finch_initialize(){
    jl_init();
    FINCH_ASSERT(!jl_exception_occurred(), "Could not initialize Julia");
    
    jl_eval_string("\
        scopes = [Set()];\n\
        refs = IdDict();\n\
    ");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not eval Julia string");

    Finch = jl_eval_string("\
        using Pkg;\n\
        Pkg.activate(joinpath(dirname(\""__FILE__"\"), \"..\"), io=devnull)\n\
        Pkg.instantiate()\n\
        using Finch;\n\
        using Printf;\n\
        Finch\n\
    ");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not find Finch module");

    root_object = jl_eval_string("\
        function root_object(rvar)\n\
            if !haskey(refs, rvar)\n\
                push!(last(scopes), rvar)\n\
                refs[rvar] = length(scopes)\n\
            end\n\
            nothing\n\
        end\n\
    ");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not eval root_object");

    free_object = jl_eval_string("\
        function free_object(rvar)\n\
            if haskey(refs, rvar)\n\
                d = pop!(refs, rvar)\n\
                pop!(scopes[d], rvar)\n\
            end\n\
            nothing\n\
        end\n\
    ");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not eval free_object");

    escape_object = jl_eval_string("\
        function escape_object(rvar)\n\
            if length(scopes) > 1\n\
                if rvar in last(scopes)\n\
                    refs[rvar] -= 1\n\
                    pop!(scopes[end], rvar)\n\
                    push!(scopes[end - 1], rvar)\n\
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
            for rvar in pop!(scopes)\n\
                pop!(refs, rvar)\n\
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

    Fiber = (jl_function_t*)jl_eval_string("(lvl) -> Finch.Fiber(lvl)");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not find Fiber");
    SparseList = (jl_function_t*)jl_eval_string("(m, lvl) -> Finch.SparseList(m, lvl)");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not find SparseList");
    SparseListLevel = (jl_function_t*)jl_eval_string("(m, pos, idx, lvl) -> Finch.SparseList(m, pos, idx, lvl)");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not find SparseListLevel");
    Dense = (jl_function_t*)jl_eval_string("(m, lvl) -> Finch.Dense(m, lvl)");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not find Dense");
    Element = (jl_function_t*)jl_eval_string("(default) -> Finch.Element{default}()");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not find Element");
    ElementLevel = (jl_function_t*)jl_eval_string("(default, val) -> Finch.Element{default}(val)");
    FINCH_ASSERT(!jl_exception_occurred(), "Could not find ElementLevel");
}

jl_value_t* finch_root(jl_value_t* var){
    // Protect `var` until we add its reference to `refs`.
    JL_GC_PUSH1(&var);
    // Wrap `var` in `RefValue{Any}` and push to `refs` to protect it.
    jl_value_t* rvar = jl_new_struct(reft, var);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not construct RefValue{Any}(*var)");
    JL_GC_POP();
    jl_call1(root_object, rvar);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not root variable");
    return var;
}

void finch_free(jl_value_t* var){
    jl_value_t* rvar = jl_new_struct(reft, var);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not construct RefValue{Any}(*var)");
    jl_call1(free_object, rvar);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not free variable");
}

jl_value_t* finch_escape(jl_value_t* var){
    jl_value_t* rvar = jl_new_struct(reft, var);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not construct RefValue{Any}(*var)");
    jl_call1(escape_object, rvar);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not escape variable");
    return var;
}

void finch_scope_open(){
    jl_call0(open_scope);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not open scope");
}

void finch_scope_close(){
    jl_call0(close_scope);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not close scope");
}

jl_value_t* finch_eval(const char* prg){
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
    return finch_call(exec_function, jl_cstr_to_string(proc));
}

jl_value_t *finch_call_(jl_function_t *f, jl_value_t **args) {
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
            FINCH_ASSERT((args[i] != NULL), "Argument %d is NULL", i)
            argv[i] = args[i];
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
    jl_value_t* arr_type = jl_apply_array_type((jl_value_t*)type, 1);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not construct vector type");
    jl_value_t* res = (jl_value_t*) jl_ptr_to_array_1d(arr_type, ptr, len, 1);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not consume vector");
    return finch_root(res);
}
jl_value_t* finch_mirror_vector(jl_datatype_t* type, void* ptr, int len){
    jl_value_t* arr_type = jl_apply_array_type((jl_value_t*)type, 1);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not construct vector type");
    jl_value_t* res = (jl_value_t*) jl_ptr_to_array_1d(arr_type, ptr, len, 0);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not mirror vector");
    return finch_root(res);
}


void finch_finalize(){
    /* strongly recommended: notify Julia that the
         program is about to terminate. this allows
         Julia time to cleanup pending write requests
         and run all finalizers
    */
    jl_atexit_hook(0);
    FINCH_ASSERT(!jl_exception_occurred(), "Could not finalize Julia");
}

jl_value_t* finch_Int64(int64_t x){
    return finch_root(jl_box_int64(x));
}

jl_value_t* finch_Int32(int32_t x){
    return finch_root(jl_box_int32(x));
}

jl_value_t* finch_Cint(int x){
    if(sizeof(int) == sizeof(uint32_t)){
        return finch_Int32(x);
    } else if (sizeof(int) == sizeof(uint64_t)){
        return finch_Int64(x);
    } else {
        FINCH_ASSERT(0, "C has a weird int size");
    }
}

jl_value_t* finch_Float32(float x){
    return finch_root(jl_box_float32(x));
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
    jl_value_t *res = finch_call(Fiber, lvl);
    return res;
}

jl_value_t* finch_SparseList(jl_value_t *n, jl_value_t* lvl){
    jl_value_t *res = finch_call(SparseList, n, lvl);
    return res;
}

jl_value_t* finch_SparseListLevel(jl_value_t *n, jl_value_t *pos, jl_value_t *idx, jl_value_t* lvl){
    jl_value_t *res = finch_call(SparseListLevel, n, pos, idx, lvl);
    return res;
}

jl_value_t* finch_Dense(jl_value_t *n, jl_value_t* lvl){
    jl_value_t *res = finch_call(Dense, n, lvl);
    return res;
}

jl_value_t* finch_Element(jl_value_t *fill){
    jl_value_t *res = finch_call(Element, fill);
    return res;
}

jl_value_t* finch_ElementLevel(jl_value_t *fill, jl_value_t *val){
    jl_value_t *res = finch_call(ElementLevel, fill, val);
    return res;
}