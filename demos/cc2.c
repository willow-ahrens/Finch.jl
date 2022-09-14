// element Vertex end
// element Edge end

// const edges : edgeset{Edge}(Vertex,Vertex) = load (argv[1]);

// const vertices : vertexset{Vertex} = edges.getVertices();
// const IDs : vector{Vertex}(int) = 1;

// const update: vector[2](int);


old_ID[j] = a => new_IDs[a] = min(old_IDs[a], ol)
new_IDs[old_IDs[j]] = min(old_IDs[j], old_IDs[old_IDs[i]]), where there is edge from i to j
new_IDs[old_IDs[i]] = min(old_IDs[i], old_IDs[old_IDs[j]])
update[1] = old_IDs[old_IDs[j]] != new_IDs[old_IDs[j]] || old_IDs[old_IDs[i]] != new_IDs[old_IDs[i]]
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

// func init(v : Vertex)
//      IDs[v] = v;
// end

update[0] = 0
IDs[i] = (new_IDs[new_IDs[i]] != new_IDs[i]) * new_IDs[new_IDs[i]] + (new_IDs[new_IDs[i]] == new_IDs[i]) * new_IDs[i]
update[0] = new_IDs[new_IDs[i]] != new_IDs[i] | i:(OR, 0)
// func pjump(v: Vertex) 
//     var y: Vertex = IDs[v];
//     var x: Vertex = IDs[y];
//     if x != y
//         IDs[v] = x;
//         update[0] = 1;
//     end
// end

old_update[1] = 0;
UpdateEdge(old_IDs, old_update, new_IDs, new_update)
new_update[0] = 1
final_IDs, final_update = UpdateVertices*(new_IDs, new_update) | (#2[0] == 0)
// func main()
//     var n : int = edges.getVertices();
//     for trial in 0:10
//         startTimer();
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
//         var elapsed_time : float = stopTimer();
//         print "elapsed time: ";
//         print elapsed_time;
//     end
// end
id, up = InnerLoop(IDs, update) | (#2[1] == 0)

// while (#2[1] != 0) {

}


// N int

// edges int[N][N]


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

    jl_value_t* update;
};

// Let Init() -> (IDs int[N], update int)
//     IDs[i] = i
//     update = 1
// End

