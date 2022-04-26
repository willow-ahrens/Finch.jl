#ifndef __FINCH_H
#define __FINCH_H

extern void finch_initialize();

jl_value_t* finch_eval(const char* prg);

jl_value_t* finch_call(jl_function_t* func, int argc, ...);

jl_value_t* finch_consume_vector(jl_datatype_t* type, void* ptr, int len);

jl_value_t* finch_mirror_vector(jl_datatype_t* type, void* ptr, int len);

void finch_free(jl_value_t* var);

void finch_finalize();

#endif