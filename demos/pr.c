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
jl_function_t* out_deg_ex;

jl_function_t* rinit_code;
jl_function_t* rinit_ex;

jl_function_t* r_code;
jl_function_t* r_ex;

jl_function_t* rank_code;
jl_function_t* rank_ex;

struct pr_data {

    jl_value_t* ranks;

    jl_value_t* r;
};

// jl_value_t* call_finch(jl_function_t* b, va_list args)
// {
//     printf("in Call helper, func to call: %p\n", b);
//     return finch_call(b, args);
// }

#define call_finch(f, ...) finch_call(f, ##__VA_ARGS__)

#define run_finch(codegen, exgen, funcode, ...) {\
    jl_value_t* code = finch_call(codegen, ##__VA_ARGS__); \
    jl_value_t* ex = finch_call(exgen, ##__VA_ARGS__); \
    finch_call(funcode, code, ex);\
}

// jl_value_t* run_finch(jl_function_t* codegen, jl_function_t* exgen, jl_function_t* funcode, ...) {
//     va_list args;
//     va_start(args, funcode);
//     printf("Getting codegen\n");
//     jl_value_t* code = call_finch(codegen, args);
//     va_end(args);

//     va_list args_;
//     va_start(args_, funcode);
//     printf("Getting ex\n");
//     jl_value_t* ex = call_finch(exgen, args_);
//     va_end(args_);
    
//     return finch_call(funcode, code, ex);
// }

// Let InitRank() -> (r_out float[N])
//     out_d[j] = edges[i][j] | i:(+, 0)
//     r_out[j] = 1.0 / N
// End
void Init(struct pr_data* data) {
    out_degree = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    run_finch(out_deg_code, out_deg_ex, funcode, out_degree, edges);
    printf("Out degree: \n");
    // finch_exec("println(%s.lvl.lvl.val)", out_degree);

    jl_value_t* r = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Float64(0), finch_eval("Float64[]")))
    );
    run_finch(rinit_code, rinit_ex, funcode, r, finch_Cint(N));
    printf("r: \n");
    // finch_exec("println(%s.lvl.lvl.val)", r);

    data->r = r;
}

void Rank_Update(struct pr_data* in_data, struct pr_data* out_data) {
    jl_value_t* rank = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Float64(0), finch_eval("Float64[]")))
    );
    run_finch(rank_code, rank_ex, funcode,  rank, edges, in_data->r, out_degree);
    printf("New Rank: \n");
    // finch_exec("println(%s.lvl.lvl.val)", rank);

    out_data->ranks = rank;
    
    
//     jl_function_t* display = finch_eval("function display_lowered(rank, edges, r_in, out_d)\n\
//     ex = @index_program_instance (@loop i j rank[i] += edges[i, j] * r_in[j] / out_d[j])\n\
//     display(execute_code_lowered(:ex, typeof(ex)))\n\
//     println()\n\
// end");
//     finch_call(display, rank, edges, in_data->r, out_degree);
}

void R_Update(struct pr_data* out_data) {
    jl_value_t* r_out = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Float64(0), finch_eval("Float64[]")))
    );
    run_finch(r_code, r_ex, funcode, r_out, finch_Float64(beta_score), finch_Float64(damp), out_data->ranks);
    printf("New R: \n");
    // finch_exec("println(%s.lvl.lvl.val)", r_out);

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
        printf("iteration %d DONE\n", i);
        finch_free(data->r);
        finch_free(data->ranks);
        data->r = new_data.r;
        data->ranks = new_data.ranks;
    }
}


