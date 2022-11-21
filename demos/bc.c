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

jl_function_t* num_paths_init_code;
jl_function_t* deps_init_code;
jl_function_t* visited_init_code;
jl_function_t* frontier_init_code;

jl_function_t* forward_code1;
jl_function_t* forward_code2;
jl_function_t* forward_code3;

jl_function_t* backward_vertex_code1;
jl_function_t* backward_vertex_code2;
jl_function_t* backward_edge_code1;
jl_function_t* backward_edge_code2;

jl_function_t* compute_final_code;
jl_function_t* empty_frontier_code;


void compile() {
    printf("START COMPILE\n");
    jl_value_t*  num_paths_init_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        println(\"IN CODE\")\n\
        source = Finch.virtualize(:source, Int64, ctx_2)\n\
        println(source)\n\
        t = typeof(@fiber d(e(0)))\n\
        num_paths = Finch.virtualize(:num_paths, t, ctx_2)\n\
        println(num_paths)\n\
        \n\
        kernel = @finch_program @loop i num_paths[i] = (i == $source)\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function num_paths_init(num_paths, source)\n\
                $code\n\
            end\n\
    end");
    num_paths_init_code = finch_exec("eval(last(%s.args))", num_paths_init_expr);
   
    jl_value_t*  deps_init_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        t = typeof(@fiber d(e(0)))\n\
        deps = Finch.virtualize(:deps, t, ctx_2)\n\
        \n\
        kernel = @finch_program @loop i deps[i] = 0\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function deps_init(deps)\n\
                $code\n\
            end\n\
    end");
    deps_init_code = finch_exec("eval(last(%s.args))", deps_init_expr);
    
    jl_value_t*  visited_init_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        source = Finch.virtualize(:source, Int64, ctx_2)\n\
        t = typeof(@fiber d(e(0)))\n\
        visited = Finch.virtualize(:visited, t, ctx_2)\n\
        \n\
        kernel = @finch_program @loop i visited[i] = (i == $source)\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function visited_init(visited, source)\n\
                $code\n\
            end\n\
    end");
    visited_init_code = finch_exec("eval(last(%s.args))", visited_init_expr);
    
    jl_value_t*  frontier_init_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        source = Finch.virtualize(:source, Int64, ctx_2)\n\
        t4 = typeof(@fiber d(sl(e(0))))\n\
        frontier_list = Finch.virtualize(:frontier_list, t4, ctx_2)\n\
        \n\
        kernel = @finch_program (@loop i (@loop j (@sieve select[1, i] (@sieve select[$source, j] frontier_list[i,j] = 1 ))))\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function frontier_list_init(frontier_list, source)\n\
                $code\n\
            end\n\
    end");
    frontier_init_code = finch_exec("eval(last(%s.args))", frontier_init_expr);
    
    jl_value_t*  forward_expr1 = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        round = Finch.virtualize(:round, Int64, ctx_2)\n\
        t1 = typeof(@fiber d(sl(e(0))))\n\
        old_frontier_list = Finch.virtualize(:old_frontier_list, t1, ctx_2)\n\
        edges = Finch.virtualize(:edges, t1, ctx_2)\n\
        t2 = typeof(@fiber sl(e(0)))\n\
        new_frontier = Finch.virtualize(:new_frontier, t2, ctx_2)\n\
        t = typeof(@fiber d(e(0)))\n\
        old_num_paths = Finch.virtualize(:old_num_paths, t, ctx_2)\n\
        new_visited = Finch.virtualize(:new_visited, t, ctx_2)\n\
        old_visited = Finch.virtualize(:old_visited, t, ctx_2)\n\
        B = Finch.virtualize(:B, t, ctx_2)\n\
        w = Finch.virtualize(:w, typeof(Scalar{0, Int64}()), ctx_2, :w)\n\
        \n\
        kernel = @finch_program (@loop j @loop k (begin\n\
            new_frontier[j] <<$or>>= w[]\n\
            new_visited[j] <<$or>>= (old_visited[j] != 0) * 1 + w[]\n\
            B[j] += w[] * old_num_paths[k]\n\
        end\n\
            where (w[] = edges[j,k] * old_frontier_list[($round-1),k] * (old_visited[j] == 0)) ) )\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function forward1(new_frontier, new_visited, B, old_num_paths, old_frontier_list, old_visited, edges, round)\n\
                w = Scalar{0}()\n\
                $code\n\
            end\n\
    end");
    forward_code1 = finch_exec("eval(last(%s.args))", forward_expr1);
    
    jl_value_t*  forward_expr2 = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        t = typeof(@fiber d(e(0)))\n\
        new_num_paths = Finch.virtualize(:new_num_paths, t, ctx_2)\n\
        old_num_paths = Finch.virtualize(:old_num_paths, t, ctx_2)\n\
        B = Finch.virtualize(:B, t, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j new_num_paths[j] = B[j] + old_num_paths[j]\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function forward2(new_num_paths, B, old_num_paths)\n\
                $code\n\
            end\n\
    end");
    forward_code2 = finch_exec("eval(last(%s.args))", forward_expr2);
    
    jl_value_t*  forward_expr3 = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        round = Finch.virtualize(:round, Int64, ctx_2)\n\
        t1 = typeof(@fiber d(sl(e(0))))\n\
        new_frontier_list = Finch.virtualize(:new_frontier_list, t1, ctx_2)\n\
        old_frontier_list = Finch.virtualize(:old_frontier_list, t1, ctx_2)\n\
        t = typeof(@fiber sl(e(0)))\n\
        frontier = Finch.virtualize(:frontier, t, ctx_2)\n\
        \n\
        kernel = @finch_program (@loop r (@loop j new_frontier_list[r,j] <<$or>>= frontier[j] * (r == $round) + old_frontier_list[r,j] * (r != $round) ))\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function forward3(new_frontier_list, frontier, old_frontier_list, round)\n\
                $code\n\
            end\n\
    end");
    forward_code3 = finch_exec("eval(last(%s.args))", forward_expr3);
    
    jl_value_t*  backward_vertex_expr1 = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        P = 3\n\
        round = Finch.virtualize(:round, Int64, ctx_2)\n\
        t = typeof(@fiber d(e(0)))\n\
        old_deps = Finch.virtualize(:old_deps, t, ctx_2)\n\
        new_deps = Finch.virtualize(:new_deps, t, ctx_2)\n\
        num_paths = Finch.virtualize(:num_paths, t, ctx_2)\n\
        t1 = typeof(@fiber d(sl(e(0))))\n\
        frontier_list = Finch.virtualize(:frontier_list, t1, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j new_deps[j] = old_deps[j] + (num_paths[j] != 0) * frontier_list[$round,j] / ( (num_paths[j] == 0) * $P + num_paths[j])\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function back_vertex1(new_deps, old_deps, num_paths, frontier_list, round)\n\
                println(round)\n\
                $code\n\
            end\n\
    end");
    backward_vertex_code1 = finch_exec("eval(last(%s.args))", backward_vertex_expr1);
    
    jl_value_t*  backward_vertex_expr2 = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        round = Finch.virtualize(:round, Int64, ctx_2)\n\
        t = typeof(@fiber d(e(0)))\n\
        final_visited = Finch.virtualize(:final_visited, t, ctx_2)\n\
        old_visited = Finch.virtualize(:old_visited, t, ctx_2)\n\
        t1 = typeof(@fiber d(sl(e(0))))\n\
        frontier_list = Finch.virtualize(:frontier_list, t1, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j final_visited[j] = $or(frontier_list[$round,j], old_visited[j])\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function back_vertex2(final_visited, frontier_list, old_visited, round)\n\
                $code\n\
            end\n\
    end");
    backward_vertex_code2 = finch_exec("eval(last(%s.args))", backward_vertex_expr2);
    
    // @finch @loop j k B[j] += edges[k,j] * frontier_list[$round,k] * (visited[j] == 0) * deps[k] * (j != $source)\n\
    //     @finch @loop j new_deps[j] = B[j] + deps[j]
    jl_value_t*  backward_edge_expr1 = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        round = Finch.virtualize(:round, Int64, ctx_2)\n\
        source = Finch.virtualize(:source, Int64, ctx_2)\n\
        t = typeof(@fiber d(e(0)))\n\
        visited = Finch.virtualize(:visited, t, ctx_2)\n\
        deps = Finch.virtualize(:deps, t, ctx_2)\n\
        B = Finch.virtualize(:B, t, ctx_2)\n\
        t1 = typeof(@fiber d(sl(e(0))))\n\
        edges = Finch.virtualize(:edges, t1, ctx_2)\n\
        frontier_list = Finch.virtualize(:frontier_list, t1, ctx_2)\n\
        \n\
        kernel = @finch_program (@loop j (@loop k B[j] += edges[k,j] * frontier_list[$round,k] * (visited[j] == 0) * deps[k] * (j != $source) ))\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function back_edge1(B, edges, frontier_list, visited, deps, round, source)\n\
                $code\n\
            end\n\
    end");
    backward_edge_code1 = finch_exec("eval(last(%s.args))", backward_edge_expr1);
    
    jl_value_t*  backward_edge_expr2 = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        t = typeof(@fiber d(e(0)))\n\
        new_deps = Finch.virtualize(:new_deps, t, ctx_2)\n\
        deps = Finch.virtualize(:deps, t, ctx_2)\n\
        B = Finch.virtualize(:B, t, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j new_deps[j] = B[j] + deps[j]\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function back_edge2(new_deps, B, deps)\n\
                $code\n\
            end\n\
    end");
    finch_exec("println(last(%s.args))", backward_edge_expr2);
    backward_edge_code2 = finch_exec("eval(last(%s.args))", backward_edge_expr2);
    
    // @loop j final_deps[j] = (num_paths[j] != 0) * (deps[j] * num_paths[j] - 1)
    jl_value_t* compute_final_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        t = typeof(@fiber d(e(0)))\n\
        new_deps = Finch.virtualize(:new_deps, t, ctx_2)\n\
        deps = Finch.virtualize(:deps, t, ctx_2)\n\
        num_paths = Finch.virtualize(:num_paths, t, ctx_2)\n\
        \n\
        kernel = @finch_program @loop j new_deps[j] = (num_paths[j] != 0) * (deps[j] * num_paths[j] - 1)\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function final_compute(new_deps, num_paths, deps)\n\
                $code\n\
            end\n\
    end");
    compute_final_code = finch_exec("eval(last(%s.args))", compute_final_expr);

    jl_value_t* empty_frontier_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        row = Finch.virtualize(:row, Int64, ctx_2)\n\
        t1 = typeof(@fiber d(sl(e(0))))\n\
        frontier_list = Finch.virtualize(:frontier_list, t1, ctx_2)\n\
        res = Finch.virtualize(:res, typeof(@fiber d(e(0))), ctx_2)\n\
        \n\
        kernel = @finch_program (@loop i (@loop j res[i] <<$or>>= frontier_list[$row, j] ))\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function final_compute(frontier_list, row)\n\
                res = Finch.Fiber(\n\
                    Dense(1,\n\
                        Element{0, Int64}()\n\
                    )\n\
                )\n\
                $code\n\
                return res.lvl.lvl.val\n\
            end\n\
    end");
    empty_frontier_code = finch_exec("eval(last(%s.args))", empty_frontier_expr);
    
    printf("COMPILE DONE\n");
}

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
    printf("Before init\n");
    jl_value_t* num_paths = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );
    finch_call(num_paths_init_code, num_paths, finch_Int64(source));
    printf("Num paths: \n");
    finch_exec("println(%s.lvl.lvl.val)", num_paths);

    jl_value_t* deps = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );
    finch_call(deps_init_code, deps);
    printf("Deps: \n");
    finch_exec("println(%s.lvl.lvl.val)", deps);

    jl_value_t* visited = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );
    finch_call(visited_init_code, visited, finch_Int64(source));
    printf("Visited: \n");
    finch_exec("println(%s.lvl.lvl.val)", visited);

    jl_value_t* frontier_list = finch_Fiber(
        finch_Dense(finch_Int64(N),
            finch_SparseList(finch_Int64(N),
                finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]"))
            )
        )
    );
    finch_call(frontier_init_code, frontier_list, finch_Int64(source));
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

    out_data->round = in_data->round + 1;
    
    jl_value_t* new_frontier = finch_Fiber(
        finch_SparseListLevel(finch_Int64(N), finch_eval("Int64[1, 1]"), finch_eval("Int64[]"),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );
    
    jl_value_t* B = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );
   
    // new_frontier, new_visited, B, old_frontier_list, old_visited, edges, round
    finch_call(forward_code1, new_frontier, out_data->visited, B, in_data->num_paths, in_data->frontier_list, in_data->visited, edges, finch_Int64(in_data->round));
    finch_call(forward_code2, out_data->num_paths, B, in_data->num_paths);
    
    printf("Current Frontier: \n");
    finch_exec("println(%s.lvl.lvl.val)", new_frontier);

    printf("New num paths: \n");
    finch_exec("println(%s.lvl.lvl.val)",  out_data->num_paths);

    printf("New visited: \n");
    finch_exec("println(%s.lvl.lvl.val)", out_data->visited);

    // new_frontier_list, frontier, old_frontier_list, round
    finch_call(forward_code3, out_data->frontier_list, new_frontier, in_data->frontier_list, finch_Int64(in_data->round));

    finch_free(new_frontier);
    finch_free(B);

    printf("New Frontier list: \n");
    finch_exec("println(%s.lvl.lvl.lvl.val)", out_data->frontier_list);
}


