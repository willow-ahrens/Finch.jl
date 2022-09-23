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
    @finch @loop i j out_d[j] += edges[i, j]\n\
end");

    out_degree = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(out_d_init, out_degree, edges);
    printf("Out degree: \n");
    finch_exec("println(%s.lvl.lvl.val)", out_degree);

    jl_value_t* r = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Float64(0), finch_eval("Float64[]")))
    );
    
    jl_function_t* r_init = finch_eval("function r_init(r, N)\n\
    @finch @loop j r[j] = 1.0 / $N\n\
end");
    printf("function pointer: %p\n", r_init);
    finch_call(r_init, r, finch_Cint(N));

    printf("r: \n");
    finch_exec("println(%s.lvl.lvl.val)", r);

    data->r = r;
}

void Contrib_Update(struct pr_data* in_data, struct pr_data* out_data) {
    jl_function_t* contrib_func = finch_eval("function c_init(contrib, r_in, out_d)\n\
    @finch @loop i contrib[i] = r_in[i] / out_d[i]\n\
end");
    jl_value_t* contrib = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Float64(0), finch_eval("Float64[]")))
    );
    finch_call(contrib_func, contrib, in_data->r, out_degree);
    printf("Contrib: \n");
    finch_exec("println(%s.lvl.lvl.val)", contrib);

    out_data->contrib = contrib;
}

void Rank_Update(struct pr_data* in_data, struct pr_data* out_data) {
    jl_function_t* rank_func = finch_eval("function rank_func(rank, edges, r_in, out_d)\n\
    @finch @loop i j rank[i] += ifelse(out_d[j] != 0, edges[i, j] * r_in[j] / out_d[j], 0)\n\
end");
    jl_value_t* rank = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Float64(0), finch_eval("Float64[]")))
    );
    finch_call(rank_func, rank, edges, in_data->r, out_degree);
    printf("Rank: \n");
    finch_exec("println(%s.lvl.lvl.val)", rank);

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
    @finch @loop i r_out[i] = $beta_score + $damp * rank[i]\n\
end");
    jl_value_t* r_out = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Float64(0), finch_eval("Float64[]")))
    );
    finch_call(r_func, r_out, finch_Float64(beta_score), finch_Float64(damp), out_data->ranks);

    printf("R: \n");
    finch_exec("println(%s.lvl.lvl.val)", r_out);

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

