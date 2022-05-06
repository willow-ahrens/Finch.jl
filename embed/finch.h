#ifndef __FINCH_H
#define __FINCH_H

/*!
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

/*!
    jl_value_t* finch_escape(jl_value_t* var)

Removes `var` from the current scope and registers it with the parent scope.
This means`var` will not be freed when the current scope is closed.
*/
jl_value_t* finch_escape(jl_value_t* var);

/*!
    jl_value_t* finch_root(jl_value_t* var)

Register the Julia-allocated object `var` with Finch on the current scope to
avoid garbage collecting it.
*/
jl_value_t* finch_root(jl_value_t* var);

/*!
    void finch_free(jl_value_t* var)

Unregister the Finch-tracked object `var` within the current scope to allow the
garbage collector to free memory. This method should be avoided in favor of
using FINCH_SCOPE to limit the lifetime of objects.
*/
void finch_free(jl_value_t* var);

/*!
    void finch_initialize()

Initialize Finch. Should be called only once before any other finch calls, from
the executable.
*/
void finch_initialize();

/*!
    void finch_finalize();

Finalize Finch. Should be called at the end of the program to allow Finch to
cleanup.
*/
void finch_finalize();

/*!
    jl_value_t* finch_eval(const char* prg)

Evaluate the Julia string represented by `prg` at global scope in the `Main` module.
*/
jl_value_t* finch_eval(const char* prg);

/*!
    jl_value_t* finch_call(jl_value_t* f, jl_value_t* args...)

Call the Julia function `f` on the arguments `args` and return the result. This
is a macro that counts the number of arguments.
*/
jl_value_t* finch_eval(const char* prg);
#define finch_call(f, ...) finch_call_(f, (jl_value_t*[]){finch_call_begin, ##__VA_ARGS__, finch_call_end})
int finch_call_begin_ = 0;
int finch_call_end_ = 0;
#define finch_call_begin ((jl_value_t*)&finch_call_begin_)
#define finch_call_end ((jl_value_t*)&finch_call_end_)
jl_value_t *finch_call_(jl_value_t *f, jl_value_t **args);

/*!
    jl_value_t* finch_get(jl_value_t* obj, const char *property);

Get the property of `obj` specified by the period-delimited path of property
names given in `property`. For instance,
```
    printf("%d\n", finch_get(finch_eval("(x = (y = 42,), z = 12,)"), ".x.y"));
```
should print `42`.
*/
jl_value_t* finch_get(jl_value_t* obj, const char *property);

/*!
    jl_value_t* finch_consume_vector(jl_datatype_t* type, void* ptr, int len);

Create a Julia array with elements of datatype `type` from the pointer `ptr`. The array
will be of length `len`, no copying will be performed, and Finch may call `free(ptr)`.
*/
jl_value_t* finch_consume_vector(jl_datatype_t* type, void* ptr, int len);

/*!
    jl_value_t* finch_mirror_vector(jl_datatype_t* type, void* ptr, int len);

Create a Julia array with elements of datatype `type` from the pointer `ptr`. The array
will be of length `len`, no copying will be performed, and Finch may not call `free(ptr)`.
*/
jl_value_t* finch_mirror_vector(jl_datatype_t* type, void* ptr, int len);


/*!
    void finch_print(jl_value_t* obj);

Call `println(obj)`.
*/
void finch_print(jl_value_t* obj);

/*!
    void finch_display(jl_value_t* obj);

Call `display(obj)`.
*/
void finch_display(jl_value_t* obj);

/*!
    void finch_Int32(int32_t x);

Create a Julia Int32 object from `x`.
*/
jl_value_t* finch_Int32(int32_t x);

/*!
    void finch_Int64(int64_t x);

Create a Julia Int64 object from `x`.
*/
jl_value_t* finch_Int64(int64_t x);

/*!
    void finch_Int(int x);

Create an integer Julia object of the same size as `x`.
*/
jl_value_t* finch_Int(int x);

/*!
    void finch_Float32(float x);

Create a Julia Float32 object from `x`.
*/
jl_value_t* finch_Float32(float x);

/*!
    void finch_Float64(float x);

Create a Julia Float64 object from `x`.
*/
jl_value_t* finch_Float64(double x);

jl_value_t* finch_Vector_Float64(double *ptr, int len);
jl_value_t* finch_Vector_Int64(int64_t *ptr, int len);

jl_value_t* finch_Fiber(jl_value_t* lvl);
jl_value_t* finch_HollowList(jl_value_t* n, jl_value_t* lvl);
jl_value_t* finch_HollowListLevel(jl_value_t* n, jl_value_t* pos, jl_value_t* idx, jl_value_t* lvl);
jl_value_t* finch_Solid(jl_value_t* n, jl_value_t* lvl);
jl_value_t* finch_Element(jl_value_t *fill);
jl_value_t* finch_ElementLevel(jl_value_t *fill, jl_value_t *val);

#endif