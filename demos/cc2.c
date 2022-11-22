#include <julia.h>
#include "finch.h"
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

JULIA_DEFINE_FAST_TLS // only define this once, in an executable


// N int
// edges int[N][N]
int N = 5;
jl_value_t* edges = 0;

jl_function_t* ids_init_code;
jl_function_t* edge_update_code1;
jl_function_t* edge_update_code2;
jl_function_t* edge_update_code3;
jl_function_t* vertex_update_code;
jl_function_t* reset_scalar_code;

struct cc_data {
    jl_value_t* IDs;

    jl_value_t* update0;

    jl_value_t* update1;
};

void compile() {
    jl_value_t*  ids_init_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        t = typeof(@fiber d(e(0)))\n\
        ids = Finch.virtualize(:ids, t, ctx_2)\n\
        \n\
        kernel = @finch_program @loop i ids[i] = i\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function ids_init(ids)\n\
                $code\n\
            end\n\
    end");
    ids_init_code = finch_exec("eval(last(%s.args))", ids_init_expr);

    jl_value_t* edge_update_expr1 = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        N = Finch.virtualize(:N, Int64, ctx_2)\n\
        t = typeof(@fiber d(e(0)))\n\
        old_ids = Finch.virtualize(:old_ids, t, ctx_2)\n\
        t1 = typeof(@fiber d(e(typemax(Int64))))\n\
        B = Finch.virtualize(:B, t1, ctx_2)\n\
        t4 = typeof(@fiber d(sl(e(0))))\n\
        edges = Finch.virtualize(:edges, t4, ctx_2)\n\
        \n\
        kernel = @finch_program (@loop j (@loop i B[old_ids[j]] <<min>>= old_ids[old_ids[i]] * (edges[j,i] == 1 || edges[i,j] == 1) + (edges[j,i] == 0 && edges[i,j] == 0) * ($N + 1) ))\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function edge_update1(B, old_ids, edges, N)\n\
                $code\n\
            end\n\
    end");
    edge_update_code1 = finch_exec("eval(last(%s.args))", edge_update_expr1);

    jl_value_t* edge_update_expr2 = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        t = typeof(@fiber d(e(0)))\n\
        old_ids = Finch.virtualize(:old_ids, t, ctx_2)\n\
        B = Finch.virtualize(:B, t, ctx_2)\n\
        new_ids = Finch.virtualize(:new_ids, t, ctx_2)\n\
        \n\
        kernel = @finch_program @loop i new_ids[i] = min(B[i],old_ids[i])\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function edge_update2(new_ids, B, old_ids)\n\
                $code\n\
            end\n\
    end");
    edge_update_code2 = finch_exec("eval(last(%s.args))", edge_update_expr2);

     jl_value_t* edge_update_expr3 = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        t = typeof(@fiber d(e(0)))\n\
        old_ids = Finch.virtualize(:old_ids, t, ctx_2)\n\
        new_ids = Finch.virtualize(:new_ids, t, ctx_2)\n\
        new_update1 = Finch.virtualize(:new_update1, t, ctx_2)\n\
        \n\
        kernel = @finch_program (@loop j (@loop i new_update1[j] <<or>>= (old_ids[old_ids[i]] != new_ids[old_ids[i]]) ))\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function edge_update3(new_update1, new_ids, old_ids, N)\n\
                $code\n\
            end\n\
    end");
    // finch_exec("println(last(%s.args))", edge_update_expr3);
    edge_update_code3 = finch_exec("eval(last(%s.args))", edge_update_expr3);

    jl_value_t*  vertex_update_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        t = typeof(@fiber d(e(0)))\n\
        old_ids = Finch.virtualize(:old_ids, t, ctx_2)\n\
        new_ids = Finch.virtualize(:new_ids, t, ctx_2)\n\
        new_update0 = Finch.virtualize(:new_update0, t, ctx_2)\n\
        w = Finch.virtualize(:w, typeof(Scalar{0, Int64}()), ctx_2, :w)\n\
        \n\
        kernel = @finch_program (@loop i (@loop j (begin\n\
            new_ids[i] = w[]\n\
            new_update0[j] <<or>>= (w[] != old_ids[i])\n\
        end\n\
            where (w[] = old_ids[old_ids[i]]) ) ))\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function vertex_update(new_update0, new_ids, old_ids)\n\
                w = Scalar{0}()\n\
                $code\n\
            end\n\
    end");
    vertex_update_code = finch_exec("eval(last(%s.args))", vertex_update_expr);

    jl_value_t*  reset_scalar_expr = finch_exec("ctx = Finch.LowerJulia()\n\
    code = Finch.contain(ctx) do ctx_2\n\
        val = Finch.virtualize(:val, Int64, ctx_2)\n\
        idx = Finch.virtualize(:idx, Int64, ctx_2)\n\
        t = typeof(@fiber d(e(0)))\n\
        w = Finch.virtualize(:w, t, ctx_2)\n\
        \n\
        kernel = @finch_program @loop i w[i] = (i == 1) * $val\n\
        kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)\n\
    end\n\
    return quote\n\
            function clear(w, idx, val)\n\
                $code\n\
            end\n\
    end");
    // finch_exec("println(last(%s.args))", reset_scalar_expr);
    reset_scalar_code = finch_exec("eval(last(%s.args))", reset_scalar_expr);

    printf("COMPILE DONE\n");
}

