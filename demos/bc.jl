using Finch
using Finch.IndexNotation
using Finch: execute_code_lowered
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
    (@rule @i(@chunk $i a (b[j...] <<min>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @i (b[j...] <<min>>= $d)
    end),

    (@rule @i(@chunk $i a @multi b... (c[j...] <<min>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @i @multi (c[j...] <<min>>= $d) @chunk $i a @i(@multi b... e...)
        end
    end),

    (@rule @i(@chunk $i a (b[j...] <<$or>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @i (b[j...] <<$or>>= $d)
    end),

    (@rule @i(@chunk $i a @multi b... (c[j...] <<$or>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @i @multi (c[j...] <<$or>>= $d) @chunk $i a @i(@multi b... e...)
        end
    end),
])

Finch.register()

function IDs_init(ID)
    @index @loop i ID[i] = i
end

function RevIDs_update(RevID, ID)
    @index @loop i j RevID[i] <<$or>>= j * (ID[j] == i) 
end

function updateIDs(edges, old_ID, RevID, new_ID, N)
    val = typemax(Cint)
    B = Finch.Fiber(
        Solid(N,
            Element{val, Cint}([])
        )
    )
    @index @loop a b B[a] <<min>>= old_ID[b] * (edges[RevID[a],RevID[b]] || edges[RevID[b], RevID[a]])
    @index @loop a new_ID[a] = min(old_ID[a], B[a])
end

function main()
    N = 4
    edge_vector = Cint[0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0]
    edges = Finch.Fiber(
        Solid(N,
                Solid(N,
                    Element{0, Cint}(edge_vector)
                )
            )
    )
    println("Edges:")
    println(edges.lvl.lvl.lvl.val)

    ID = Finch.Fiber(
        Solid(N,
            Element{0, Cint}([])
        )
    )
    IDs_init(ID);
    println("IDs:");
    println(ID.lvl.lvl.val);

    RevID = Finch.Fiber(
        Solid(N,
            Element{0, Cint}([])
        )
    )
    RevIDs_update(RevID, ID)
    println("RevID:")
    println(RevID.lvl.lvl.val);

    new_ID = Finch.Fiber(
        Solid(N,
            Element{0, Cint}([])
        )
    )
    updateIDs(edges, ID, RevID, new_ID, N)
    println("New IDs: ")
    println(new_IDs.lvl.lvl.va)

end

main()