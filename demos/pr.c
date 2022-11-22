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

jl_function_t* funcode;

jl_function_t* out_deg_code;

jl_function_t* rinit_code;

jl_function_t* r_code;

jl_function_t* rank_code;

struct pr_data {

    jl_value_t* ranks;

    jl_value_t* r;
};


void compile() {
    jl_value_t*  out_deg_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        t1 = typeof(@fiber d(sl(e(0))))\n\
        t2 = typeof(@fiber d(e(0)))\n\
        edges = Finch.virtualize(:edges, t1, ctx_2)\n\
        deg = Finch.virtualize(:deg, t2, ctx_2)\n\
        w = Finch.virtualize(:w, typeof(Scalar{0, Int64}()), ctx_2, :w)\n\
        \n\
        kernel = @finch_program (@loop j deg[j] = w[] where (@loop i w[] += edges[i, j]))\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function out_degree(deg, edges)\n\
                w = Scalar{0}()\n\
                $code\n\
            end\n\
    end");
    out_deg_code = finch_exec("eval(last(%s.args))", out_deg_expr);
    
    jl_value_t* rinit_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        N = %s\n\
        t = typeof(@fiber d(e(0)))\n\
        r = Finch.virtualize(:r, t, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j r[j] = 1.0 / $N\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function rinit(r)\n\
                $code\n\
            end\n\
    end", finch_Int64(N));
    rinit_code = finch_exec("eval(%s)", rinit_expr);

    jl_value_t* rank_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        t1 = typeof(@fiber d(e(0)))\n\
        t2 = typeof(@fiber d(e(0)))\n\
        t3 = typeof(@fiber d(sl(e(0))))\n\
        t4 = typeof(@fiber d(e(0)))\n\
        rank = Finch.virtualize(:rank, t1, ctx_2)\n\
        out_d = Finch.virtualize(:out_d, t2, ctx_2)\n\
        edges = Finch.virtualize(:edges, t3, ctx_2)\n\
        r_in = Finch.virtualize(:r_in, t4, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j (@loop i rank[j] += ifelse(out_d[i] != 0, edges[j, i] * r_in[i] / out_d[i], 0))\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function rank_(rank, out_d, edges, r_in)\n\
                $code\n\
            end\n\
    end");
    rank_code = finch_exec("eval(%s)", rank_expr);
    
    jl_value_t* r_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        beta_score=%s\n\
        damp=%s\n\
        t1 = typeof(@fiber d(e(0)))\n\
        t2 = typeof(@fiber d(e(0)))\n\
        r_out = Finch.virtualize(:r_out, t1, ctx_2)\n\
        rank = Finch.virtualize(:rank, t2, ctx_2)\n\
        \n\
        kernel = @finch_program @loop i r_out[i] = $beta_score + $damp * rank[i]\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function rout(r_out, rank)\n\
                $code\n\
            end\n\
    end", finch_Float64(beta_score), finch_Float64(damp));
    r_code = finch_exec("eval(%s)", r_expr);
}


// Let InitRank() -> (r_out float[N])
//     out_d[j] = edges[i][j] | i:(+, 0)
//     r_out[j] = 1.0 / N
// End
void Init(struct pr_data* data) {
    out_degree = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );
    finch_call(out_deg_code, out_degree, edges);
    // printf("Out degree: \n");
    // finch_exec("println(%s.lvl.lvl.val)", out_degree);

    jl_value_t* r = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Float64(0), finch_eval("Float64[]")))
    );
    finch_call(rinit_code, r);
    // printf("r: \n");
    // finch_exec("println(%s.lvl.lvl.val)", r);

    data->r = r;
}

void Rank_Update(struct pr_data* in_data, struct pr_data* out_data) {
    finch_call(rank_code, out_data->ranks, out_degree, edges, in_data->r);
    // printf("New Rank: \n");
    // finch_exec("println(%s.lvl.lvl.val)", out_data->ranks);
}

void R_Update(struct pr_data* out_data) {
    finch_call(r_code, out_data->r, out_data->ranks);
    // printf("New R: \n");
    // finch_exec("println(%s.lvl.lvl.val)", out_data->r);
}

// Let PageRankStep(contrib_in float[N], rank_in float[N], r_in float[N]) -> (contrib float[N], rank float[N], r_out float[N])
//     rank[i] = edges[i][j] * r_in[j] / out_d[j] | j:(+, 0.0)

