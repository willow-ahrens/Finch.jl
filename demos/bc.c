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
void Init(struct cc_data* data) {
    jl_function_t* ids_init = finch_eval("function ids_init(ids)\n\
    @index @loop i ids[i] = i\n\
end");

    jl_value_t* ids = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(ids_init, ids);

    printf("IDs: \n");
    finch_exec("println(%s)", ids);

    jl_function_t* update_init = finch_eval("function update_init(update)\n\
        @index @loop i update[i] = 1\n\
    end");
    jl_value_t* update = finch_Fiber(
        finch_Solid(finch_Cint(1),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(update_init, update);

    printf("Update: \n");
    finch_exec("println(%s)", update);

    data->IDs = ids;
    data->update = update;
}


// Let Forward(old_ids int[N]) -> (new_ids int[N])
//     new_ids[i] = edges[j][i] * old_ids[j] + (1 - edges[j][i]) * old_ids[i] | j : (MIN, old_ids[i])
// End
void Forward(struct cc_data* in_data, struct cc_data* out_data) {
    jl_function_t* forward_func = finch_eval("function forward(edges, old_ids, new_ids, N)\n\
    val = typemax(Cint)\n\
    B = Finch.Fiber(\n\
        Solid(N,\n\
            Element{val, Cint}([])\n\
        )\n\
    )\n\
    \n\
    @index @loop j i B[i] <<min>>= edges[j,i] * old_ids[j] + (1 - edges[j,i]) * old_ids[i]\n\
    @index @loop i new_ids[i] = min(B[i], old_ids[i])\n\
end");
    jl_value_t* new_ids = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(forward_func, edges, in_data->IDs, new_ids, finch_Cint(N));
    printf("Forward IDs: \n");
    finch_exec("println(%s)", new_ids);

    out_data->IDs = new_ids;
    out_data->update = in_data->update;
}



// Let Backward(old_ids int[N]) -> (new_ids int[N])
//     new_ids[j] = edges[j][i] * old_ids[i] + (1 - edges[j][i]) * old_ids[j] | i : (MIN, old_ids[j])
// End
void Backward(struct cc_data* in_data, struct cc_data* out_data) {
    jl_function_t* backward_func = finch_eval("function backward(edges, old_ids, new_ids, N)\n\
    val = typemax(Cint)\n\
    B = Finch.Fiber(\n\
        Solid(N,\n\
            Element{val, Cint}([])\n\
        )\n\
    )\n\
    \n\
    @index @loop j i B[j] <<min>>= edges[j,i] * old_ids[i] + (1 - edges[j,i]) * old_ids[j]\n\
    @index @loop j new_ids[j] = min(B[j], old_ids[j])\n\
end");
    jl_value_t* new_ids = finch_Fiber(
        finch_Solid(finch_Cint(N),
        finch_ElementLevel(finch_Cint(0), finch_eval("Cint[]")))
    );
    finch_call(backward_func, edges, in_data->IDs, new_ids, finch_Cint(N));
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
    @index @loop i j new_update[j] <<$or>>= (old_ids[i] != new_ids[i])\n\
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
    int *update_data = jl_array_data(update_val);
    return update_data[0];
}

// Let CC() -> (ids int[N], update int, dummy int[N], new_ids int[N], new_update int)
//     ids, update = Init()
//     dummy[i] = 0

//     new_ids, new_update = UpdateEdges*(ids, update) | (#2 == 0)
// End
void CC(struct cc_data* data) {
    Init(data);

    struct cc_data* old_data = data;
    struct cc_data new_data = {};
    
    while (has_changed(old_data->update)) {
        UpdateEdges(old_data, &new_data);
        old_data = &new_data;
    }

    data->IDs = new_data.IDs;
    data->update = new_data.update;
}

int main(int argc, char** argv) {

    finch_initialize();

    jl_value_t* res = finch_eval("using RewriteTools\n\
    using Finch.IndexNotation\n");

    res = finch_eval("or(x,y) = x == 1|| y == 1\n");

    res = finch_eval("@slots a b c d e i j Finch.add_rules!([\n\
    (@rule @i(@chunk $i a (b[j...] <<min>>= $d)) => if Finch.isliteral(d) && i ∉ j\n\
        @i (b[j...] <<min>>= $d)\n\
    end),\n\
    (@rule @i(@chunk $i a @multi b... (c[j...] <<min>>= $d) e...) => begin\n\
        if Finch.isliteral(d) && i ∉ j\n\
            @i @multi (c[j...] <<min>>= $d) @chunk $i a @i(@multi b... e...)\n\
        end\n\
    end),\n\
    (@rule @i(@chunk $i a (b[j...] <<$or>>= $d)) => if Finch.isliteral(d) && i ∉ j\n\
        @i (b[j...] <<$or>>= $d)\n\
    end),\n\
    (@rule @i(@chunk $i a @multi b... (c[j...] <<$or>>= $d) e...) => begin\n\
        if Finch.isliteral(d) && i ∉ j\n\
            @i @multi (c[j...] <<$or>>= $d) @chunk $i a @i(@multi b... e...)\n\
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
    // jl_value_t* edge_vector = finch_eval("Cint[0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0]");
    // N = 4;

    // 2 1, 3 1, 1 2, 3 2, 1 3
    jl_value_t* edge_vector = finch_eval("Cint[0, 1, 1, 1, 0, 0, 1, 1, 0]");
    N = 3;


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