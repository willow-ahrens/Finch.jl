using Finch
using Finch.IndexNotation
using RewriteTools
using BenchmarkTools
using SparseArrays
using LinearAlgebra

or(x,y) = x == 1|| y == 1

function choose(x, y)
    if x != 0
        return x
    else
        return y
    end
end

@slots a b c d e i j Finch.add_rules!([
    (@rule @f(@chunk $i a (b[j...] <<min>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<min>>= $d)
    end),
    (@rule @f(@chunk $i a @multi b... (c[j...] <<min>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @f @multi (c[j...] <<min>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),

    (@rule @f(@chunk $i a (b[j...] <<$or>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<$or>>= $d)
    end),

    (@rule @f(@chunk $i a @multi b... (c[j...] <<$or>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @f @multi (c[j...] <<$or>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),
])

Finch.register()

function IDs_init(ID)
    @finch @loop i ID[i] = i
end

function forward(edges, old_ids, new_ids, N)
    val = typemax(Cint)
    B = Finch.Fiber(
        Dense(N,
            Element{val, Cint}([])
        )
    )
    @finch @loop j i B[i] <<min>>= edges[j,i] * old_ids[j] + (1 - edges[j,i]) * old_ids[i]
    @finch @loop i new_ids[i] = min(B[i], old_ids[i])
end

function main()
    N = 4
    edge_vector = Cint[0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0]
    edges = Finch.Fiber(
        Dense(N,
                Dense(N,
                    Element{0, Cint}(edge_vector)
                )
            )
    )
    println("Edges:")
    println(edges.lvl.lvl.lvl.val)

    ID = Finch.Fiber(
        Dense(N,
            Element{0, Cint}([])
        )
    )
    IDs_init(ID);
    println("IDs:");
    println(ID.lvl.lvl.val);

    new_ID = Finch.Fiber(
        Dense(N,
            Element{0, Cint}([])
        )
    )
    forward(edges, ID, new_ID, N)
    println("New IDs: ")
    println(new_IDs.lvl.lvl.va)

end

main()