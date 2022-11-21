#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
 

//  priorityQ[j][k] += (dist[k] > new_dist[k]) * (new_dist[k] == j) - (dist[k] > new_dist[k]) * (dist[k] == j)

 // new_priorityQ[j][k] = (dist[k] > new_dist[k]) * (new_dist[k] == j) + (dist[k] == new_dist[k] && j != priority) * priorityQ[j][k]
//  \forall k j priorityQ[j][k] += (dist[k] > new_dist[k]) * (new_dist[k] == j) - (dist[k] > new_dist[k]) * (dist[k] == j)
//  \forall k j priorityQ[j][k] += (mask[k] * (new_dist[k] == j) - mask[k]* (dist[k] == j))


JULIA_DEFINE_FAST_TLS // only define this once, in an executable

int P = 5;
int N = 5;
int source = 5;
jl_value_t* weights = 0;

jl_function_t* pq_init_code;
jl_function_t* dist_init_code;
jl_function_t* pq_update_code;
jl_function_t* dist_update_code1;
jl_function_t* dist_update_code2;
jl_function_t* slicing_code;

void compile() {
    jl_value_t*  pq_init_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        P = %s\n\
        source = %s\n\
        t = typeof(@fiber sl(sl(e(0))))\n\
        priorityQ = Finch.virtualize(:priorityQ, t, ctx_2)\n\
        \n\
        kernel = @finch_program @loop p (@loop j priorityQ[p, j] = (p == 1 && j == $source) + (p == $P && j != $source))\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function pq_init(priorityQ)\n\
                $code\n\
            end\n\
    end", finch_Int64(P), finch_Int64(source));
    pq_init_code = finch_exec("eval(last(%s.args))", pq_init_expr);

    jl_value_t*  dist_init_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        val = typemax(Int64)\n\
        P = %s\n\
        source = %s\n\
        t = typeof(@fiber d(e($val)))\n\
        dist = Finch.virtualize(:dist, t, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j dist[j] = ifelse(j == $source, 0, $val)\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function dist_init(dist)\n\
                $code\n\
            end\n\
    end", finch_Int64(P), finch_Int64(source));
    dist_init_code = finch_exec("eval(last(%s.args))", dist_init_expr);

    jl_value_t*  dist_update_expr1 = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        P = %s\n\
        N = %s\n\
        val = typemax(Int64)\n\
        t1 = typeof(@fiber d(N, sl(N, e(0))))\n\
        t2 = typeof(@fiber sl(P, sl(N, e(0))))\n\
        t4 = typeof(@fiber d(N, e($val)))\n\
        priority = Finch.virtualize(:priority, Int64, ctx_2)\n\
        weights = Finch.virtualize(:weights, t1, ctx_2)\n\
        priorityQ = Finch.virtualize(:priorityQ, t2, ctx_2)\n\
        dist = Finch.virtualize(:dist, t4, ctx_2)\n\
        B = Finch.virtualize(:B, t4, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j (@loop k B[j] <<min>>= ifelse(weights[j, k] * priorityQ[$priority, k] != 0, weights[j, k] + dist[k], $val))\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function dist_update1(B, dist, weights, priorityQ, priority)\n\
                    $code\n\
            end\n\
    end", finch_Int64(P), finch_Int64(N));
    // finch_exec("println(last(%s.args))", dist_update_expr1);
    dist_update_code1 = finch_exec("eval(last(%s.args))", dist_update_expr1);

    jl_value_t*  dist_update_expr2 = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        val = typemax(Int64)\n\
        t = typeof(@fiber d(e($val)))\n\
        dist = Finch.virtualize(:dist, t, ctx_2)\n\
        new_dist = Finch.virtualize(:new_dist, t, ctx_2)\n\
        B = Finch.virtualize(:B, t, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j new_dist[j] = min(B[j], dist[j])\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function dist_update2(new_dist, B, dist)\n\
                    $code\n\
            end\n\
    end");
    // finch_exec("println(last(%s.args))", dist_update_expr2);
    dist_update_code2 = finch_exec("eval(last(%s.args))", dist_update_expr2);

    jl_value_t*  pq_update_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        val = typemax(Int64)\n\
        t1 = typeof(@fiber sl(sl(e(0))))\n\
        t3 = typeof(@fiber d(e($val)))\n\
        priority = Finch.virtualize(:priority, Int64, ctx_2)\n\
        priorityQ = Finch.virtualize(:priorityQ, t1, ctx_2)\n\
        new_priorityQ = Finch.virtualize(:new_priorityQ, t1, ctx_2)\n\
        dist = Finch.virtualize(:dist, t3, ctx_2)\n\
        new_dist = Finch.virtualize(:new_dist, t3, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j (@loop k new_priorityQ[j, k] = (dist[k] > new_dist[k]) * (new_dist[k] == j-1) + (dist[k] == new_dist[k] && j != $priority) * priorityQ[j, k])\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function pq_update(new_priorityQ, dist, new_dist, priorityQ, priority)\n\
                $code\n\
            end\n\
    end");
    // finch_exec("println(%s)", pq_update_expr);
    pq_update_code = finch_exec("eval(last(%s.args))", pq_update_expr);

    jl_value_t*  slicing_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        t1 = typeof(@fiber sl(e(0)))\n\
        t2 = typeof(@fiber sl(sl(e(0))))\n\
        tensor1D = Finch.virtualize(:tensor1D, t1, ctx_2)\n\
        tensor2D = Finch.virtualize(:tensor2D, t2, ctx_2)\n\
        index = Finch.virtualize(:index, Int64, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j tensor1D[j] = tensor2D[$index, j]\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function slice(tensor1D, tensor2D, index)\n\
                $code\n\
            end\n\
    end");
    // finch_exec("println(%s)", slicing_expr);
    slicing_code = finch_exec("eval(last(%s.args))", slicing_expr);
}


struct sssp_data {
    jl_value_t* priorityQ;

    jl_value_t* dist;
};

//     priorityQ[p][j] = (p == 0 && j == source) + (p == (P - 1) && j != source)
void Init_priorityQ(struct sssp_data* data) {
    jl_value_t* priorityQ = finch_Fiber(
        finch_SparseList(finch_Int64(P),
            finch_SparseList(finch_Int64(N),
                finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]"))
            )
        )
    );
    data->priorityQ = priorityQ;
    finch_call(pq_init_code, data->priorityQ);

    printf("PQ init: \n");
    finch_exec("println(%s.lvl.idx)", priorityQ);
    finch_exec("println(%s.lvl.pos)", priorityQ);
    finch_exec("println(%s.lvl.lvl.idx)", priorityQ);
    finch_exec("println(%s.lvl.lvl.pos)", priorityQ);
    finch_exec("println(%s.lvl.lvl.lvl.val)", priorityQ);
}

//     dist[j] = (j != source) * P
void Init_dist(struct sssp_data* data) {
    jl_value_t* dist = finch_exec("Finch.Fiber(\n\
        Dense(%s,\n\
            Element{typemax(Int64), Int64}()\n\
        )\n\
    )", finch_Int64(N));
    data->dist = dist;
    finch_call(dist_init_code, data->dist);
    
    // printf("Dist init: \n");
    // finch_exec("println(%s.lvl.lvl.val)", dist);
}

// Let Init(source int) -> (dist float[N], priorityQ int[P][N])
//     dist[j] = (j != source) * P
//     priorityQ[p][j] = (p == 0 && j == source) + (p == (P - 1) && j != source)
// End
void Init(struct sssp_data* data) {
    Init_priorityQ(data);
    Init_dist(data);
}

// Let UpdateEdges(dist float[N], priorityQ int[P][N], priority int) -> (new_dist float[N], new_priorityQ int[P][N], new_priority int)
//     new_dist[j] = edges[j][k] * priorityQ[priority][k] * (weights[j][k] + dist[k]) + (edges[j][k] * priorityQ[priority][k] == 0) * P | k:(MIN, dist[j])
//     new_priorityQ[j][k] = (dist[k] > new_dist[k]) * (j <= new_dist[k] &&  new_dist[k] < j + 1) + (dist[k] == new_dist[k] && j != priority) * priorityQ[j][k]
// 	new_priority = priority
// End
void UpdateEdges(struct sssp_data* old_data, struct sssp_data* new_data, int priority) {
    jl_value_t* B = finch_exec("B = Finch.Fiber(\n\
        Dense(%s,\n\
            Element{typemax(Int64), Int64}()\n\
        )\n\
    )", finch_Int64(N));
    finch_call(dist_update_code1, B, old_data->dist, weights, old_data->priorityQ, finch_Int64(priority));
    
    // printf("B: \n");
    // finch_exec("println(%s.lvl.lvl.val)", B);
    // printf("Dist: \n");
    // finch_exec("println(%s.lvl.lvl.val)", old_data->dist);
    finch_call(dist_update_code2, new_data->dist, B, old_data->dist);
    finch_free(B);

    // printf("New dist: \n");
    // finch_exec("println(%s.lvl.lvl.val)", new_data->dist);

    finch_call(pq_update_code, new_data->priorityQ, old_data->dist, new_data->dist, old_data->priorityQ, finch_Int64(priority));
    // printf("New pQ: \n");
    // finch_exec("println(%s.lvl.lvl.lvl.val)", new_data->priorityQ);
}

// returns true if need to exit the loop
int inner_loop_condition(jl_value_t* priorityQ, int priority) {

    jl_value_t* val = finch_eval("Int64[]");
     jl_value_t* pq_slice = finch_Fiber(
        finch_SparseListLevel(finch_Int64(N), finch_eval("Int64[1, 1]"), finch_eval("Int64[]"),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );
    finch_call(slicing_code, pq_slice, priorityQ, finch_Int64(priority));
    
    jl_value_t *pq_val = finch_exec("%s.lvl.lvl.val", pq_slice);
    double *pq_data = jl_array_data(pq_val);
    for(int i = 0; i < N; i++) {
        if (pq_data[i] != 0) {
            finch_free(pq_slice);
            return 0;
        }
    }

    finch_free(pq_slice);
    return 1;   
}

// Let SSSP_one_priority_lvl(dist float[N], priorityQ int[P][N], priority int) -> (new_dist float[N], new_priorityQ int[P][N], new_priority int)
// 	new_dist, new_priorityQ, _ = UpdateEdges*(dist, priorityQ, priority) | (#2[#3] == 0)
//     new_priority = priority + 1
// End
int SSSP_one_priority_lvl(struct sssp_data* old_data, struct sssp_data* new_data, int priority) {
    struct sssp_data temp_val = {};
    struct sssp_data* temp = &temp_val;

    while (inner_loop_condition(old_data->priorityQ, priority) == 0) {
        UpdateEdges(old_data, new_data, priority);
        temp = old_data;
        old_data = new_data;
        new_data = temp;
    }

    return priority + 1;
}

int outer_loop_condition(jl_value_t* priorityQ, int priority) {

    if (priority == P+1) {
        return 1;
    }

    jl_value_t *pq_val = finch_exec("%s.lvl.lvl.lvl.val", priorityQ);
    double *pq_data = jl_array_data(pq_val);
    for(int i = 0; i < N * P; i++){
        if (pq_data[i] != 0) {
            return 0;
        }
    }

    return 1;
}

// Let SSSP() -> (new_dist float[N], dist float[N], priorityQ int[P][N])
// 	dist, priorityQ = Init(source)
// 	new_dist, _, _ = SSSP_one_priority_lvl*(dist, priorityQ, 0) | (#2 == 0 || #3 == P)
// End
int SSSP(struct sssp_data* final_data) {
    struct sssp_data data_val = {};

    jl_value_t* dist = finch_exec("Finch.Fiber(\n\
        Dense(%s,\n\
            Element{typemax(Int64), Int64}()\n\
        )\n\
    )", finch_Int64(N));
    final_data->dist = dist;

    jl_value_t* priorityQ = finch_Fiber(
        finch_SparseList(finch_Int64(P),
            finch_SparseList(finch_Int64(N),
                finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]"))
            )
        )
    );
    final_data->priorityQ = priorityQ;

    struct sssp_data old_val = {};
    struct sssp_data* old_data = &old_val;
    Init(old_data);

    int priority = 1;

    struct sssp_data temp_val = {};
    struct sssp_data* temp = &temp_val;
    while(outer_loop_condition(old_data->priorityQ, priority) == 0) {
        priority = SSSP_one_priority_lvl(old_data, final_data, priority);
        temp = old_data;
        old_data = final_data;
        final_data = temp;
    }

    return priority;
}


void make_weights_and_edges(const char* graph_name, int n) {
    // 0, 1, 0, 0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0
    char code[1000];
    sprintf(code, "N = %d\n\
        matrix = copy(transpose(MatrixMarket.mmread(\"./graphs/%s\")))\n\
        Finch.Fiber(\n\
                 Dense(N,\n\
                 SparseList(N, matrix.colptr, matrix.rowval,\n\
                 Element{0}(matrix.nzval))))", n, graph_name);

    weights = finch_eval(code);
    // finch_exec("println(%s.lvl.lvl.lvl.val)", weights);
    printf("Loaded weights\n");
}

void starter() {
    char zereout[1000];
    sprintf(zereout, "N = %d\n\
        rowptr = ones(Int64, N + 1)\n\
        Finch.Fiber(\n\
                 Dense(N,\n\
                 SparseList(N, rowptr, Int64[],\n\
                 Element{0}(Int64[]))))", N);
    weights = finch_eval(zereout);
    compile();
    printf("Compiled kernels\n");

    struct sssp_data d = {};
    struct sssp_data* data = &d;
    SSSP(data);

    printf("Ran starter\n");
}
void setup1() {
    // 1 5, 4 5, 3 4, 2 3, 1 2
    // jl_value_t* edge_vector = finch_eval("Int64[0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]");
    N = 5;
    source = 5;
    P = 5;
    
    // compile and cache 
    starter();

    make_weights_and_edges("dag5.mtx", N);

    struct sssp_data d = {};
    struct sssp_data* data = &d;
    SSSP(data);

    printf("EXAMPLE1\nFinal: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->dist);
}

void setup2() {
    // 2 1, 3 1, 3 2, 3 4
    N = 4;
    source = 1;
    P = 4;
    
    // compile and cache 
    starter();

    make_weights_and_edges("dag4.mtx", N);
    
    struct sssp_data d = {};
    struct sssp_data* data = &d;
    SSSP(data);

    printf("EXAMPLE2\nFinal: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->dist);
}

void setup3() {
    // 2 1, 3 1, 1 2, 3 2, 1 3
    // jl_value_t* edge_vector = finch_eval("Int64[0, 1, 1, 1, 0, 0, 1, 1, 0]");
    N = 3;
    source = 1;
    P = 3;
    
    // compile and cache 
    starter();

    make_weights_and_edges("dag3.mtx", N);

    struct sssp_data d = {};
    struct sssp_data* data = &d;
    SSSP(data);

    printf("EXAMPLE3\nFinal: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->dist);
}

void setup4() {
    // 2 3, 3 1, 4 3, 5 4, 6 5, 6 7, 7 5, 7 6
    // jl_value_t* edge_vector = finch_eval("Int64[0,0,0,0,0,0,0, 0,0,1,0,0,0,0, 1,0,0,0,0,0,0, 0,0,1,0,0,0,0, 0,0,0,1,0,0,0, 0,0,0,0,1,0,1, 0,0,0,0,1,1,0]");
    N = 7;
    P = 20;
    source = 1;
    
    // compile and cache 
    starter();

    make_weights_and_edges("dag7.mtx", N);

    struct sssp_data d = {};
    struct sssp_data* data = &d;
    SSSP(data);

    printf("EXAMPLE4\n Final: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->dist);
}

void setup5() {
    N = 4847571;
    P = 10000;
    source = 1;
    
    // compile and cache 
    starter();

    make_weights_and_edges("soc-LiveJournal1.mtx", N);

    struct sssp_data d = {};
    struct sssp_data* data = &d;
    SSSP(data);

    printf("LARGE GRAPH\n Final: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->dist);
}

int main(int argc, char** argv) {
    finch_initialize();

    jl_value_t* res = finch_eval("using RewriteTools\n\
    using Finch.IndexNotation: or_, choose\n\
     using SparseArrays\n\
     using MatrixMarket\n\
    ");

    setup1();

    setup2();

    setup3();

    setup4();

    setup5();

    finch_finalize();
}