// Let Init() -> (IDs int[N], update0 int, update1 int)
//     IDs[i] = i
//     update0 = 1
//     update1 = 1
// End

// func init(v : Vertex)
//      IDs[v] = v;
// end
void Init(struct cc_data* data) {
    jl_value_t* ids = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );
    finch_call(ids_init_code, ids);
    
    printf("IDs: \n");
    finch_exec("println(%s.lvl.lvl.val)", ids);

    jl_value_t* up0 = finch_Fiber(
        finch_Dense(finch_Int64(1),
        finch_ElementLevel(finch_Int64(1), finch_eval("Int64[1]")))
    );
    jl_value_t* up1 = finch_Fiber(
        finch_Dense(finch_Int64(1),
        finch_ElementLevel(finch_Int64(1), finch_eval("Int64[1]")))
    );

    // printf("Update: \n");
    // finch_exec("println(%s)", up0);
    // finch_exec("println(%s)", up1);

    data->IDs = ids;
    data->update0 = up0;
    data->update1 = up1;
}

// func updateEdge(src : Vertex, dst : Vertex)
//     var src_id: Vertex = IDs[src];
//     var dst_id: Vertex = IDs[dst];

//     var p_src_id: Vertex = IDs[src_id];
//     var p_dst_id: Vertex = IDs[dst_id];

//     IDs[dst_id] min= p_src_id;
//     IDs[src_id] min= p_dst_id;

//     if update[1] == 0
//           if p_dst_id != IDs[dst_id]
//                 update[1] = 1;
//           end
//           if p_src_id != IDs[src_id]
//                 update[1] = 1;
//           end 
//     end
    
// end

// new_IDs[old_IDs[j]] = old_IDs[old_IDs[i]] * (edges[j][i] || edges[i][j]) + (edges[j][i] == 0 && edges[i][j] == 0) * (N+1) | i: (MIN, old_IDs[old_IDs[j]])
// new_update[1] = (old_update[1] == 0) * ( old[old[j]] != new[old[j]] || old[old[i]] != new[old[i]] ) | i:(OR, 0)

// @finch @loop j i B[old_ids[j]] <<min>>= old_ids[old_ids[i]] * (edges[j,i] == 1|| edges[i,j] == 1) + (edges[j,i] == 0 && edges[i,j] == 0) * (N+1)\n\
//     @finch @loop i begin\n\
//         new_ids[i] = min(B[i],old_ids[i])\n\
//         new_update1[] <<$or>>= old[old[j]] != new[old[j]] || old[old[i]] != new[old[i]]\n\
//     end\n\

