
// N int

// source int

// edges int[N][N]

#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

JULIA_DEFINE_FAST_TLS // only define this once, in an executable

int N = 5;
int source = 5;
jl_value_t* edges = 0;

struct bfs_data {
    jl_value_t* F;

    jl_value_t* P;
};

// Let Init() -> (F int[N], P int[N])
//     F[j] = (j == source)
//     P[j] = (j == source) * (0 - 2) + (j != source) * (0 - 1)
// End
void Init(struct bfs_data* data) {
     jl_function_t* F_init = finch_eval("function F_init(F, source)\n\
    @index @loop j F[j] = (j == $source)\n\
end");
    jl_value_t *val = finch_eval("Cint[]");
    jl_value_t* F = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), val))
    );
    finch_call(F_init, F, finch_Cint(source));
    data->F = F;

     jl_function_t* P_init = finch_eval("function P_init(P, source)\n\
    @index @loop j P[j] = (j == $source) * (0 - 2) + (j != $source) * (0 - 1)\n\
end");

    jl_value_t* P = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(P_init, P, finch_Cint(source));
    data->P = P;
}

void V_update(struct bfs_data* in_data, jl_value_t* V_out) {
    jl_function_t* V_func = finch_eval("function V_func(V_out, P_in)\n\
    @index @loop j V_out[j] = (P_in[j] == (0 - 1))\n\
end");
    finch_call(V_func, V_out, in_data->P);
    // printf("V_out:\n");
    // finch_exec("println(%s)\n", V_out);
}

void F_P_update(struct bfs_data* in_data, struct bfs_data* out_data, jl_value_t* V_out)  {
    jl_function_t* P_F_func = finch_eval("function P_F(F_out, P_out, P_in, edges, F_in, V_out, N)\n\ 
    B = Finch.Fiber(\n\
        Solid(N,\n\
            Element{0, Cint}([])\n\
        )\n\
    )\n\
    @index @loop j k begin\n\
        F_out[j] <<$or>>= edges[j, k] * F_in[k] * V_out[j]\n\
        B[j] <<$choose>>= edges[j, k] * F_in[k] * V_out[j] * k\n\
      end\n\
    @index @loop j P_out[j] = $choose(B[j], P_in[j])\n\
end");

    jl_value_t* F_out = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );

    jl_value_t* P_out = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );

    finch_call(P_F_func, F_out, P_out, in_data->P, edges, in_data->F, V_out, finch_Cint(N));

//     jl_function_t* display = finch_eval("function display_lowered(F_out, P_out, P_in, edges, F_in, V_out, N)\n\
//     B = Finch.Fiber(\n\
//         Solid(N,\n\
//             Element{0, Cint}([])\n\
//         )\n\
//     )\n\
//     ex1 = @index_program_instance @loop j k begin\n\
//         F_out[j] <<$or>>= edges[j, k] * F_in[k] * V_out[j]\n\
//         B[j] <<$choose>>= edges[j, k] * F_in[k] * V_out[j] * k\n\
//       end\n\
//     display(execute_code_lowered(:ex1, typeof(ex1)))\n\
//     ex2 = @index_program_instance @loop j P_out[j] = $choose(B[j], P_in[j])\n\
//     display(execute_code_lowered(:ex2, typeof(ex2)))\n\
//     println()\n\
// end");
//     finch_call(display, F_out, P_out, in_data->P, edges, in_data->F, V_out, finch_Cint(N));
}

void F_update(struct bfs_data* in_data, struct bfs_data* out_data, jl_value_t* V_out) {
    jl_function_t* F_func = finch_eval("function F_out_func(F_out, edges, F_in, V_out)\n\
    @index @loop j k F_out[j] <<$or>>= edges[j, k] * F_in[k] * V_out[j]\n\
end");
    jl_value_t* F_out = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(F_func, F_out, edges, in_data->F, V_out);
    // printf("F_out: \n");
    // finch_exec("println(%s)\n", F_out);
    out_data->F = F_out;
}

void P_update(struct bfs_data* in_data, struct bfs_data* out_data, jl_value_t* V_out) {
    jl_function_t* P_func = finch_eval("function P_out_func(P_out, edges, F_in, V_out, P_in, N)\n\
    B = Finch.Fiber(\n\
        Solid(N,\n\
            Element{0, Cint}([])\n\
        )\n\
    )\n\
    @index @loop j k B[j] <<$choose>>= edges[j, k] * F_in[k] * V_out[j] * k\n\
    @index @loop j P_out[j] = $choose(P_in[j], B[j])\n\
end");
    jl_value_t* P_out = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(P_func, P_out, edges, in_data->F, V_out, in_data->P, finch_Cint(N));
    // printf("Old F: \n");
    // finch_exec("println(%s)\n", in_data->F);

    // printf("Old P: \n");
    // finch_exec("println(%s)\n", in_data->P);

    // printf("New V: \n");
    // finch_exec("println(%s)\n", V_out);

    // printf("P_out: \n");
    // finch_exec("println(%s)\n", P_out);
    out_data->P = P_out;
}

