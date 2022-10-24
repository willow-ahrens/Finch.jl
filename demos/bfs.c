
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

jl_function_t* F_init_code;
jl_function_t* P_init_code;
jl_function_t* V_code;
jl_function_t* update_code1;
jl_function_t* update_code2;


void compile() {
    jl_value_t*  F_init_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        source = Finch.virtualize(:source, Int64, ctx_2)\n\
        t = typeof(@fiber sl(e(0)))\n\
        F = Finch.virtualize(:F, t, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j F[j] = (j == $source)\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function F_init(F, source)\n\
                $code\n\
            end\n\
    end");
    F_init_code = finch_exec("eval(last(%s.args))", F_init_expr);

    jl_value_t*  P_init_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        source = Finch.virtualize(:source, Int64, ctx_2)\n\
        t = typeof(@fiber d(e(0)))\n\
        P = Finch.virtualize(:P, t, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j P[j] = (j == $source) * (0 - 2) + (j != $source) * (0 - 1)\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function P_init(P, source)\n\
                $code\n\
            end\n\
    end");
    P_init_code = finch_exec("eval(last(%s.args))", P_init_expr);

    jl_value_t*  V_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        t1 = typeof(@fiber d(e(0)))\n\
        P = Finch.virtualize(:P, t1, ctx_2)\n\
        t2 = typeof(@fiber sl(e(0)))\n\
        V = Finch.virtualize(:V, t2, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j V[j] = (P[j] == (0 - 1))\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function V_update(V, P)\n\
                $code\n\
            end\n\
    end");
    V_code = finch_exec("eval(last(%s.args))", V_expr);

// @finch @loop i @multi begin
//   B[i] = w[]
//   C[i] = w[] * 2
// end @where w[] = A[i]
    jl_value_t*  update_expr1 = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        t1 = typeof(@fiber d(e(0)))\n\
        B = Finch.virtualize(:B, t1, ctx_2)\n\
        t2 = typeof(@fiber sl(e(0)))\n\
        V_out = Finch.virtualize(:V_out, t2, ctx_2)\n\
        t3 = typeof(@fiber sl(e(0)))\n\
        F_in = Finch.virtualize(:F_in, t3, ctx_2)\n\
        F_out = Finch.virtualize(:F_out, t3, ctx_2)\n\
        t4 = typeof(@fiber d(sl(e(0))))\n\
        edges = Finch.virtualize(:edges, t4, ctx_2)\n\
        w = Finch.virtualize(:w, typeof(Scalar{0, Int64}()), ctx_2, :w)\n\
        \n\
        kernel = @finch_program (@loop j @loop k (begin\n\
            F_out[j] <<$or>>= w[]\n\
            B[j] <<$choose>>= w[] * k\n\
        end\n\
            where (w[] = edges[j, k] * F_in[k] * V_out[j]) ) )\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function P_update1(F_out, B, edges, F_in, V_out)\n\
                w = Scalar{0}()\n\
                $code\n\
            end\n\
    end");
    update_code1 = finch_exec("eval(last(%s.args))", update_expr1);

    jl_value_t*  update_expr2 = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        t1 = typeof(@fiber d(e(0)))\n\
        P_in = Finch.virtualize(:P_in, t1, ctx_2)\n\
        P_out = Finch.virtualize(:P_out, t1, ctx_2)\n\
        B = Finch.virtualize(:B, t1, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j P_out[j] = $choose(B[j], P_in[j])\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function P_update2(P_out, B, P_in)\n\
                $code\n\
            end\n\
    end");
    update_code2 = finch_exec("eval(last(%s.args))", update_expr2);
}


struct bfs_data {
    jl_value_t* F;

    jl_value_t* P;
};

// Let Init() -> (F int[N], P int[N])
//     F[j] = (j == source)
//     P[j] = (j == source) * (0 - 2) + (j != source) * (0 - 1)
// End
void Init(struct bfs_data* data) {
    jl_value_t *val = finch_eval("Int64[]");
    jl_value_t* F = finch_Fiber(
        finch_SparseList(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), val))
    );

    finch_call(F_init_code, F, finch_Int64(source));
    data->F = F;

    // printf("F init:\n");
    // finch_exec("println(%s.lvl.lvl.val)\n", F);

    jl_value_t* P = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );

    finch_call(P_init_code,P, finch_Int64(source));
    data->P = P;

    // printf("P init:\n");
    // finch_exec("println(%s.lvl.lvl.val)\n", P);
}

void V_update(struct bfs_data* in_data, jl_value_t* V_out) {
    finch_call(V_code, V_out, in_data->P);

    // printf("V_out:\n");
    // finch_exec("println(%s)\n", V_out);
}

void F_P_update(struct bfs_data* in_data, struct bfs_data* out_data, jl_value_t* V_out)  {
    jl_value_t* B = finch_exec("B = Finch.Fiber(\n\
        Dense(%s,\n\
            Element{0, Int64}()\n\
        )\n\
    )", finch_Int64(N));
    finch_call(update_code1, out_data->F, B, edges, in_data->F, V_out);
    // printf("B: \n");
    // finch_exec("println(%s.lvl.lvl.val)\n", B);
    // printf("F_out: \n");
    // finch_exec("println(%s.lvl.lvl.val)\n", out_data->F);

    finch_call(update_code2, out_data->P, B, in_data->P);
    // printf("P_out: \n");
    // finch_exec("println(%s.lvl.lvl.val)\n", out_data->P);
}

//Let BFS_Step(F_in int[N], P_in int[N], V_in int[N]) -> (F_out int[N], P_out int[N], V_out int[N])
//  V_out[j] = P_in[j] == 0 - 1
//  F_out[j] = edges[j][k] * F_in[k] * V_out[j] | k: (OR, 0)   / k:(CHOOSE, 0)
//  P_out[j] = edges[j][k] * F_in[k] * V_out[j] * (k + 1) | k:(CHOOSE, P_in[j])
//End
void BFS_Step(struct bfs_data* in_data, struct bfs_data* out_data) {
    jl_value_t* V_out = finch_Fiber(
        finch_SparseList(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );
    V_update(in_data, V_out);
    F_P_update(in_data, out_data, V_out);
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

    jl_value_t *val = finch_eval("Int64[]");
    jl_value_t* F = finch_Fiber(
        finch_SparseList(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), val))
    );
    jl_value_t* P = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );

    struct bfs_data new_val = {};
    struct bfs_data* new_data = &new_val;
    new_data->F = F;
    new_data->P = P;

    struct bfs_data temp_val = {};
    struct bfs_data* temp = &temp_val;

    while(!outer_loop_condition(data->F)) {
        BFS_Step(data, new_data);
        temp = data;
        data = new_data;
        new_data = temp;
    }
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
    source = 1;

    make_weights_and_edges("starter.mtx", N);

    struct bfs_data d = {};
    struct bfs_data* data = &d;
    BFS(data);

    printf("EXAMPLE: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->P);
}

