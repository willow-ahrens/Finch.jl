#ifndef __FINCH_H
#define __FINCH_H

extern void finch_initialize();

jl_value_t* finch_eval(const char* prg);

jl_value_t* finch_call(jl_function_t* func, int argc, ...);

void finch_free(jl_value_t* var);

void finch_finalize();

#endif