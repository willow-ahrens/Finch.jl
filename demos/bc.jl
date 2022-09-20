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
    (@rule @f(@chunk $i a (b[j...] <<min>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<min>>= $d)
    end),

    (@rule @f(@chunk $i a @multi b... (c[j...] <<min>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
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

function frontier_visit_paths(new_frontier, new_visited, new_num_paths, edges, round, frontier_list, old_visited, old_num_paths)
    @finch @loop j k begin
        new_frontier[j] <<$or>>= edges[j,k] * frontier_list[($round-1),k] * (old_visited[j] == 0)
        new_visited[j] <<$or>>= (old_visited[j] != 0) * 1 + edges[j,k] * frontier_list[($round-1),k] * (old_visited[j] == 0)
        new_num_paths[j] += edges[j,k] * frontier_list[($round-1),k] * (old_visited[j] == 0) * old_num_paths[k]
     end
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

    num_paths = Finch.Fiber(
        Dense(N,
            Element{0, Cint}([0,0,0,1])
        )
    )

    new_num_paths = Finch.Fiber(
        Dense(N,
            Element{0, Cint}([0,0,0,1])
        )
    )

    visited = Finch.Fiber(
        Dense(N,
            Element{0, Cint}([0,0,0,1])
        )
    )

    new_visited = Finch.Fiber(
        Dense(N,
            Element{0, Cint}([0,0,0,1])
        )
    )

    frontier = Finch.Fiber(
        Dense(N,
            Element{0, Cint}([0,0,0,1])
        )
    )

    frontier_list = Finch.Fiber(
        Dense(N,
            Dense(N,
            Element{0, Cint}([0,0,0,1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
            )
        )
    );

    frontier_visit_paths(frontier, new_visited, new_num_paths, edges, 2, frontier_list, visited, num_paths)
    
    println(new_num_paths.lvl.lvl.val)

end

main()