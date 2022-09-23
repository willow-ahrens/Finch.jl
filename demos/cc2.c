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

struct cc_data {
    jl_value_t* IDs;

    jl_value_t* update0;

    jl_value_t* update1;
};

// Let Init() -> (IDs int[N], update0 int, update1 int)
//     IDs[i] = i
//     update0 = 1
//     update1 = 1
// End

// func init(v : Vertex)
//      IDs[v] = v;
// end
void Init(struct cc_data* data) {
    jl_function_t* ids_init = finch_eval("function ids_init(ids)\n\
    @finch @loop i ids[i] = i\n\
end");

    jl_value_t* ids = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(ids_init, ids);

    printf("IDs: \n");
    finch_exec("println(%s.lvl.lvl.val)", ids);

    jl_value_t* up0 = finch_Fiber(
        finch_Dense(finch_Cint(1),
        finch_ElementLevel(finch_Cint(1), finch_eval("Cint[1]")))
    );
        //finch_Scalar(finch_Cint(1));
    jl_value_t* up1 = finch_Fiber(
        finch_Dense(finch_Cint(1),
        finch_ElementLevel(finch_Cint(1), finch_eval("Cint[1]")))
    );//finch_Scalar(finch_Cint(1));

    printf("Update: \n");
    finch_exec("println(%s)", up0);
    finch_exec("println(%s)", up1);

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
    jl_function_t* edge_update = finch_eval("function edge_update(edges, N, old_ids, new_ids, new_update1)\n\
    val = typemax(Cint)\n\
    B = Finch.Fiber(\n\
        Dense(N,\n\
            Element{val, Cint}([])\n\
        )\n\
    )\n\
    \n\
    @finch @loop j i a b B[a] <<min>>= old_ids[b] * ((edges[j,i] == 1|| edges[i,j] == 1) && old_ids[j] == a && old_ids[i] == b) + ((edges[j,i] == 0 && edges[i,j] == 0) || old_ids[j] != a || old_ids[i] != b) * ($N + 1)\n\
    println(B.lvl.lvl.val)\n\
    @finch @loop i new_ids[i] = min(B[i],old_ids[i])\n\
    # @finch @loop i j new_update1[] <<$or>>= (old_ids[old_ids[j]] != new_ids[old_ids[j]] || old_ids[old_ids[i]] != new_ids[old_ids[i]]) * (edges[j,i] == 1 || edges[i,j] == 1)\n\
    C = Finch.Fiber(\n\
        Dense(N,\n\
            Element{0, Cint}([])\n\
        )\n\
    )\n\
    @finch @loop i C[i] <<$or>>= old_ids[old_ids[i]] != new_ids[old_ids[i]]\n\
    println(C.lvl.lvl.val)\n\
    @finch @loop j i new_update1[j] <<$or>>= C[i]\n\
    println(new_update1)\n\
end");
    jl_value_t* new_ids = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    jl_value_t* new_update1 = finch_Fiber(
        finch_Dense(finch_Cint(1),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );//finch_Scalar(finch_Cint(0));
    printf("old IDs: \n");
    finch_exec("println(%s.lvl.lvl.val)", in_data->IDs);
    finch_call(edge_update, edges, finch_Cint(N), in_data->IDs, new_ids, new_update1);

    printf("New IDs: \n");
    finch_exec("println(%s.lvl.lvl.val)", new_ids);

    printf("New update 1: \n");
    finch_exec("println(%s.lvl.lvl.val)", new_update1);

    out_data->IDs = new_ids;
    out_data->update0 = in_data->update0;
    out_data->update1 = new_update1;
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
    jl_function_t* vertex_update = finch_eval("function vertex_update(old_ids, new_ids, new_update0)\n\
    @finch @loop i j begin\n\
        new_ids[i] = old_ids[old_ids[i]]\n\
        new_update0[j] <<$or>>= (old_ids[old_ids[i]] != old_ids[i])\n\
    end\n\
end");
    jl_value_t* new_ids = finch_Fiber(
        finch_Dense(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    jl_value_t* new_update0 = finch_Fiber(
        finch_Dense(finch_Cint(1),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );//finch_Scalar(finch_Cint(0));
    finch_call(vertex_update, in_data->IDs, new_ids, new_update0);

    printf("New IDs: \n");
    finch_exec("println(%s.lvl.lvl.val)", new_ids);
    printf("New update 0: \n");
    finch_exec("println(%s.lvl.lvl.val)", new_update0);

    out_data->IDs = new_ids;
    out_data->update0 = new_update0;
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
    UpdateEdges(in_data, out_data);

    struct cc_data final_data = {};

    // set out_data->update[0] on 1
    out_data->update0 = finch_Fiber(
        finch_Dense(finch_Cint(1),
        finch_ElementLevel(finch_Cint(1), finch_eval("Cint[1]")))
    );//finch_Scalar(finch_Cint(1));

    while (has_changed(out_data->update0)) {
        UpdateVertices(out_data, &final_data);
        *out_data = final_data;
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

    struct cc_data new_data = {};

     while (has_changed(data->update1)) {
        CC_Step(data, &new_data);
        *data = new_data;
    }
}


void setup1() {
    // 1 5, 4 5, 3 4, 2 3, 1 2
    //jl_value_t* edge_vector = finch_eval("Cint[0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]");
    N = 5;
    edges = finch_eval("N = 5\n\
        edge_matrix = sparse([0 0 0 0 0; 1 0 0 0 0; 0 1 0 0 0; 0 0 1 0 0; 1 0 0 1 0])\n\
        Finch.Fiber(\n\
                 Dense(N,\n\
                 SparseList(N, edge_matrix.colptr, edge_matrix.rowval,\n\
                 Element{0.0}(edge_matrix.nzval))))");
    struct cc_data d = {};
    struct cc_data* data = &d;
    CC(data);

    printf("EXAMPLE1\nFinal: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->IDs);
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
    struct cc_data d = {};
    struct cc_data* data = &d;
    CC(data);

    printf("EXAMPLE2\nFinal: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->IDs);
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
    struct cc_data d = {};
    struct cc_data* data = &d;
    CC(data);

    printf("EXAMPLE3\nFinal: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->IDs);
}

void setup4() {
    // 2 3, 3 1, 4 3, 5 4, 6 5, 6 7, 7 5, 7 6
    // jl_value_t* edge_vector = finch_eval("Cint[0,0,0,0,0,0,0, 0,0,1,0,0,0,0, 1,0,0,0,0,0,0, 0,0,1,0,0,0,0, 0,0,0,1,0,0,0, 0,0,0,0,1,0,1, 0,0,0,0,1,1,0]");
    N = 7;
    edges = finch_eval("N = 7\n\
    edge_matrix = sparse([0 0 1 0 0 0 0; 0 0 0 0 0 0 0; 0 1 0 1 0 0 0; 0 0 0 0 1 0 0; 0 0 0 0 0 1 1; 0 0 0 0 0 0 1; 0 0 0 0 0 1 0])\n\
    Finch.Fiber(\n\
                Dense(N,\n\
                SparseList(N, edge_matrix.colptr, edge_matrix.rowval,\n\
                Element{0.0}(edge_matrix.nzval))))");
    struct cc_data d = {};
    struct cc_data* data = &d;
    CC(data);

    printf("EXAMPLE4\n Final: \n");
    finch_exec("println(%s.lvl.lvl.val)", data->IDs);
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