int is_nonempty_frontier(jl_value_t* frontier_arr, int row) {
    // jl_value_t *frontier_val = finch_exec("%s.lvl.lvl.lvl.val", frontier_arr);
    // int *frontier_data = jl_array_data(frontier_val);
    // printf("Iterating from %d to %d\n", (row-1)*N, row * N);
    // printf("Frontier val: %d\n", frontier_data[4]);
    // for (int i=0; i < N * N; i++) {
    //     printf("%d\n", frontier_data[i]);
    // }
    // for (int i=(row-1)*N; i < row * N; i++) {
    //     if (frontier_data[i] != 0) {
    //         return 1;
    //     }
    // }

    // return 0;
    
    jl_value_t* is_empty_arr = finch_call(empty_frontier_code, frontier_arr, finch_Int64(row));
    int *is_empty = jl_array_data(is_empty_arr);
    return is_empty[0];
}


// Let Forward(frontier_list int[N][N], num_paths int[N], visited int[N]) -> (dummy int[N], new_forward_frontier_list int[N][N], new_forward_num_paths int[N], new_forward_visited int[N], new_forward_round int)
// 	dummy[j] = 0
// 	_, new_forward_frontier_list, new_forward_num_paths, new_forward_visited, new_forward_round = Forward_Step*(dummy, frontier_list, num_paths, visited, 2) | (#2[#5-1] == 0)
// End
int Forward(struct bc_data* in_data, struct bc_data* out_data) {
   
    struct bc_data* tmp_data = 0;
    int swap = -1;

    while (is_nonempty_frontier(in_data->frontier_list, in_data->round - 1)) {
        ForwardStep(in_data, out_data);

        tmp_data = in_data;
        in_data = out_data;
        out_data = tmp_data;
        swap += 1;
    }

    return swap % 2;
}