void setup1() {
    // 1 5, 4 5, 3 4, 2 3, 1 2
    // jl_value_t* edge_vector = finch_eval("Cint[0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]");
    N = 5;
    edges = finch_eval("N = 5\n\
        edge_matrix = sparse([0 0 0 0 0; 1 0 0 0 0; 0 1 0 0 0; 0 0 1 0 0; 1 0 0 1 0])\n\
        Finch.Fiber(\n\
                 Dense(N,\n\
                 SparseList(N, edge_matrix.colptr, edge_matrix.rowval,\n\
                 Element{0.0}(edge_matrix.nzval))))");
    struct pr_data d = {};
    struct pr_data* data = &d;
    PageRank(data);

    printf("EXAMPLE1\nFinal: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->r);
}

void setup2() {
    // 2 1, 3 1, 3 2, 3 4
    N = 4;
    edges = finch_eval("N = 4\n\
        edge_matrix = sparse([0 1 1 0; 0 0 1 0; 0 0 0 0; 0 0 1 0])\n\
        Finch.Fiber(\n\
                 Dense(N,\n\
                 SparseList(N, edge_matrix.colptr, edge_matrix.rowval,\n\
                 Element{0.0}(edge_matrix.nzval))))");
    struct pr_data d = {};
    struct pr_data* data = &d;
    PageRank(data);

    printf("EXAMPLE2\nFinal: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->r);
}

void setup3() {
    // 2 1, 3 1, 1 2, 3 2, 1 3
    // jl_value_t* edge_vector = finch_eval("Cint[0, 1, 1, 1, 0, 0, 1, 1, 0]");
    N = 3;
    edges = finch_eval("N = 3\n\
        edge_matrix = sparse([0 1 1; 1 0 1; 1 0 0])\n\
        Finch.Fiber(\n\
                 Dense(N,\n\
                 SparseList(N, edge_matrix.colptr, edge_matrix.rowval,\n\
                 Element{0.0}(edge_matrix.nzval))))");
    struct pr_data d = {};
    struct pr_data* data = &d;
    PageRank(data);

    printf("EXAMPLE3\nFinal: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->r);
}

void setup4() {
    // 3 2, 3 1, 4 3, 5 4, 6 5, 6 7, 7 5, 7 6
    // jl_value_t* edge_vector = finch_eval("Cint[0,0,0,0,0,0,0, 0,0,1,0,0,0,0, 1,0,0,0,0,0,0, 0,0,1,0,0,0,0, 0,0,0,1,0,0,0, 0,0,0,0,1,0,1, 0,0,0,0,1,1,0]");
    N = 7;
    edges = finch_eval("N = 7\n\
    edge_matrix = sparse([0 0 1 0 0 0 0; 0 0 0 0 0 0 0; 0 1 0 1 0 0 0; 0 0 0 0 1 0 0; 0 0 0 0 0 1 1; 0 0 0 0 0 0 1; 0 0 0 0 0 1 0])\n\
    Finch.Fiber(\n\
                Dense(N,\n\
                SparseList(N, edge_matrix.colptr, edge_matrix.rowval,\n\
                Element{0.0}(edge_matrix.nzval))))");
    struct pr_data d = {};
    struct pr_data* data = &d;
    PageRank(data);

    printf("EXAMPLE4\n Final: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->r);
}

int main(int argc, char** argv) {

    finch_initialize();

    jl_value_t* res = finch_eval("using RewriteTools\n\
    using Finch.IndexNotation\n\
    using SparseArrays\n\
    ");

    res = finch_eval("or(x,y) = x == 1|| y == 1\n\
function choose(x, y)\n\
    if x != 0\n\
        return x\n\
    else\n\
        return y\n\
    end\n\
end");

    res = finch_eval("@slots a b c d e i j Finch.add_rules!([\n\
    (@rule @f(@chunk $i a (b[j...] <<min>>= $d)) => if Finch.isliteral(d) && i ∉ j\n\
        @f (b[j...] <<min>>= $d)\n\
    end),\n\
    (@rule @f(@chunk $i a @multi b... (c[j...] <<min>>= $d) e...) => begin\n\
        if Finch.isliteral(d) && i ∉ j\n\
            @f @multi (c[j...] <<min>>= $d) @chunk $i a @f(@multi b... e...)\n\
        end\n\
    end),\n\
    \n\
    (@rule @f($or(false, $a)) => a),\n\
    (@rule @f($or($a, false)) => a),\n\
    (@rule @f($or($a, true)) => true),\n\
    (@rule @f($or(true, $a)) => true),\n\
    \n\
    (@rule @f(@chunk $i a (b[j...] <<$choose>>= $d)) => if Finch.isliteral(d) && i ∉ j\n\
        @f (b[j...] <<$choose>>= $d)\n\
    end),\n\
    (@rule @f(@chunk $i a @multi b... (c[j...] <<choose>>= $d) e...) => begin\n\
        if Finch.isliteral(d) && i ∉ j\n\
            @f @multi (c[j...] <<choose>>= $d) @chunk $i a @f(@multi b... e...)\n\
        end\n\
    end),\n\
    (@rule @f($choose(0, $a)) => a),\n\
    (@rule @f($choose($a, 0)) => a),\n\
    (@rule @f(@chunk $i a (b[j...] <<$or>>= $d)) => if Finch.isliteral(d) && i ∉ j\n\
        @f (b[j...] <<$or>>= $d)\n\
    end),\n\
    (@rule @f(@chunk $i a @multi b... (c[j...] <<$or>>= $d) e...) => begin\n\
        if Finch.isliteral(d) && i ∉ j\n\
            @f @multi (c[j...] <<$or>>= $d) @chunk $i a @f(@multi b... e...)\n\
        end\n\
    end),\n\
])\n\
\n\
Finch.register()");

    damp = 0.85;
    beta_score = (1.0 - damp) / N;

    setup1();

    setup2();

    setup3();

    setup4();

    finch_finalize();
}