void compile_finch() {
    funcode = finch_eval("function call(code, ex_)\n\
        fun = eval(Expr(:->,:ex, code))\n\
        Base.invokelatest(fun, ex_)\n\
    end");

    out_deg_code = finch_eval("println(\"HELLO\")\n\
    function outdeg_codegen(out_d, edges)\n\
            code = @finch_code @loop i j out_d[j] += edges[i, j]\n\
            return code\n\
    end");
    out_deg_ex = finch_eval("function outdeg_ex(out_d, edges)\n\
            ex = @finch_program_instance @loop i j out_d[j] += edges[i, j]\n\
            return ex\n\
    end");
    
    rinit_code = finch_eval("function rinit_codegen(r, N)\n\
        code = @finch_code @loop j r[j] = 1.0 / $N\n\
        return code\n\
    end");  
    rinit_ex = finch_eval("function rinit_ex(r, N)\n\
        ex = @finch_program_instance @loop j r[j] = 1.0 / $N\n\
        return ex\n\
    end");

    rank_code = finch_eval("function rank_codegen(rank, edges, r_in, out_d)\n\
        code = @finch_code @loop j i rank[j] += ifelse(out_d[i] != 0, edges[j, i] * r_in[i] / out_d[i], 0)\n\
        return code\n\
    end");
    rank_ex = finch_eval("function rank_ex(rank, edges, r_in, out_d)\n\
        ex = @finch_program_instance @loop j i rank[j] += ifelse(out_d[i] != 0, edges[j, i] * r_in[i] / out_d[i], 0)\n\
        return ex\n\
    end");

    r_code = finch_eval("function r_codegen(r_out, beta_score, damp, rank)\n\
        code = @finch_code @loop i r_out[i] = $beta_score + $damp * rank[i]\n\
        return code\n\
    end");
    r_ex = finch_eval("function r_ex(r_out, beta_score, damp, rank)\n\
        ex = @finch_program_instance @loop i r_out[i] = $beta_score + $damp * rank[i]\n\
        return ex\n\
    end");
}


void make_weights_and_edges(const char* graph_name, int n) {
    // 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0
    char code[1000];
    sprintf(code, "N = %d\n\
        matrix = copy(transpose(MatrixMarket.mmread(\"./graphs/%s\")))\n\
        nzval = ones(size(matrix.nzval, 1))\n\
        Finch.Fiber(\n\
                 Dense(N,\n\
                 SparseList(N, matrix.colptr, matrix.rowval,\n\
                 Element{0}(nzval))))", n, graph_name);
    edges = finch_eval(code);
    printf("Loaded edges\n");
}

void starter() {
    N = 1;

    make_weights_and_edges("starter.mtx", N);

    struct pr_data d = {};
    struct pr_data* data = &d;
    PageRank(data);

    printf("EXAMPLE\nFinal: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->r);
}

void setup1() {
    // 1 5, 4 5, 3 4, 2 3, 1 2
    // jl_value_t* edge_vector = finch_eval("Cint[0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]");
    N = 5;

    make_weights_and_edges("dag5.mtx", N);

    struct pr_data d = {};
    struct pr_data* data = &d;
    PageRank(data);

    printf("EXAMPLE1\nFinal: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->r);
}

void setup2() {
    // 2 1, 3 1, 3 2, 3 4
    N = 4;

    make_weights_and_edges("dag4.mtx", N);

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
    
    make_weights_and_edges("dag3.mtx", N);

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
    
    make_weights_and_edges("dag7.mtx", N);

    struct pr_data d = {};
    struct pr_data* data = &d;
    PageRank(data);

    printf("EXAMPLE4\n Final: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->r);
}

void setup5() {
    N = 4847571;
    
    make_weights_and_edges("soc-LiveJournal1.mtx", N);

    struct pr_data d = {};
    struct pr_data* data = &d;
    PageRank(data);

    printf("LARGE GRAPH\n Final: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->r);
}

int main(int argc, char** argv) {

    finch_initialize();

    jl_value_t* res = finch_eval("using RewriteTools\n\
    using Finch.IndexNotation\n\
    using SparseArrays\n\
     using MatrixMarket\n\
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

    N = 1;

    // compile all the necessary functions first
    compile_finch();
    printf("Compiled finch\n");

    starter();
    printf("Ran starter\n");

    setup1();

    // setup2();

    // setup3();

    // setup4();

    // setup5();

    finch_finalize();
}