// func init(v : Vertex)
//      IDs[v] = v;
// end
void Init(struct cc_data* data) {
    jl_function_t* ids_init = finch_eval("function ids_init(ids)\n\
    @finch @loop i ids[i] = i\n\
end");

    jl_value_t* ids = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(ids_init, ids);

    printf("IDs: \n");
    finch_exec("println(%s)", ids);

    jl_function_t* update_init = finch_eval("function update_init(update)\n\
        @finch @loop i update[i] = 1\n\
    end");
    jl_value_t* update = finch_Fiber(
        finch_Solid(finch_Cint(2),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(update_init, update);

    printf("Update: \n");
    finch_exec("println(%s)", update);

    data->IDs = ids;
    data->update = update;
}


new_IDs[old_IDs[j]] = min(old_IDs[old_IDs[j]], old_IDs[old_IDs[i]]), where there is edge from i to j  => loop a, b: new_IDs[a]= min(old_IDs[a], old_IDs[b])
new_IDs[old_IDs[i]] = min(old_IDs[i], old_IDs[old_IDs[j]])
update[1] = old_IDs[old_IDs[j]] != new_IDs[old_IDs[j]] || old_IDs[old_IDs[i]] != new_IDs[old_IDs[i]]
// func updateEdge(src : Vertex, dst : Vertex)
//     var src_id: Vertex = IDs[src];   1 ---> 2 => src_id = 1; dst_id = 2 => IDs[2] = IDs[1] = 1
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
void UpdateEdges(struct cc_data* in_data, struct cc_data* out_data) {
    jl_function_t* ids_func = finch_eval("function ids_func(old_ids, new_ids)\n\
    val = typemax(Cint)\n\
    B = Finch.Fiber(\n\
        Dense(N,\n\
            Element{val, Cint}([])\n\
        )\n\
    )\n\
    \n\
    @finch @loop i B[i] <<min>>= edges[j,i] * old_ids[j] + (1 - edges[j,i]) * old_ids[i]\n\
    @finch @loop i new_ids[i] = min(B[i], old_ids[i])\n\
end");
    jl_value_t* new_ids = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(forward_func, in_data->IDs, new_ids);
    printf("Forward IDs: \n");
    finch_exec("println(%s)", new_ids);

    out_data->IDs = new_ids;
    out_data->update = in_data->update;
}



// Let Backward(old_ids int[N]) -> (new_ids int[N])
//     new_ids[j] = edges[j][i] * old_ids[i] + (1 - edges[j][i]) * old_ids[j] | i : (MIN, old_ids[j])
// End
void Backward(struct cc_data* in_data, struct cc_data* out_data) {
    jl_function_t* backward_func = finch_eval("function backward(old_ids, new_ids)\n\
    val = typemax(Cint)\n\
    B = Finch.Fiber(\n\
        Dense(N,\n\
            Element{val, Cint}([])\n\
        )\n\
    )\n\
    \n\
    @finch @loop j B[j] <<min>>= edges[j,i] * old_ids[i] + (1 - edges[j,i]) * old_ids[j]\n\
    @finch @loop j new_ids[j] = min(B[j], old_ids[j])\n\
end");
    jl_value_t* new_ids = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(backward_func, in_data->IDs, new_ids);
    printf("Backward IDs: \n");
    finch_exec("println(%s)", new_ids);

    out_data->IDs = new_ids;
    out_data->update = in_data->update;
}



// Let UpdateEdges(old_ids int[N], old_update int) -> (new_ids int[N], new_update int)
//     forward_ids = Forward(old_ids)
//     new_ids = Backward(forward_ids)

//     new_update = (old_ids[i] != new_ids[i]) | i : (OR, 0)
// End
void UpdateEdges(struct cc_data* in_data, struct cc_data* out_data) {
    struct cc_data d = {};
    struct cc_data* inter_data = &d;

    Forward(in_data, inter_data);
    Backward(inter_data, out_data);

    jl_function_t* update_edge_func = finch_eval("function r_func(old_ids, new_ids, new_update)\n\
    @finch @loop i  new_update <<$or>>= (old_ids[i] != new_ids[i])\n\
end");
    jl_value_t* update = finch_Fiber(
            finch_Solid(finch_Cint(1),
            finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(update_edge_func, in_data->IDs, out_data->IDs, update);

    out_data->update = update;

    printf("New Update: \n");
    finch_exec("println(%s)", out_data->update);
}

int has_changed(jl_value_t* update_arr) {
    jl_value_t *update_val = finch_exec("%s.lvl.lvl.val", update_arr);
    double *update_data = jl_array_data(update_val);
    return update_data[0];
}

// Let CC() -> (ids int[N], update int, dummy int[N], new_ids int[N], new_update int)
//     ids, update = Init()
//     dummy[i] = 0

//     new_ids, new_update = UpdateEdges*(ids, update) | (#2 == 0)
// End
void CC(struct cc_data* data) {
    Init(data);

    struct cc_data new_data = {};

    while (has_changed(data->update)) {
        UpdateEdges(data, &new_data);
        data = &new_data;
    }
}

int main(int argc, char** argv) {

    finch_initialize();

    jl_value_t* res = finch_eval("using RewriteTools\n\
    using Finch.IndexNotation\n");

    res = finch_eval("or(x,y) = x == 1|| y == 1\n");

    res = finch_eval("@slots a b c d e i j Finch.add_rules!([\n\
    (@rule @f(@chunk $i a (b[j...] <<min>>= $d)) => if Finch.isliteral(d) && i ∉ j\n\
        @f (b[j...] <<min>>= $d)\n\
    end),\n\
    (@rule @f(@chunk $i a @multi b... (c[j...] <<min>>= $d) e...) => begin\n\
        if Finch.isliteral(d) && i ∉ j\n\
            @f @multi (c[j...] <<min>>= $d) @chunk $i a @f(@multi b... e...)\n\
        end\n\
    end),\n\
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

    // 1 5, 4 5, 3 4, 2 3, 1 2
    // jl_value_t* edge_vector = finch_eval("Cint[0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]");
    // N = 5;
    // source = 5;

    // 2 1, 3 1, 3 2, 1 3, 3 4
    jl_value_t* edge_vector = finch_eval("Cint[0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0]");
    N = 4;

    // 2 1, 3 1, 1 2, 3 2, 1 3
    // jl_value_t* edge_vector = finch_eval("Cint[0, 1, 1, 1, 0, 0, 1, 1, 0]");
    // N = 3;


    edges = finch_Fiber(
        finch_Solid(finch_Cint(N),
                finch_Solid(finch_Cint(N),
                    finch_ElementLevel(finch_Cint(0), edge_vector)
                )
            )
        );

    struct cc_data d = {};
    struct cc_data* data = &d;
    CC(data);

    printf("Final IDs: \n");
    finch_exec("println(%s)", data->IDs);

    finch_finalize();
}