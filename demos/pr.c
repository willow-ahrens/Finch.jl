// N int

// edges int[N][N]

// damp float

// beta_score float

#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

JULIA_DEFINE_FAST_TLS // only define this once, in an executable

int N = 5;
double damp;
double beta_score;
jl_value_t* edges = 0;
jl_value_t* out_degree = 0;

struct pr_data {
    jl_value_t* contrib;

    jl_value_t* ranks;

    jl_value_t* r;
};

// Let InitRank() -> (r_out float[N])
//     out_d[j] = edges[i][j] | i:(+, 0)
//     r_out[j] = 1.0 / N
// End
void Init(struct pr_data* data) {
    jl_function_t* out_d_init = finch_eval("function out_d_init(out_d, edges)\n\
    @index @loop i j out_d[j] += edges[i, j]\n\
end");

    out_degree = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(out_d_init, out_degree, edges);
    printf("Out degree: \n");
    finch_exec("println(%s)", out_degree);

    jl_value_t* r = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Float64(0), finch_eval("Float64[]")))
    );
    finch_exec("println(%s)", r);
    
    jl_function_t* r_init = finch_eval("function r_init(r, N)\n\
    @index @loop j r[j] = 1.0 / $N\n\
end");
    printf("function pointer: %p\n", r_init);
    finch_call(r_init, r, finch_Cint(N));

    printf("r: \n");
    finch_exec("println(%s)", r);

    data->r = r;
}

void Contrib_Update(struct pr_data* in_data, struct pr_data* out_data) {
    jl_function_t* contrib_func = finch_eval("function c_init(contrib, r_in, out_d)\n\
    @index @loop i contrib[i] = r_in[i] / out_d[i]\n\
end");
    jl_value_t* contrib = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Float64(0), finch_eval("Float64[]")))
    );
    finch_call(contrib_func, contrib, in_data->r, out_degree);
    printf("Contrib: \n");
    finch_exec("println(%s)", contrib);

    out_data->contrib = contrib;
}

void Rank_Update(struct pr_data* in_data, struct pr_data* out_data) {
    jl_function_t* rank_func = finch_eval("function rank_func(rank, edges, r_in, out_d)\n\
    @index @loop i j rank[i] += edges[i, j] * r_in[j] / out_d[j]\n\
end");
    jl_value_t* rank = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Float64(0), finch_eval("Float64[]")))
    );
    finch_call(rank_func, rank, edges, in_data->r, out_degree);
    printf("Rank: \n");
    finch_exec("println(%s)", rank);

    out_data->ranks = rank;
    
    
//     jl_function_t* display = finch_eval("function display_lowered(rank, edges, r_in, out_d)\n\
//     ex = @index_program_instance (@loop i j rank[i] += edges[i, j] * r_in[j] / out_d[j])\n\
//     display(execute_code_lowered(:ex, typeof(ex)))\n\
//     println()\n\
// end");
//     finch_call(display, rank, edges, in_data->r, out_degree);
}

void R_Update(struct pr_data* out_data) {
    jl_function_t* r_func = finch_eval("function r_func(r_out, beta_score, damp, rank)\n\
    @index @loop i r_out[i] = $beta_score + $damp * rank[i]\n\
end");
    jl_value_t* r_out = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Float64(0), finch_eval("Float64[]")))
    );
    finch_call(r_func, r_out, finch_Float64(beta_score), finch_Float64(damp), out_data->ranks);

    printf("R: \n");
    finch_exec("println(%s)", r_out);

    out_data->r = r_out;
}

// Let PageRankStep(contrib_in float[N], rank_in float[N], r_in float[N]) -> (contrib float[N], rank float[N], r_out float[N])
//     rank[i] = edges[i][j] * r_in[j] / out_d[j] | j:(+, 0.0)

//     r_out[i] = beta_score + damp * (rank[i])
// End
void PageRankStep(struct pr_data* in_data, struct pr_data* out_data) {
    Rank_Update(in_data, out_data);
    R_Update(out_data);
}

int outer_loop_condition(jl_value_t* F) {

}

// Let PageRank() -> (contrib float[N], rank float[N], r_out float[N])
//     contrib[i] = 0.0
//     rank[i] = 0.0
//     _, _, _, r_out = PageRankStep*(out_d, contrib, rank, InitRank()) | 20
// End
void PageRank(struct pr_data* data) {
    Init(data);

    struct pr_data new_data = {};

    for(int i=0; i < 20; i++) {
        PageRankStep(data, &new_data);
        *data = new_data;
    }
}

int main(int argc, char** argv) {

    finch_initialize();

    jl_value_t* res = finch_eval("using RewriteTools\n\
    using Finch.IndexNotation\n\
    using Finch: execute_code_lowered");

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

    // 1 5, 4 5, 3 4, 2 3, 1 2
    // jl_value_t* edge_vector = finch_eval("Cint[0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]");
    // N = 5;
    // source = 5;

    // 2 1, 3 1, 3 2, 1 3, 3 4
    jl_value_t* edge_vector = finch_eval("Cint[0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0]");
    N = 4;

    // 2 1, 3 1, 1 2, 3 2, 1 3
    // jl_value_t* edge_vector = finch_eval("Cint[0, 1, 1, 1, 0, 0, 1, 1, 0]");
    // N = 3;

    damp = 0.85;
    beta_score = (1.0 - damp) / N;


    edges = finch_Fiber(
        finch_Solid(finch_Cint(N),
                finch_Solid(finch_Cint(N),
                    finch_ElementLevel(finch_Cint(0), edge_vector)
                )
            )
        );

    struct pr_data d = {};
    struct pr_data* data = &d;
    PageRank(data);

    finch_finalize();
}