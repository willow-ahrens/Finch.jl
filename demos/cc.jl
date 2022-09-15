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

function edge_update(edges, N, old_ids, new_ids, new_update1)
    val = typemax(Cint)
    B = Finch.Fiber(
        Dense(N,
            Element{val, Cint}([])
        )
    )
    valid =  Finch.Fiber(
        Dense(N,
                Dense(N,
                    Dense(N,
                            Dense(N,
                            Element{val, Cint}([]) 
                        )
                    ) 
            )
        )
    )
    
    # old_ids[j] = a
    # old_ids[i] = b
    @finch @loop j i a b valid[a,b,i,j] = (old_ids[j] == a) * (old_ids[i] == b) * (edges[j,i] == 1|| edges[i,j] == 1)
    @finch @loop a b i j B[a] <<min>>= valid[a,b,i,j] * old_ids[b] + (1-valid[a,b,i,j]) * ($N+1)
    @finch @loop i new_ids[i] = min(B[i],old_ids[i])
    @finch @loop i j a b new_update1[] <<$or>>= (old_ids[a] != new_ids[a] || old_ids[b] != new_ids[b]) * valid[a,b,i,j]
end

function vertex_update(old_ids, new_ids, new_update0)
    @finch @loop i a begin
        new_ids[i] += (old_ids[i] == a) * ( (old_ids[a] != a) * old_ids[a] + (old_ids[a] == a) * a)
        new_update0[] <<$or>>= (old_ids[i] == a) * (old_ids[a] != a)
    end
end

function test(old_ids, new_ids)
    @finch @loop i new_ids[old_ids[i]] = i
end

function main()
    # N = 4
    # ID = Finch.Fiber(
    #     Dense(N,
    #         Element{0, Cint}([])
    #     )
    # )
    # IDs_init(ID);
    # println("IDs:");
    # println(ID.lvl.lvl.val);

    # new_ID = Finch.Fiber(
    #     Dense(N,
    #         Element{0, Cint}([])
    #     )
    # )
    # test(ID, new_ID)
    # println("New IDs: ")
    # println(new_IDs.lvl.lvl.va)

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
    update = Scalar{0}()
    edge_update(edges, N, ID, new_ID, update)

    println("New IDs: ")
    println(new_ID.lvl.lvl.val)

    final_ID = Finch.Fiber(
        Dense(N,
            Element{0, Cint}([])
        )
    )

    new_update0 = Scalar{0}()
    vertex_update(new_ID, final_ID, new_update0)
    println("Final IDs: ")
    println(final_ID.lvl.lvl.val)

end

main()