void UpdateEdges(struct cc_data* in_data, struct cc_data* out_data) {
    finch_call(reset_scalar_code, out_data->update1, finch_Int64(1), finch_Int64(0));

    jl_value_t* B = finch_exec("B = Finch.Fiber(\n\
        Dense(%s,\n\
            Element{typemax(Int64), Int64}()\n\
        )\n\
    )", finch_Int64(N));
    finch_call(edge_update_code1, B, in_data->IDs, edges, finch_Int64(N)); // B, old_ids, edges
    printf("B: \n");
    finch_exec("println(%s.lvl.lvl.val)", B);
    finch_call(edge_update_code2, out_data->IDs, B, in_data->IDs); // new_ids, B, old_ids
    
    printf("New IDs: \n");
    finch_exec("println(%s.lvl.lvl.val)", out_data->IDs);
    printf("Old IDs: \n");
    finch_exec("println(%s.lvl.lvl.val)", in_data->IDs);
    finch_call(edge_update_code3, out_data->update1, out_data->IDs, in_data->IDs, finch_Int64(N)); //new_update1, new_ids, old_ids
    finch_free(B);
    
    printf("New update 1: \n");
    finch_exec("println(%s.lvl.lvl.val)", out_data->update1);

    out_data->update0 = in_data->update0;
}


// func pjump(v: Vertex) 
//     var y: Vertex = IDs[v];
//     var x: Vertex = IDs[y];
//     if x != y
//         IDs[v] = x;
//         update[0] = 1;
//     end
// end

// update[0] = 0
// final[i] = (new[new[i]] != new[i]) * new[new[i]] + (new[new[i]] == new[i]) * new[i]
// update[0] = new[new[i]] != new[i] | i:(OR, 0)
void UpdateVertices(struct cc_data* in_data, struct cc_data* out_data) {
    finch_call(reset_scalar_code, out_data->update0, finch_Int64(1), finch_Int64(0));
    // new_ids, new_update0, old_ids
    printf("Old IDs: \n");
    finch_exec("println(%s.lvl.lvl.val)", in_data->IDs);

    finch_call(vertex_update_code, out_data->update0, out_data->IDs, in_data->IDs);
    
    printf("New IDs: \n");
    finch_exec("println(%s.lvl.lvl.val)", out_data->IDs);

    printf("New update 0: \n");
    finch_exec("println(%s.lvl.lvl.val)", out_data->update0);

    out_data->update1 = in_data->update1;
}


int has_changed(jl_value_t* update) {
    jl_value_t *update_val = finch_exec("%s.lvl.lvl.val", update);
    int* update_data = jl_array_data(update_val);
    return update_data[0];
}

//             update[1] = 0;
//             #s1# edges.apply(updateEdge);
//             update[0] = 1;
//             #s0# while update[0] != 0
//                 update[0] = 0;
//                 vertices.apply(pjump);
//             end
void CC_Step(struct cc_data* in_data, struct cc_data* out_data) {
    
    struct cc_data* tmp_data = 0;

    UpdateEdges(in_data, out_data);

    tmp_data = in_data;
    in_data = out_data;
    out_data = tmp_data;
    
    finch_exec("println(%s.lvl.lvl.val)", in_data->update0);

    finch_call(reset_scalar_code, in_data->update0, finch_Int64(1), finch_Int64(1));

    finch_exec("println(%s.lvl.lvl.val)", in_data->update0);

    while (has_changed(in_data->update0)) {
        UpdateVertices(in_data, out_data);

        tmp_data = in_data;
        in_data = out_data;
        out_data = tmp_data;
    }

}

//         vertices.apply(init);	
//         update[1] = 1;
//         while update[1] != 0
//             update[1] = 0;
//             #s1# edges.apply(updateEdge);
//             update[0] = 1;
//             #s0# while update[0] != 0
//                 update[0] = 0;
//                 vertices.apply(pjump);
//             end
//         end

