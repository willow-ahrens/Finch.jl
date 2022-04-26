#ifndef __FINCH_H
#define __FINCH_H

extern void finch_initialize();

/*
enum finch_object_type_t{
    finch_kernel_type,
    finch_jl_value_type
}

struct finch_object_t{
    finch_object_type_t type;
}

struct finch_kernel_t{
    finch_object_type_t type;
    jl_function_t* func;
    int nargs;
}
*/

jl_value_t* finch_eval(const char* prg);

jl_value_t* finch_call(jl_function_t* func, int argc, ...);

jl_value_t* finch_get(jl_value_t* obj, const char *property);

jl_value_t* finch_consume_vector(jl_datatype_t* type, void* ptr, int len);

jl_value_t* finch_mirror_vector(jl_datatype_t* type, void* ptr, int len);

jl_value_t* finch_root(jl_value_t* var);

void finch_free(jl_value_t* var);

void finch_print(jl_value_t* obj);
void finch_display(jl_value_t* obj);

void finch_finalize();

jl_value_t* finch_Int64(int64_t x);
jl_value_t* finch_Int32(int32_t x);
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