void BackwardVertex(struct bc_data* in_data, struct bc_data* out_data) {
    // out_data->frontier_list = in_data->frontier_list;
    // out_data->num_paths = in_data->num_paths;
    out_data->round = in_data->round - 1;
    
    // new_deps, old_deps, num_paths, frontier_list, round, P
    finch_call(backward_vertex_code1, out_data->deps, in_data->deps, in_data->num_paths, in_data->frontier_list, finch_Int64(out_data->round));
    printf("New deps: \n");
    finch_exec("println(%s.lvl.lvl.val)", out_data->deps);
    
    finch_call(backward_vertex_code2, out_data->visited, in_data->frontier_list, in_data->visited, finch_Int64(out_data->round));
    printf("New visited: \n");
    finch_exec("println(%s.lvl.lvl.val)", out_data->visited);
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
    
    // 	backward_deps[j] = edges[j][k] * frontier_list[round][k] * (visited[j] == 0) * deps[k] | k:(+, deps[j])
    jl_value_t* B = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );
    
    // B, edges, frontier_list, visited, deps, round, source
    finch_call(backward_edge_code1, B, edges, out_data->frontier_list, out_data->visited, out_data->deps, finch_Int64(out_data->round), finch_Int64(source));
   
    printf("B: \n");
    finch_exec("println(%s.lvl.lvl.val)", B);
    
    printf("In DEPS: \n");
    finch_exec("println(%s.lvl.lvl.val)", out_data->deps);
    
    jl_value_t* new_deps = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );
    finch_call(backward_edge_code2, new_deps, B, out_data->deps);
    
    out_data->deps = new_deps;
    printf("Out deps: \n");
    finch_exec("println(%s.lvl.lvl.val)", out_data->deps);
    finch_free(B);
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
int Backward(struct bc_data* in_data, struct bc_data* out_data) {
    struct bc_data tmp = {};
    struct bc_data* tmp_data = &tmp;
    
    int swap = -1;

    while (in_data->round > 2) {
        BackwardStep(in_data, out_data);
        
        tmp_data = in_data;
        in_data = out_data;
        out_data = tmp_data;
        swap += 1;
    }

    if (swap % 2) {
        BackwardVertex(out_data, in_data);
    } else {
        BackwardVertex(in_data, out_data);
    }

    return (swap + 1) % 2;
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
    finch_call(compute_final_code, out_data->deps, in_data->num_paths, in_data->deps);

    printf("Final deps: ");
    finch_exec("println(%s.lvl.lvl.val)", out_data->deps);
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
    struct bc_data* cpy = data;
    Init(data);
   
    jl_value_t* num_paths = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );
    
    jl_value_t* deps = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );
    
    jl_value_t* visited = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );
    
    jl_value_t* frontier_list = finch_Fiber(
        finch_Dense(finch_Int64(N),
            finch_SparseList(finch_Int64(N),
                finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]"))
            )
        )
    );
    struct bc_data new = {};
    struct bc_data* new_data = &new;

    new_data->deps = deps;
    new_data->num_paths = num_paths;
    new_data->visited = visited;
    new_data->frontier_list = frontier_list;
    int swap = Forward(data, new_data);
    
    struct bc_data* tmp = 0;
    if (swap) {
        tmp = data;
        data = new_data;
        new_data = tmp;
    }
    // clear visited trensor
    finch_call(deps_init_code, data->visited);

    swap = Backward(data, new_data);
    if (swap) {
        tmp = data;
        data = new_data;
        new_data = tmp;
    }

    ComputeFinalDeps(data, new_data);

    cpy->deps = new_data->deps;
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

    struct bc_data d = {};
    struct bc_data* data = &d;
    BC(data);

    printf("EXAMPLE\nFinal: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->deps);
}

