"""
    pagerank(adj; [nsteps], [damp])

Calculate `nsteps` steps of the page rank algorithm on the graph specified by
the adjacency matrix `adj`. `damp` is the damping factor.
"""
function pagerank(edges; nsteps=20, damp = 0.85)
    (n, m) = size(edges)
    @assert n == m
    out_degree = Fiber!(Dense(Element(0)))
    @finch (out_degree .= 0; @loop j i out_degree[j] += edges[i, j])
    scaled_edges = Fiber!(Dense(SparseList(Element(0.0))))
    @finch begin
        scaled_edges .= 0
        for j = _, i = _
            if out_degree[i] != 0
                scaled_edges[i, j] = edges[i, j] / out_degree[j]
            end
        end
    end
    r = Fiber!(Dense(Element(0.0), n))
    @finch (r .= 0.0; @loop j r[j] = 1.0/n)
    rank = Fiber!(Dense(Element(0.0), n))
    beta_score = (1 - damp)/n

    for step = 1:nsteps
        @finch (rank .= 0; @loop j i rank[i] += scaled_edges[i, j] * r[j])
        @finch (r .= 0.0; @loop i r[i] = beta_score + damp * rank[i])
    end
    return r
end

"""
    bfs(edges; [source])

Calculate a breadth-first search on the graph specified by the `edges` adjacency
matrix. Return the node numbering.
"""
function bfs(edges, source=5)
    (n, m) = size(edges)
    edges = pattern!(edges)

    @assert n == m
    F = Fiber!(SparseByteMap(Pattern(), n))
    _F = Fiber!(SparseByteMap(Pattern(), n))
    @finch F[source] = true

    V = Fiber!(Dense(Element(false), n))
    @finch V[source] = true

    P = Fiber!(Dense(Element(0), n))
    @finch P[source] = source

    v = Scalar(false)

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


"""
    bellmanford(adj, source=1)

Calculate the shortest paths from the vertex `source` in the graph specified by
an adjacency matrix `adj`, whose entries are edge weights. Weights should be
infinite when unconnected.

The output is given as a vector of distance, parent pairs for each node in the graph.
"""
function bellmanford(edges, source=1)
    (n, m) = size(edges)
    @assert n == m

    dists_prev = Fiber!(Dense(Element((Inf, 0)), n))
    dists_prev[source] = (0.0, 0)
    dists = Fiber!(Dense(Element((Inf, 0)), n))
    active_prev = Fiber!(SparseByteMap(Pattern(), n))
    active_prev[source] = true
    active = Fiber!(SparseByteMap(Pattern(), n))
    d = Scalar(0.0)

    for iter = 1:n  
        @finch @loop j if active_prev[j] dists[j] <<minby>>= dists_prev[j] end

        @finch begin
            active .= false
            for j = _
                if active_prev[j]
                    for i = _
                        d .= 0
                        d[] = first(dists_prev[j]) + edges[i, j]
                        dists[i] <<minby>>= (d[], j)
                        active[i] |= d[] < first(dists_prev[i])
                    end
                end
            end
        end

        if !any(active)
            return dists
        end
        dists_prev, dists = dists, dists_prev
        active_prev, active = active, active_prev
    end

    return dists_prev
end

"""
    tricount(adj)

Count the number of triangles in the graph specified by `adj`, which is assumed to be
symmetric. Requires edges to be 1 and non-edges 0.
"""
function tricount(edges)
    (n, m) = size(edges)
    @assert n == m

    #store lower triangles
    L = Fiber!(Dense(SparseList(Element(0), n), n))
    @finch begin
        L .= 0
        @loop j begin
            @loop i L[i,j] = lotrimask[i,j+1] * edges[i,j]
        end
    end

    triangles = Scalar(0)
    @finch @loop j k i triangles[] += L[i, k] * L[k, j] * edges[j, i]

    return triangles[]
end
