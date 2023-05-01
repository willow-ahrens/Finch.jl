# # # Apps Documentation

# Page rank documentation

function pagerank(edges; nsteps=20, damp = 0.85)
    (n, m) = size(edges)
    @assert n == m
    @finch begin
        scaled_edges .= 0
        for j = _, i = _
            if out_degree[i] != 0
                scaled_edges[i, j] = edges[i, j] / out_degree[j]
            end
        end
    end
    r = @fiber d(e(0.0), n)
    @finch (r .= 0; @loop j r[j] = 1.0/n)
    rank = @fiber d(e(0.0), n)
    beta_score = (1 - damp)/n

    for step = 1:nsteps
        @finch (rank .= 0; @loop j i rank[i] += scaled_edges[i, j] * r[j])
        @finch (r .= 0; @loop i r[i] = beta_score + damp * rank[i])
    end
    return r
end

# Bfs documentation

function bfs(edges, source=5)
    (n, m) = size(edges)
    edges = pattern!(edges)

# SparseBitMaps allow random access?? (CHECK THIS)
    @assert n == m
    F = @fiber sbm(p(), n)
    _F = @fiber sbm(p(), n)
    @finch F[source] = true

    V = @fiber d(e(false), n)
    @finch V[source] = true

    P = @fiber d(e(0), n)
    @finch P[source] = source

    v = Scalar(false)

# countstored outputs the number of nonzeros in the array
    while countstored(F) > 0
        @finch begin
            _F .= false
            @loop j k begin
                v .= false
                v[] = F[j] && edges[k, j] && !(V[k])
                if v[]
                    _F[k] |= true
                    P[k] <<choose(0)>>= j #Only set the parent for this vertex
                end
            end
        end
        @finch @loop k V[k] |= _F[k]
        (F, _F) = (_F, F)
    end
    return P
end

# # Bellman-Ford Shortest Paths
# The following function computes SSSP (single-source shortest paths) using the Bellman-Ford algorithm.
# The shortest paths are represented as tuples (distance, parent node). If a negative weight cycle is found, the function returns -1. 
# Note, we require diagonals = inf to avoid self-loops in the paths.

function bellmanford(edges, source=1)
    (n, m) = size(edges)
    @assert n == m

# At the start, we set all distances to infinity except for the source, which has distance 0. 
# We also set our modified counter to false to indicate if updates occur during each iteration.
    init_dists = [(Inf, -1) for i=1:n]
    init_dists[source] = (0.0, -1)
    dists_prev = @fiber(d(e((Inf, -1))), init_dists)
    dists_next = @fiber(d(e((Inf, -1)), n))
    modified = Scalar(false)

# At each iteration, we simulate another step along each edge. From each node, we traverse an additional edge to reach each neighbor 
# and check if this results in a shorter path than the current best path. We use the `min` function to accumulate the minimum value over all these paths.
    for iter = 1:n
        @finch @loop j dists_next[j] = dists_prev[j]
        @finch @loop j i dists_next[j] <<min>>= (first(dists_prev[i]) + edges[i, j], i) 
        dists_prev, dists_next = dists_next, dists_prev
# The first loop updates `dists_next` to the current best solutions. In the case where none of the new paths result in a shorter distance, 
# `min` will return the previous path. 


# We compare our updated distances with the previous distances. If no updates are made, we can return immediately. 
# Since multiple shortest paths may exist, only distances are compared.
        modified = Scalar(false)
        @finch @loop i modified[] |= dists_next[i][1] != dists_prev[i][1]
        if !modified[]
            break
        end
    end

# If we fail to converge to shortest paths within n iterations, we know that there must exist a negative weight cycle. 
# Otherwise, the longest possible path is (n-1) vertices and we would have found it in (n-1) iterations, each of which simulate an additional step. 
    return modified[] ? -1 : dists_prev
end


# # Triangle counter
# The following function computes the number of triangles (sets of 3 nodes that are all connected) of an undirected, unweighted graph.
function tricount(edges)
    (n, m) = size(edges)
    @assert n == m

    # Since the graph is undirected, it is symmetric and we can mask the adjacency matrix to get the lower triangle part, `L`
    # `L` represents all edges connecting from a lower indexed node to a higher indexed node.
    L = @fiber d(sl(e(0), n), n)
    @finch begin
        L .= 0
        @loop j begin
            @loop i L[i,j] = lotrimask[i,j+1] * edges[i,j]
        end
    end

    # L[i,k] stores the number of ways to get from node i to node k in one step (either 1 or 0). By multiplying L[i,k] * L[k,j], 
    # looping over k, we get the number of ways to get from i to j in 2 steps. Thus, the matrix multiplication L[i,k] * L[k,j] counts the number of wedges
    # (i.e. paths of length 2) in the graph. Finally, we mask by L[i,j] the check that an edge connected i and j to complete the triangle, 
    # and we can sum all of these triangles to get our result.
    triangles = Scalar(0)
    @finch @loop j k i triangles[] +=  L[i, k] * L[k, j] * L[i, j]

    return triangles[]
end