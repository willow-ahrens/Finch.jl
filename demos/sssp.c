
#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

// N int

// P int

// edges int[N][N]

// weights float[N][N]

// source int

// Let Init(source int) -> (dist float[N], priorityQ int[P][N])
//     dist[j] = (j != source) * P
//     priorityQ[p][j] = (p == 0 && j == source) + (p == (P - 1) && j != source)
// End

// Let UpdateEdges(dist float[N], priorityQ int[P][N], priority int) -> (new_dist float[N], new_priorityQ int[P][N], new_priority int)
//     new_dist[j] = edges[j][k] * priorityQ[priority][k] * (weights[j][k] + dist[k]) + (edges[j][k] * priorityQ[priority][k] == 0) * P | k:(MIN, dist[j])
//     new_priorityQ[j][k] = (dist[k] > new_dist[k]) * (j <= new_dist[k] &&  new_dist[k] < j + 1) + (dist[k] == new_dist[k] && j != priority) * priorityQ[j][k]
// 	new_priority = priority
// End

// Let SSSP_one_priority_lvl(dist float[N], priorityQ int[P][N], priority int) -> (new_dist float[N], new_priorityQ int[P][N], new_priority int)
// 	new_dist, new_priorityQ, _ = UpdateEdges*(dist, priorityQ, priority) | (#2[#3] == 0)
//     new_priority = priority + 1
// End

// Let SSSP() -> (new_dist float[N], dist float[N], priorityQ int[P][N])
// 	dist, priorityQ = Init(source)
// 	new_dist, _, _ = SSSP_one_priority_lvl*(dist, priorityQ, 0) | (#2 == 0 || #3 == P)
// End

//    edges.insert({0, 1}, 1);
//    edges.insert({1, 2}, 1);
//    edges.insert({2, 3}, 1);
//    edges.insert({3, 4}, 1);
//    edges.insert({0, 4}, 1);
//    edges.insert({2, 4}, 1);
//    edges.insert({1, 4}, 1);

//    weights.insert({0, 1}, 1);
//    weights.insert({1, 2}, 1);
//    weights.insert({2, 3}, 1);
//    weights.insert({3, 4}, 1);
//    weights.insert({0, 4}, 10);
//    weights.insert({2, 4}, 8);
//    weights.insert({1, 4}, 6);
 

//  priorityQ[j][k] += (dist[k] > new_dist[k]) * (new_dist[k] == j) - (dist[k] > new_dist[k]) * (dist[k] == j)

 // new_priorityQ[j][k] = (dist[k] > new_dist[k]) * (new_dist[k] == j) + (dist[k] == new_dist[k] && j != priority) * priorityQ[j][k]
//  \forall k j priorityQ[j][k] += (dist[k] > new_dist[k]) * (new_dist[k] == j) - (dist[k] > new_dist[k]) * (dist[k] == j)
//  \forall k j priorityQ[j][k] += (mask[k] * (new_dist[k] == j) - mask[k]* (dist[k] == j))


JULIA_DEFINE_FAST_TLS // only define this once, in an executable

int P = 5;
int N = 5;
int source = 5;

struct sssp_data {
    jl_value_t* priorityQ;

    jl_value_t* dist;
};


jl_value_t* Init_priorityQ() {
    jl_function_t* pq_init = finch_eval("function pq_init(source, P, priorityQ)\n\
        @index @loop p j priorityQ[p, j] = (p == 1 && j == $source) + (p == $P && j != $source)\n\
    end");

    jl_value_t* val = finch_eval("Cint[]");
    jl_value_t *priorityQ = finch_Fiber(
        finch_Solid(finch_Cint(P),
        // finch_HollowListLevel(
        //     finch_Int64(N),
        //     pos, 
        //     idx,
        //     finch_ElementLevel(finch_Int64(0),val)
        // )
        finch_Solid(finch_Cint(N), finch_ElementLevel(finch_Cint(0), val))
        ));

    finch_call(pq_init, finch_Cint(source), finch_Cint(P), priorityQ);
    finch_exec("println(%s)", priorityQ);

    jl_value_t *pq_val = finch_exec("%s.lvl.lvl.lvl.val", priorityQ);
    int *pq_data = jl_array_data(pq_val);
    for(int i = 0; i < 25; i++) {
        printf("%d, ", pq_data[i]);
    }
    printf("\n");
    finch_free(pq_val);
}

jl_value_t* Init_dist() {
    jl_function_t* dist_init = finch_eval("function dist_init(source, P, dist)\n\
        @index @loop j dist[j] = (j != $source) * $P\n\
    end");

    jl_value_t* val = finch_eval("Cint[]");
    jl_value_t* dist = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), val))
    );
    finch_call(dist_init, finch_Cint(source), finch_Cint(P), dist);
    finch_exec("println(%s)", dist);
}

void Init(struct sssp_data* data) {
    jl_value_t* pq = Init_priorityQ();
    jl_value_t* d = Init_dist();

    data->priorityQ = pq;
    data->dist = d;
    
    return;
}

int main(int argc, char** argv){
    printf("%s\n", "BEfore initialize");

    finch_initialize();
    printf("%s\n", "After initialize");

    jl_value_t* res = finch_eval("using Finch.IndexNotation\n");

    struct sssp_data data_val = {};
    struct sssp_data *data = &data_val;
    Init(data);

    // printf("Result of import: %p\n", res);

    // jl_function_t* pq_init = finch_eval("function pq_init(source, P, priorityQ)\n\
    //     @index @loop p j priorityQ[p, j] = (p == 1 && j == $source) + (p == $P && j != $source)\n\
    // end");

    // int P = 5;
    // int N = 5;
    // int source = 5;

    // jl_value_t* pos = finch_eval("Cint[1, 1, 1, 1, 1, 1]");
    // jl_value_t* idx = finch_eval("Cint[]");
    // jl_value_t* val = finch_eval("Cint[]");

    // printf("%s\n", "Before defining priority q");
 
    // printf("Pos: %p\n", pos);
    // printf("Idx: %p\n", idx);
    // printf("Val: %p\n", val);

    // jl_value_t *priorityQ = finch_Fiber(
    //     finch_Solid(finch_Cint(P),
    //     // finch_HollowListLevel(
    //     //     finch_Int64(N),
    //     //     pos, 
    //     //     idx,
    //     //     finch_ElementLevel(finch_Int64(0),val)
    //     // )
    //     finch_Solid(finch_Cint(N), finch_ElementLevel(finch_Cint(0), val))
    //     ));

    // finch_call(pq_init, finch_Cint(source), finch_Cint(P), priorityQ);

    // finch_exec("println(%s)", priorityQ);

    // jl_value_t *pq_val = finch_exec("%s.lvl.lvl.lvl.val", priorityQ);

    // int *pq_data = jl_array_data(pq_val);

    // for(int i = 0; i < 25; i++){
    //     printf("%d, ", pq_data[i]);
    // }
    // printf("\n");

    // finch_free(pq_val);

    // finch_free(priorityQ);

    finch_finalize();
}