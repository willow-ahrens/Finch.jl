#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

JULIA_DEFINE_FAST_TLS // only define this once, in an executable


// N int
// edges int[N][N]
int N = 5;
int P = 1000;
int source = 5;
jl_value_t* edges = 0;


struct bc_data {
    jl_value_t* frontier_list;

    jl_value_t* num_paths;

    jl_value_t* deps;

    jl_value_t* visited;

    int round;
};


// Let Init() -> (frontier_list int[N][N], num_paths int[N], deps int[N], visited int[N])
//    num_paths[j] = (j == source)
//    deps[j] = 0
//    visited[j] = (j == source)
//    frontier_list[r][j] = (r == 0 && j == source)
// End
void Init(struct bc_data* data) {
    jl_function_t* num_paths_init = finch_eval("function num_paths(num_paths, source)\n\
    @finch @loop i num_paths[i] = (i == $source)\n\
end");

    jl_value_t* num_paths = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(num_paths_init, num_paths, finch_Cint(source));
    printf("Num paths: \n");
    finch_exec("println(%s.lvl.lvl.val)", num_paths);

    jl_function_t* deps_init = finch_eval("function deps_init(deps)\n\
    @finch @loop i deps[i] = 0\n\
end");
    jl_value_t* deps = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(deps_init, deps);
    printf("Deps: \n");
    finch_exec("println(%s.lvl.lvl.val)", deps);

    jl_value_t* visited = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(num_paths_init, visited, finch_Cint(source));
    printf("Visited: \n");
    finch_exec("println(%s.lvl.lvl.val)", visited);

    jl_value_t* frontier_list = finch_Fiber(
        finch_Dense(finch_Cint(N),
            finch_SparseList(finch_Cint(N),
                finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]"))
            )
        )
    );
    jl_function_t* frontier_init = finch_eval("function frontier_init(frontier, source)\n\
        @finch @loop i j frontier[i,j] = (i == 1 && j == $source) * 1\n\
    end");
    finch_call(frontier_init, frontier_list, finch_Cint(source));
    printf("Frontier list: \n");
    finch_exec("println(%s.lvl.lvl.lvl.val)", frontier_list);

    data->num_paths = num_paths;
    data->deps = deps;
    data->visited = visited;
    data->frontier_list = frontier_list;
    data->round = 2;
}