void setup1() {
    // 1 5, 4 5, 3 4, 2 3, 1 2
    // jl_value_t* edge_vector = finch_eval("Int64[0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]");
    N = 5;
    source = 5;
    
    make_weights_and_edges("dag5.mtx", N);

    struct bfs_data d = {};
    struct bfs_data* data = &d;
    BFS(data);

    printf("EXAMPLE1: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->P);
}

void setup2() {
    // 2 1, 3 1, 3 2, 3 4
    N = 4;
    source = 1;
     
    make_weights_and_edges("dag4.mtx", N);

    struct bfs_data d = {};
    struct bfs_data* data = &d;
    BFS(data);

    printf("EXAMPLE2\nFinal: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->P);
}

void setup3() {
    // 2 1, 3 1, 1 2, 3 2, 1 3
    // jl_value_t* edge_vector = finch_eval("Int64[0, 1, 1, 1, 0, 0, 1, 1, 0]");
    N = 3;
    source = 1;
     
    make_weights_and_edges("dag3.mtx", N);

    struct bfs_data d = {};
    struct bfs_data* data = &d;
    BFS(data);

    printf("EXAMPLE3: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->P);
}

void setup4() {
    // 2 3, 3 1, 4 3, 5 4, 6 5, 6 7, 7 5, 7 6
    // jl_value_t* edge_vector = finch_eval("Int64[0,0,0,0,0,0,0, 0,0,1,0,0,0,0, 1,0,0,0,0,0,0, 0,0,1,0,0,0,0, 0,0,0,1,0,0,0, 0,0,0,0,1,0,1, 0,0,0,0,1,1,0]");
    N = 7;
    source = 1;
     
    make_weights_and_edges("dag7.mtx", N);

    struct bfs_data d = {};
    struct bfs_data* data = &d;
    BFS(data);

    printf("EXAMPLE4: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->P);
}

void setup5() {
    N = 4847571;
    source = 1;
    
    make_weights_and_edges("soc-LiveJournal1.mtx", N);

    struct bfs_data d = {};
    struct bfs_data* data = &d;
    BFS(data);

    printf("LARGE GRAPH\n");
    // finch_exec("println(%s.lvl.lvl.val)", data->P);
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
    compile();
    printf("COMPILE DONE\n");

    starter();
    printf("WARMUP DONE\n");
    
    setup1();

    setup2();

    setup3();

    setup4();

    setup5();
    
    finch_finalize();
}