void setup1() {
    // 1 5, 4 5, 3 4, 2 3, 1 2
    // expected: [0,0,1,2,0]
    // jl_value_t* edge_vector = finch_eval("Int64[0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]");
    N = 5;
    source = 5;
    
    make_weights_and_edges("dag5.mtx", N);

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
    
    make_weights_and_edges("dag4.mtx", N);

    struct bc_data d = {};
    struct bc_data* data = &d;
    BC(data);

    printf("EXAMPLE2\nFinal deps: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->deps);
}

void setup3() {
    // 2 1, 3 1, 1 2, 3 2, 1 3
    // expected: [0,0,0]
    // jl_value_t* edge_vector = finch_eval("Int64[0, 1, 1, 1, 0, 0, 1, 1, 0]");
    N = 3;
    source = 1;
    
    make_weights_and_edges("dag3.mtx", N);

    struct bc_data d = {};
    struct bc_data* data = &d;
    BC(data);

    printf("EXAMPLE3\nFinal deps: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->deps);
}

void setup4() {
    // 2 3, 3 1, 4 3, 5 4, 6 5, 6 7, 7 5, 7 6
    // expected: [0,0,5,3,2,0]
    // jl_value_t* edge_vector = finch_eval("Int64[0,0,0,0,0,0,0, 0,0,1,0,0,0,0, 1,0,0,0,0,0,0, 0,0,1,0,0,0,0, 0,0,0,1,0,0,0, 0,0,0,0,1,0,1, 0,0,0,0,1,1,0]");
    N = 7;
    source = 1;
    
    make_weights_and_edges("dag7.mtx", N);

    struct bc_data d = {};
    struct bc_data* data = &d;
    BC(data);

    printf("EXAMPLE4\n Final deps: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->deps);
}

void setup5() {
    N = 4847571;
    source = 1;
    
    make_weights_and_edges("soc-LiveJournal1.mtx", N);

    struct bc_data d = {};
    struct bc_data* data = &d;
    BC(data);

    printf("LARGE GRAPH\n Final: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->deps);
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

    starter();

    setup1();

    // setup2();

    // setup3();

    // setup4();

    // setup5();
    
    finch_finalize();
}