// Let Forward_Step(frontier_in int[N], frontier_list int[N][N], num_paths int[N], visited int[N], round int) -> (frontier int[N], forward_frontier_list int[N][N], forward_num_paths int[N], forward_visited int[N], forward_round int)
// 	frontier[j] = edges[j][k] * frontier_list[round-1][k] * (visited[j] == 0) | k:(OR, 0)
// 	forward_frontier_list[r][j] = frontier[j] * (r == round) + frontier_list[r][j] * (r != round)
// 	forward_num_paths[j] = edges[j][k] * frontier_list[round - 1][k] * (visited[j] == 0) * num_paths[k] | k:(+, num_paths[j])
// 	forward_visited[j] = edges[j][k] * frontier_list[round-1][k] * (visited[j] == 0) | k:(OR, visited[j])
// 	forward_round = round + 1
// End
void ForwardStep(struct bc_data* in_data, struct bc_data* out_data) {
    printf("Starting round %d\n", in_data->round);
    out_data->deps = in_data->deps;
    // 	frontier[j] = edges[j][k] * frontier_list[round][k] * (visited[j] == 0) | k:(OR, 0)
    // 	forward_num_paths[j] = edges[j][k] * frontier_list[round - 1][k] * (visited[j] == 0) * num_paths[k] | k:(+, num_paths[j])
    // 	forward_visited[j] = edges[j][k] * frontier_list[round-1][k] * (visited[j] == 0) | k:(OR, visited[j])
    
    // Finch.Fiber(
    //     SparseList(10, [1, 6], [1, 3, 5, 7, 9],
    //     Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    jl_value_t* new_frontier = finch_Fiber(
        finch_SparseListLevel(finch_Cint(N), finch_eval("Cint[1, 1]"), finch_eval("Cint[]"),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    
    jl_value_t* new_num_paths = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    jl_value_t* new_visited = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    jl_function_t* frontier_visit_paths = finch_eval("function frontier_visit_paths(new_frontier, new_visited, new_num_paths, edges, N, round, frontier_list, old_visited, old_num_paths)\n\
        B = Finch.Fiber(\n\
            Dense(N,\n\
                Element{0, Cint}([])\n\
            )\n\
        )\n\
        @finch @loop j k new_frontier[j] <<$or>>= edges[j,k] * frontier_list[($round-1),k] * (old_visited[j] == 0)\n\
        @finch @loop j k new_visited[j] <<$or>>= (old_visited[j] != 0) * 1 + edges[j,k] * frontier_list[($round-1),k] * (old_visited[j] == 0)\n\
        @finch @loop j k B[j] += edges[j,k] * frontier_list[($round-1),k] * (old_visited[j] == 0) * old_num_paths[k]\n\
        @finch @loop j new_num_paths[j] = B[j] + old_num_paths[j]\n\
    end");
    finch_call(frontier_visit_paths, new_frontier, new_visited, new_num_paths, edges, finch_Cint(N), finch_Cint(in_data->round), in_data->frontier_list, in_data->visited, in_data->num_paths);
    out_data->visited = new_visited;
    out_data->num_paths = new_num_paths;

    printf("Current Frontier: \n");
    finch_exec("println(%s.lvl.lvl.val)", new_frontier);

    printf("New num paths: \n");
    finch_exec("println(%s.lvl.lvl.val)", new_num_paths);

    printf("New visited: \n");
    finch_exec("println(%s.lvl.lvl.val)", new_visited);

    // 	forward_frontier_list[r][j] = frontier[j] * (r == round) + frontier_list[r][j] * (r != round)
    jl_value_t* new_frontier_list = finch_Fiber(
        finch_Dense(finch_Cint(N),
            finch_SparseList(finch_Cint(N),
                finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]"))
            )
        )
    );
    jl_function_t* frontier_list_func = finch_eval("function frontier_list_func(new_frontier_list, frontier, old_frontier_list, round)\n\
        @finch @loop r j new_frontier_list[r,j] <<$or>>= frontier[j] * (r == $round) + old_frontier_list[r,j] * (r != $round)\n\
    end");
    finch_call(frontier_list_func, new_frontier_list, new_frontier, in_data->frontier_list, finch_Cint(in_data->round));
    out_data->frontier_list = new_frontier_list;
    printf("New Frontier list: \n");
    finch_exec("println(%s.lvl.lvl.lvl.val)", new_frontier_list);

    // 	forward_round = round + 1
    out_data->round = in_data->round + 1;
    printf("New round: %d\n", out_data->round);
}


int is_nonempty_frontier(jl_value_t* frontier_arr, int row) {
    finch_exec("println(%s.lvl.lvl.lvl.val)", frontier_arr);
    jl_value_t *frontier_val = finch_exec("%s.lvl.lvl.lvl.val", frontier_arr);
    int *frontier_data = jl_array_data(frontier_val);
     printf("Iterating from %d to %d\n", (row-1)*N, row * N);
    for (int i=(row-1)*N; i < row * N; i++) {
        if (frontier_data[i] != 0) {
            return 1;
        }
    }

    return 0;
}


// Let Forward(frontier_list int[N][N], num_paths int[N], visited int[N]) -> (dummy int[N], new_forward_frontier_list int[N][N], new_forward_num_paths int[N], new_forward_visited int[N], new_forward_round int)
// 	dummy[j] = 0
// 	_, new_forward_frontier_list, new_forward_num_paths, new_forward_visited, new_forward_round = Forward_Step*(dummy, frontier_list, num_paths, visited, 2) | (#2[#5-1] == 0)
// End
void Forward(struct bc_data* in_data, struct bc_data* out_data) {
    struct bc_data* old_data = in_data;
    
    while (is_nonempty_frontier(old_data->frontier_list, old_data->round - 1)) {
        ForwardStep(old_data, out_data);
        *old_data = *out_data;
    }
}