void CC(struct cc_data* data) {

    Init(data);

    struct cc_data new = {};
    struct cc_data* new_data = &new;
    
    new_data->IDs = finch_Fiber(
        finch_Dense(finch_Int64(N),
        finch_ElementLevel(finch_Int64(0), finch_eval("Int64[]")))
    );;
    new_data->update0 = finch_Fiber(
        finch_Dense(finch_Int64(1),
        finch_ElementLevel(finch_Int64(1), finch_eval("Int64[1]")))
    );
    new_data->update1 = finch_Fiber(
        finch_Dense(finch_Int64(1),
        finch_ElementLevel(finch_Int64(1), finch_eval("Int64[1]")))
    );

    struct cc_data tmp = {};
    struct cc_data* tmp_data = &tmp;

    while (has_changed(data->update1)) {
        CC_Step(data, new_data);
        
        tmp_data = data;
        data = new_data;
        new_data = tmp_data;
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
    finch_exec("println(%s.lvl.lvl.lvl.val)", edges);
    
    printf("Loaded edges\n");
}

void starter() {
    N = 1;

    make_weights_and_edges("starter.mtx", N);

    struct cc_data d = {};
    struct cc_data* data = &d;
    CC(data);

    printf("Ran starter\n");
}

void setup1() {
    // 1 5, 4 5, 3 4, 2 3, 1 2
    //jl_value_t* edge_vector = finch_eval("Int64[0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]");
    N = 5;
    
    make_weights_and_edges("dag5.mtx", N);

    struct cc_data d = {};
    struct cc_data* data = &d;
    CC(data);

    printf("EXAMPLE1 : \n");
    finch_exec("println(%s.lvl.lvl.val)", data->IDs);
}

void setup2() {
    // 2 1, 3 1, 3 2, 3 4
    N = 4;
   
    make_weights_and_edges("dag4.mtx", N);

    struct cc_data d = {};
    struct cc_data* data = &d;
    CC(data);

    printf("EXAMPLE2 : \n");
    finch_exec("println(%s.lvl.lvl.val)", data->IDs);
}

void setup3() {
    // 2 1, 3 1, 1 2, 3 2, 1 3
    // jl_value_t* edge_vector = finch_eval("Int64[0, 1, 1, 1, 0, 0, 1, 1, 0]");
    N = 3;
    
    make_weights_and_edges("dag3.mtx", N);

    struct cc_data d = {};
    struct cc_data* data = &d;
    CC(data);

    printf("EXAMPLE3 : \n");
    finch_exec("println(%s.lvl.lvl.val)", data->IDs);
}

void setup4() {
    // 2 3, 3 1, 4 3, 5 4, 6 5, 6 7, 7 5, 7 6
    // jl_value_t* edge_vector = finch_eval("Int64[0,0,0,0,0,0,0, 0,0,1,0,0,0,0, 1,0,0,0,0,0,0, 0,0,1,0,0,0,0, 0,0,0,1,0,0,0, 0,0,0,0,1,0,1, 0,0,0,0,1,1,0]");
    N = 7;
    
    make_weights_and_edges("dag7.mtx", N);

    struct cc_data d = {};
    struct cc_data* data = &d;
    CC(data);

    printf("EXAMPLE4 : \n");
    finch_exec("println(%s.lvl.lvl.val)", data->IDs);
}

void setup5() {
    N = 4847571;
    
    make_weights_and_edges("soc-LiveJournal1.mtx", N);

    struct cc_data d = {};
    struct cc_data* data = &d;
    CC(data);

    printf("LARGE GRAPH : \n");
    finch_exec("println(%s.lvl.lvl.val)", data->IDs);
}

int main(int argc, char** argv) {

    finch_initialize();

    jl_value_t* res = finch_eval("using RewriteTools\n\
    using Finch.IndexNotation\n\
    using SparseArrays\n\
     using MatrixMarket\n\
    ");

    compile();

    starter();

    setup1();

    setup2();

    setup3();

    setup4();

    // setup5();

    finch_finalize();
}