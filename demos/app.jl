using Finch
using Finch.IndexNotation
using Finch: execute_code_lowered
using RewriteTools
using BenchmarkTools
using SparseArrays
using LinearAlgebra

@slots a b c d e i j Finch.add_rules!([
    (@rule @i(@chunk $i a (b[j...] <<min>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @i (b[j...] <<min>>= $d)
    end),
    (@rule @i(@chunk $i a @multi b... (c[j...] <<min>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @i @multi (c[j...] <<min>>= $d) @chunk $i a @i(@multi b... e...)
        end
    end),
])

Finch.register()

# @index @loop p j priorityQ[p, j] += (&) ((==) (p, 1), ((==) (j, source))) + (&) ((==) (p, P), (!=) (j, source))
function pq_init(source, P, priorityQ)
    @index @loop p j priorityQ[p, j] = (p == 1 && j == $source) + (p == $P && j != $source)
end

# dist[j] = (j != source) * P
function dist_init(source, P, dist)
    @index @loop j dist[j] = (j != $source) * ($P - 1)
end

# new_dist[j] = edges[j][k] * priorityQ[priority][k] * (weights[j][k] + dist[k]) + (edges[j][k] * priorityQ[priority][k] == 0) * P | k:(MIN, dist[j])
function new_dist_func(priority, N, P, new_dist, edges, priorityQ, weights, dist)
    val = typemax(Cint)
    B = Finch.Fiber(
        Solid(N,
            Element{val, Cint}([])
        )
    )
    
    @index @loop p j k B[j] <<min>>= (p == $priority) * (edges[j, k] * priorityQ[p, k] * (weights[j, k] + dist[k]) + (edges[j, k] * priorityQ[p, k] == 0) * ($P-1)) + (p != $priority) * $val
    @index @loop j new_dist[j] = min(B[j], dist[j])
end

# new_priorityQ[j][k] = (dist[k] > new_dist[k]) * (j <= new_dist[k] &&  new_dist[k] < j + 1) + (dist[k] == new_dist[k] && j != priority) * priorityQ[j][k]
function new_pq_func(new_priorityQ, old_priorityQ, dist, new_dist, priority) 
    # @index @loop j k new_priorityQ[j, k] = old_priorityQ[j, k] + ((dist[k] > new_dist[k]) * (new_dist[k] == j-1) - (dist[k] > new_dist[k]) * (dist[k] == j-1))
    @index @loop j k new_priorityQ[j, k] = (dist[k] > new_dist[k]) * (new_dist[k] == j-1) + (dist[k] == new_dist[k] && j != $priority) * old_priorityQ[j, k]
end

function access_func(tensor1D, tensor2D, index)
    @index @loop i j tensor1D[j] += tensor2D[i, j] * (i == $index)
end

function add_vec()

    P = 5;
    N = 5;
    source = 5;

    #  1 5, 4 5, 3 4, 2 3, 1 2
    edge_vector = Cint[0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]
    edges = Finch.Fiber(
        Solid(N,
                Solid(N,
                    Element{0, Cint}(edge_vector)
                )
            )
        )
    
    edge_slice = Finch.Fiber(
        Solid(N,
        Element{0, Cint}([]))
    );
    access_func(edge_slice, edges, 1);
    println(edge_slice.lvl.lvl.val);

    access_func(edge_slice, edges, 3);
    println(edge_slice.lvl.lvl.val);

    weight_vector = Cint[0, 1, 0, 0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]
    weights = Finch.Fiber(
        Solid(N,
                Solid(N,
                    Element{0, Cint}(weight_vector)
                )
            )
        )

    priorityQ = Finch.Fiber(
        Solid(P,
        # HollowList(N, Vector{Int64}(), [1, 1, 1, 1, 1, 1],
        # Element{0.0, Int64}([])))
            Solid(N, Element{0, Cint}([]))
        )
        );
    pq_init(source, P, priorityQ);
    println(priorityQ.lvl.lvl.lvl.val);

    dist = Finch.Fiber(
        Solid(N,
        Element{0, Cint}([]))
    );
    dist_init(source, P, dist);
    println("Dist: \n")
    println(dist.lvl.lvl.val);

    new_dist = Finch.Fiber(
        Solid(N,
        Element{0, Cint}([])
        )
    )
    new_dist_func(1, N, P, new_dist, edges, priorityQ, weights, dist)
    println("New dist: \n")
    println(new_dist.lvl.lvl.val)

    new_priorityQ = Finch.Fiber(
        Solid(P,
            Solid(N, Element{0, Cint}([]))
        )
        );
    new_pq_func(new_priorityQ, priorityQ, dist, new_dist, 1)
    println("New priorityQ: \n")
    println(new_priorityQ.lvl.lvl.lvl.val)
end

add_vec();