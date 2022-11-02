#ifndef __FINCH_H
#define __FINCH_H

#ifdef __cplusplus
    extern "C" {
#endif
/*! function FINCH_SCOPE end

    FINCH_SCOPE([stmt])

Execute the statement `stmt` in a new finch scope. All finch objects allocated
within this scope will be freed when the scope is closed, unless passed to
`finch_escape` to pass them to the parent scope. The user must not use `return`
or `break` to leave `stmt`.
*/
#define FINCH_SCOPE(ex) {\
    finch_scope_open();\
    ex\
    finch_scope_close();\
}
void finch_scope_open();
void finch_scope_close();

/*! function finch_escape end

    jl_value_t* finch_escape(jl_value_t* var)

Removes `var` from the current scope and registers it with the parent scope.
This means`var` will not be freed when the current scope is closed.
*/
jl_value_t* finch_escape(jl_value_t* var);

/*! function finch_root end

    jl_value_t* finch_root(jl_value_t* var)

Register the Julia-allocated object `var` with Finch on the current scope to
avoid garbage collecting it.
*/
jl_value_t* finch_root(jl_value_t* var);

/*! function finch_free end

    void finch_free(jl_value_t* var)

Unregister the Finch-tracked object `var` within the current scope to allow the
garbage collector to free memory. This method should be avoided in favor of
using FINCH_SCOPE to limit the lifetime of objects.
*/
void finch_free(jl_value_t* var);

/*! function finch_initialize end

    void finch_initialize()

Initialize Finch. Should be called only once before any other finch calls, from
the executable.
*/
void finch_initialize();

/*! function finch_finalize end

    void finch_finalize()

Finalize Finch. Should be called at the end of the program to allow Finch to
cleanup.
*/
void finch_finalize();

/*! function finch_eval end

    jl_value_t* finch_eval(const char* proc)

Evaluate the Julia code represented by the string `proc` at global scope in the `Main` module.
*/
jl_value_t* finch_eval(const char* proc);

/*! function finch_exec end

    jl_value_t* finch_exec(const char* proc, jl_value_t* args...)

Evaluate the Julia code represented by the string `proc` at local scope in the
`Main` module.  `proc` can optionally contain format specifiers to interpolate
julia arguments.  Format specifiers should be either `%s` for a julia input or
`%%` for a literal `%` character. For example,
```
    finch_exec("%s + %s", x, y)
```
should evaluate to x + y

`finch_exec` caches inputs by their string to avoid repeated compilation.
*/
#define finch_exec(proc, ...) finch_call(finch_exec_function(proc), ##__VA_ARGS__)
jl_function_t* finch_exec_function(const char* proc);

/*! function finch_call end

    jl_value_t* finch_call(jl_value_t* f, jl_value_t* args...)

Call the Julia function `f` on the arguments `args` and return the result. This
is a macro that counts the number of arguments.
*/
#define finch_call(f, ...) finch_call_(f, (jl_value_t*[]){finch_call_begin, ##__VA_ARGS__, finch_call_end})
extern int finch_call_begin_;
extern int finch_call_end_;
#define finch_call_begin ((jl_value_t*)&finch_call_begin_)
#define finch_call_end ((jl_value_t*)&finch_call_end_)
jl_value_t *finch_call_(jl_value_t *f, jl_value_t **args);

/*! function finch_consume_vector end

    jl_value_t* finch_consume_vector(jl_datatype_t* type, void* ptr, int len);

Create a Julia array with elements of datatype `type` from the pointer `ptr`. The array
will be of length `len`, no copying will be performed, and Finch may call `free(ptr)`.
*/
jl_value_t* finch_consume_vector(jl_datatype_t* type, void* ptr, int len);

/*! function finch_mirror_vector end

    jl_value_t* finch_mirror_vector(jl_datatype_t* type, void* ptr, int len);

Create a Julia array with elements of datatype `type` from the pointer `ptr`. The array
will be of length `len`, no copying will be performed, and Finch may not call `free(ptr)`.
*/
jl_value_t* finch_mirror_vector(jl_datatype_t* type, void* ptr, int len);

/*! function finch_T end

    void finch_[T](S x);

Create a Julia object of type T from corresponding C object `x` of type S.
*/
jl_value_t* finch_Int32(int32_t x);
jl_value_t* finch_Int64(int64_t x);
jl_value_t* finch_Cint(int x);
jl_value_t* finch_Float32(float x);
jl_value_t* finch_Float64(double x);

jl_value_t* finch_Vector_Float64(double *ptr, int len);
jl_value_t* finch_Vector_Int64(int64_t *ptr, int len);

jl_value_t* finch_Fiber(jl_value_t* lvl);
jl_value_t* finch_SparseList(jl_value_t* n, jl_value_t* lvl);
jl_value_t* finch_SparseListLevel(jl_value_t* n, jl_value_t* pos, jl_value_t* idx, jl_value_t* lvl);
jl_value_t* finch_Dense(jl_value_t* n, jl_value_t* lvl);
jl_value_t* finch_Element(jl_value_t *fill);
jl_value_t* finch_ElementLevel(jl_value_t *fill, jl_value_t *val);

#ifdef __cplusplus
    }
#endif

#endif