//          round = round - 1
//          frontier = frontier_list.pop();
//     	    frontier.apply(backward_vertex_f);
void BackwardVertex(struct bc_data* in_data, struct bc_data* out_data) {
    out_data->frontier_list = in_data->frontier_list;
    out_data->num_paths = in_data->num_paths;
    out_data->round = in_data->round - 1;

    printf("Backward vertex\n");
    printf("Indata deps: %p\n", in_data->deps);
    finch_exec("println(%s.lvl.lvl.val)", in_data->deps);
    //  final_deps[j] = deps[j] + (num_paths[j] != 0) * frontier_list[round][j] / ( (num_paths[j] == 0) * P + num_paths[j])
    jl_value_t* final_deps = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    jl_function_t* deps_func = finch_eval("function deps_func(new_deps, old_deps, frontier_list, num_paths, round, P)\n\
        @finch @loop j new_deps[j] = old_deps[j] + (num_paths[j] != 0) * frontier_list[$round,j] / ( (num_paths[j] == 0) * $P + num_paths[j])\n\
    end");
    finch_call(deps_func, final_deps, in_data->deps, in_data->frontier_list, in_data->num_paths, finch_Cint(out_data->round), finch_Cint(P));
    printf("New deps: \n");
    finch_exec("println(%s.lvl.lvl.val)", final_deps);
    out_data->deps = final_deps;

    //  final_visited[j] = frontier_list[round][j]
    jl_value_t* final_visited = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    jl_function_t* final_visited_func = finch_eval("function final_visited_func(final_visited, frontier_list, old_visited, round)\n\
        @finch @loop j final_visited[j] = $or(frontier_list[$round,j], old_visited[j])\n\
    end");
    finch_call(final_visited_func, final_visited, in_data->frontier_list, in_data->visited, finch_Cint(out_data->round));
    printf("New visited: \n");
    finch_exec("println(%s.lvl.lvl.val)", final_visited);
    out_data->visited = final_visited;

}

//          round = round - 1
//          frontier = frontier_list.pop();
//     	    frontier.apply(backward_vertex_f);
//           	#s2# transposed_edges.from(frontier).to(visited_vertex_filter).apply(backward_update);
//         	delete frontier;

// Let Backward_Step(frontier_list int[N][N], num_paths int[N], deps int[N], visited int[N], round int, dummy int[N]) -> (final_frontier_list int[N][N], final_num_paths int[N], final_deps int[N], final_visited int[N], final_round int, backward_deps int[N])
// 	final_frontier_list[r][j] = frontier_list[r][j]
// 	final_num_paths[j] = num_paths[j]
//  final_visited[j] = frontier_list[round][j]
// 	backward_deps[j] = edges[k][j] * frontier_list[round][k] * (visited[j] == 0) * deps[k] | k:(+, deps[j])
//  final_deps[j] = deps[j] + (num_paths[j] != 0) * frontier_list[round][j] / ( (num_paths[j] == 0) * P + num_paths[j])
//	final_round = round - 1
// End
void BackwardStep(struct bc_data* in_data, struct bc_data* out_data) {
    BackwardVertex(in_data, out_data);
    printf("Backward round: %d\n", out_data->round);
    // 	backward_deps[j] = edges[j][k] * frontier_list[round][k] * (visited[j] == 0) * deps[k] | k:(+, deps[j])
    jl_value_t* new_deps = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    printf("Intermediary deps: \n");
    finch_exec("println(%s.lvl.lvl.val)", out_data->deps);
    printf("Edges: \n");
    finch_exec("println(%s.lvl.lvl.lvl.val)", edges);
    printf("Frontier list: \n");
    finch_exec("println(%s.lvl.lvl.lvl.val)", out_data->frontier_list);
    printf("Visited: \n");
    jl_function_t* new_deps_func = finch_eval("function deps_func(new_deps, deps, visited, frontier_list, edges, round, N, source)\n\
        B = Finch.Fiber(\n\
                Dense(N,\n\
                    Element{0, Cint}([])\n\
                )\n\
            )\n\
        @finch @loop j k B[j] += edges[k,j] * frontier_list[$round,k] * (visited[j] == 0) * deps[k] * (j != $source)\n\
        @finch @loop j new_deps[j] = B[j] + deps[j]\n\
    end");
    finch_call(new_deps_func, new_deps, out_data->deps, out_data->visited, out_data->frontier_list, edges, finch_Cint(out_data->round), finch_Cint(N), finch_Cint(source));
    printf("Out deps: \n");
    finch_exec("println(%s.lvl.lvl.val)", new_deps);

    out_data->deps = new_deps;
}