//     r_out[i] = beta_score + damp * (rank[i])
// End
void PageRankStep(struct pr_data* in_data, struct pr_data* out_data) {
    Rank_Update(in_data, out_data);
    R_Update(out_data);
}

// Let PageRank() -> (contrib float[N], rank float[N], r_out float[N])
//     contrib[i] = 0.0
//     rank[i] = 0.0
//     _, _, _, r_out = PageRankStep*(out_d, contrib, rank, InitRank()) | 20
// End
void PageRank(struct pr_data* data) {
    Init(data);

    jl_value_t* r_out = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Float64(0), finch_eval("Float64[]")))
    );
    jl_value_t* rank = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Float64(0), finch_eval("Float64[]")))
    );
    struct pr_data new_data = {};
    new_data.ranks = rank;
    new_data.r = r_out;


    for(int i=0; i < 20; i++) {
        PageRankStep(data, &new_data);
        // printf("iteration %d DONE\n", i);
        data->r = new_data.r;
        data->ranks = new_data.ranks;
    }
}


void make_weights_and_edges(const char* graph_name) {
    // 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0
    char code[1000];
    sprintf(code, "matrix = copy(transpose(MatrixMarket.mmread(\"./graphs/%s\")))\n\
        (n, m) = size(matrix)\n\
        @assert n == m\n\
        nzval = ones(size(matrix.nzval, 1))\n\
        Finch.Fiber(\n\
                 Dense(n,\n\
                 SparseList(N, matrix.colptr, matrix.rowval,\n\
                 Element{0}(nzval))))", graph_name);
    edges = finch_eval(code);
    printf("Loaded edges\n");
}

void starter() {
    char zereout[1000];
    sprintf(zereout, "N = %d\n\
        rowptr = ones(Int64, N + 1)\n\
        Finch.Fiber(\n\
                 Dense(N,\n\
                 SparseList(N, rowptr, Int64[],\n\
                 Element{0}(Int64[]))))", N);
    edges = finch_eval(zereout);
    compile();
    printf("Compiled kernels\n");

    struct pr_data d = {};
    struct pr_data* data = &d;
    PageRank(data);

    printf("Ran starter\n");
}

void setup1() {
    // 1 5, 4 5, 3 4, 2 3, 1 2
    // jl_value_t* edge_vector = finch_eval("Cint[0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]");
    N = 5;
    beta_score = (1.0 - damp) / N;

    // compile and cache 
    starter();

    make_weights_and_edges("dag5.mtx");

    struct pr_data d = {};
    struct pr_data* data = &d;
    PageRank(data);

    printf("EXAMPLE1\nFinal: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->r);
}

void setup2() {
   // 2 1, 3 1, 3 2, 3 4
    N = 4;
    beta_score = (1.0 - damp) / N;

    // compile and cache 
    starter();

    make_weights_and_edges("dag4.mtx");

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
    beta_score = (1.0 - damp) / N;

    // compile and cache 
    starter();

    make_weights_and_edges("dag3.mtx");
    
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
    beta_score = (1.0 - damp) / N;

    // compile and cache 
    starter();

    make_weights_and_edges("dag7.mtx");

    struct pr_data d = {};
    struct pr_data* data = &d;
    PageRank(data);

    printf("EXAMPLE4\n Final: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->r);
}

void setup5() {
    N = 4847571;
    beta_score = (1.0 - damp) / N;

    // compile and cache 
    starter();

    make_weights_and_edges("soc-LiveJournal1.mtx");

    time_t start;
    time_t end;

    start = time(NULL);

    struct pr_data d = {};
    struct pr_data* data = &d;
    PageRank(data);

    end = time(NULL);

    printf("LARGE GRAPH completed in: %lu\n", end - start);
    // finch_exec("println(%s.lvl.lvl.val)", data->r);
}

int main(int argc, char** argv) {

    finch_initialize();

    jl_value_t* res = finch_eval("using RewriteTools\n\
    using Finch.IndexNotation\n\
    using SparseArrays\n\
    using MatrixMarket\n\
    ");

    damp = 0.85;

    setup1();

    setup2();

    setup3();

    setup4();

    // setup5();

    finch_finalize();
}