//Let BFS_Step(F_in int[N], P_in int[N], V_in int[N]) -> (F_out int[N], P_out int[N], V_out int[N])
//  V_out[j] = P_in[j] == 0 - 1
//  F_out[j] = edges[j][k] * F_in[k] * V_out[j] | k: (OR, 0)   / k:(CHOOSE, 0)
//  P_out[j] = edges[j][k] * F_in[k] * V_out[j] * (k + 1) | k:(CHOOSE, P_in[j])
//End
void BFS_Step(struct bfs_data* in_data, struct bfs_data* out_data) {
    jl_value_t* V_out = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    // printf("Before V_update\n");
    V_update(in_data, V_out);
    // printf("Before F_update\n");
    F_P_update(in_data, out_data, V_out);
    // F_update(in_data, out_data, V_out);
    // // printf("Before P_update\n");
    // P_update(in_data, out_data, V_out);
}

int outer_loop_condition(jl_value_t* F) {

    jl_value_t *F_val = finch_exec("%s.lvl.lvl.val", F);
    double *F_data = jl_array_data(F_val);
    for(int i = 0; i < N; i++){
        if (F_data[i] != 0) {
            return 0;
        }
    }

    return 1;
}

//Let BFS() -> (P_out int[N], F_in int[N], P_in int[N], V int[N])
//  F_in, P_in = Init()
//  V[i] = 0
//  _, P_out, _ = BFS_Step*(F_in, P_in, V) | (#1 == 0)
//End
void BFS(struct bfs_data* data) {
    Init(data);

    struct bfs_data new_data = {};
    while(!outer_loop_condition(data->F)) {
        BFS_Step(data, &new_data);
        *data = new_data;
    }
}

int main(int argc, char** argv) {
    finch_initialize();

    jl_value_t* res = finch_eval("using RewriteTools\n\
    using Finch.IndexNotation\n\
    using Finch: execute_code_lowered\n");

    res = finch_eval("or(x,y) = x == 1|| y == 1\n\
function choose(x, y)\n\
    if y != 0\n\
        return y\n\
    else\n\
        return x\n\
    end\n\
end");

    res = finch_eval("@slots a b c d e i j Finch.add_rules!([\n\
    (@rule @i(@chunk $i a (b[j...] <<min>>= $d)) => if Finch.isliteral(d) && i ∉ j\n\
        @i (b[j...] <<min>>= $d)\n\
    end),\n\
    (@rule @i(@chunk $i a @multi b... (c[j...] <<min>>= $d) e...) => begin\n\
        if Finch.isliteral(d) && i ∉ j\n\
            @i @multi (c[j...] <<min>>= $d) @chunk $i a @i(@multi b... e...)\n\
        end\n\
    end),\n\
    (@rule @i(@chunk $i a (b[j...] <<$or>>= $d)) => if Finch.isliteral(d) && i ∉ j\n\
        @i (b[j...] <<$or>>= $d)\n\
    end),\n\
    (@rule @i(@chunk $i a @multi b... (c[j...] <<$or>>= $d) e...) => begin\n\
        if Finch.isliteral(d) && i ∉ j\n\
            @i @multi (c[j...] <<$or>>= $d) @chunk $i a @i(@multi b... e...)\n\
        end\n\
    end),\n\
])\n\
\n\
Finch.register()");

    jl_value_t* pos = finch_eval("Cint[1, 3, 4, 5, 6, 6]");
    jl_value_t* idx = finch_eval("Cint[2, 5, 3, 4, 5]");
    jl_value_t* val = finch_eval("Cint[1, 1, 1, 1, 1]");

    // 1 5, 4 5, 3 4, 2 3, 1 2
    jl_value_t* edge_vector = finch_eval("Cint[0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]");
    N = 5;
    source = 5;

    // 2 1, 3 1, 3 2, 3 4
    // jl_value_t* edge_vector = finch_eval("Cint[0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0]");
    // N = 4;
    // source = 4;


    edges = finch_Fiber(
        finch_Solid(finch_Cint(N),
                finch_Solid(finch_Cint(N),
                    finch_ElementLevel(finch_Cint(0), edge_vector)
                )
            )
        );

    struct bfs_data nd = {};
    struct bfs_data* new_data = &nd;
    BFS(new_data);

    printf("Final P: \n");
    finch_exec("println(%s)\n", new_data->P);

    printf("Final F: \n");
    finch_exec("println(%s)\n", new_data->F);

    finch_finalize();
}