//     	  % backward pass to accumulate the dependencies
//     	  while (round > 1)
//          frontier = frontier_list.pop();
//     	    frontier.apply(backward_vertex_f);
//     	    round = round - 1;
//           	#s2# transposed_edges.from(frontier).to(visited_vertex_filter).apply(backward_update);
//         	delete frontier;
//     	  end
// 	dummy[i] = 0
// 	_, final_num_paths, final_deps, _, _, _ = Backward_Step*(forward_frontier_list, forward_num_paths, new_deps, new_visited, forward_round, dummy) | (#5 == 0)
void Backward(struct bc_data* in_data, struct bc_data* out_data) {
    struct bc_data* old_data = in_data;
    
    while (old_data->round > 2) {
        BackwardStep(old_data, out_data);
        *old_data = *out_data;
    }

    BackwardVertex(old_data, out_data);
    *old_data = *out_data;
}


// func final_vertex_f(v : Vertex)
//     if num_paths[v] != 0
//         dependences[v] = (dependences[v] - 1 / num_paths[v]) * num_paths[v];   => deps[v] * num_paths[v] - 1
//     else
//         dependences[v] = 0;
//     end
// end

// Let ComputeFinal(deps int[N], num_paths int[N]) -> (new_deps int[N])
//     new_deps[i] = (num_paths[i] != 0) * (deps[i] * num_paths[i] - 1)
// End
void ComputeFinalDeps(struct bc_data* in_data, struct bc_data* out_data) {
    jl_value_t* final_deps = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    jl_function_t* final_deps_func = finch_eval("function deps_func(final_deps, deps, num_paths)\n\
        @finch @loop j final_deps[j] = (num_paths[j] != 0) * (deps[j] * num_paths[j] - 1)\n\
    end");
    finch_call(final_deps_func, final_deps, in_data->deps, in_data->num_paths);
    printf("Final deps: ");
    finch_exec("println(%s.lvl.lvl.val)", final_deps);
    out_data->deps = final_deps;
}

// {Final Result}
// Let BC() -> (result int[N], final_deps int[N], final_num_paths int[N], frontier_list int[N][N], num_paths int[N], deps int[N], visited int[N], forward_frontier_list int[N][N], forward_num_paths int[N], forward_round int, new_deps int[N], new_visited int[N], dummy int[N])
// 	frontier_list, num_paths, deps, visited = Init()
// 	_, forward_frontier_list, forward_num_paths, _, forward_round = Forward(frontier_list, num_paths, visited)
// 	new_deps, new_visited = Backwards_Vertex(forward_frontier_list, forward_num_paths, deps, visited, forward_round)
// 	dummy[i] = 0
// 	_, final_num_paths, final_deps, _, _, _ = Backward_Step*(forward_frontier_list, forward_num_paths, new_deps, new_visited, forward_round, dummy) | (#5 == 0)
//     result = ComputeFinal(final_deps, final_num_paths)
// End
void BC(struct bc_data* data) {
    Init(data);
    struct bc_data new_data = {};

    Forward(data, &new_data);
    *data = new_data;

    // clear visited trensor
    jl_function_t* clear = finch_eval("function clear(visited)\n\
        @finch @loop i visited[i] = 0\n\
    end");
    finch_call(clear, data->visited);

    Backward(data, &new_data);
    *data = new_data;

    ComputeFinalDeps(data, &new_data);
    *data = new_data;
}


