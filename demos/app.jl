using Finch
using Finch.IndexNotation
using BenchmarkTools
using SparseArrays
using LinearAlgebra

# @index @loop p j priorityQ[p, j] += (&) ((==) (p, 1), ((==) (j, source))) + (&) ((==) (p, P), (!=) (j, source))
function pq_init(source, P, priorityQ)
    # p = Name(:p)
    # j = Name(:j)
    @index @loop p j priorityQ[p, j] = (p == 1 && j == $source) + (p == $P && j != $source)
end

# dist[j] = (j != source) * P
function dist_init(source, P, dist)
    # j = Name(:j)
    @index @loop j dist[j] = (j != $source) * $P
end

function add_vec()

    P = 5;
    N = 5;
    source = 5;

    priorityQ = Finch.Fiber(
        Solid(P,
        # HollowList(N, Vector{Int64}(), [1, 1, 1, 1, 1, 1],
        # Element{0.0, Int64}([])))
            Solid(N, Element{0, Int64}([]))
        )
        );
    pq_init(source, P, priorityQ);
    println(priorityQ.lvl.lvl.lvl.val);

    dist = Finch.Fiber(
        Solid(N,
        Element{0, Int64}([]))
    );
    dist_init(source, P, dist);
    println(dist.lvl.lvl.val);
end

add_vec();