void setup1() {
    // 1 5, 4 5, 3 4, 2 3, 1 2
    // expected: [0,0,1,2,0]
    // jl_value_t* edge_vector = finch_eval("Cint[0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]");
    N = 5;
    source = 5;
    edges = finch_eval("N = 5\n\
        edge_matrix = sparse([0 0 0 0 0; 1 0 0 0 0; 0 1 0 0 0; 0 0 1 0 0; 1 0 0 1 0])\n\
        Finch.Fiber(\n\
                 Dense(N,\n\
                 SparseList(N, edge_matrix.colptr, edge_matrix.rowval,\n\
                 Element{0.0}(edge_matrix.nzval))))");
    
    struct bc_data d = {};
    struct bc_data* data = &d;
    BC(data);

    printf("EXAMPLE1\nFinal deps: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->deps);
}

void setup2() {
    // 2 1, 3 1, 3 2, 3 4
    // expected: [0,0,0,0]
    N = 4;
    source = 1;
    edges = finch_eval("N = 4\n\
        edge_matrix = sparse([0 1 1 0; 0 0 1 0; 0 0 0 0; 0 0 1 0])\n\
        Finch.Fiber(\n\
                 Dense(N,\n\
                 SparseList(N, edge_matrix.colptr, edge_matrix.rowval,\n\
                 Element{0.0}(edge_matrix.nzval))))");
    
    struct bc_data d = {};
    struct bc_data* data = &d;
    BC(data);

    printf("EXAMPLE2\nFinal deps: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->deps);
}

void setup3() {
    // 2 1, 3 1, 1 2, 3 2, 1 3
    // expected: [0,0,0]
    // jl_value_t* edge_vector = finch_eval("Cint[0, 1, 1, 1, 0, 0, 1, 1, 0]");
    N = 3;
    source = 1;
    edges = finch_eval("N = 3\n\
        edge_matrix = sparse([0 1 1; 1 0 1; 1 0 0])\n\
        Finch.Fiber(\n\
                 Dense(N,\n\
                 SparseList(N, edge_matrix.colptr, edge_matrix.rowval,\n\
                 Element{0.0}(edge_matrix.nzval))))");
    struct bc_data d = {};
    struct bc_data* data = &d;
    BC(data);

    printf("EXAMPLE3\nFinal deps: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->deps);
}

void setup4() {
    // 2 3, 3 1, 4 3, 5 4, 6 5, 6 7, 7 5, 7 6
    // expected: [0,0,5,3,2,0]
    // jl_value_t* edge_vector = finch_eval("Cint[0,0,0,0,0,0,0, 0,0,1,0,0,0,0, 1,0,0,0,0,0,0, 0,0,1,0,0,0,0, 0,0,0,1,0,0,0, 0,0,0,0,1,0,1, 0,0,0,0,1,1,0]");
    N = 7;
    source = 1;
    edges = finch_eval("N = 7\n\
    edge_matrix = sparse([0 0 1 0 0 0 0; 0 0 0 0 0 0 0; 0 1 0 1 0 0 0; 0 0 0 0 1 0 0; 0 0 0 0 0 1 1; 0 0 0 0 0 0 1; 0 0 0 0 0 1 0])\n\
    Finch.Fiber(\n\
                Dense(N,\n\
                SparseList(N, edge_matrix.colptr, edge_matrix.rowval,\n\
                Element{0.0}(edge_matrix.nzval))))");

    struct bc_data d = {};
    struct bc_data* data = &d;
    BC(data);

    printf("EXAMPLE4\n Final deps: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->deps);
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

    setup1();

    setup2();

    setup3();

    setup4();

    finch_finalize();
}