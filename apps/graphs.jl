function pagerank(edges; nsteps=20, damp = 0.85)
    (n, m) = size(edges)
    @assert n == m
    out_degree = @fiber d(e(0))
    @finch (out_degree .= 0; @loop j i out_degree[j] += edges[i, j])
    scaled_edges = @fiber d(sl(e(0.0)))
    @finch begin
        scaled_edges .= 0
        for j = _, i = _
            if out_degree[i] != 0
                scaled_edges[i, j] = edges[i, j] / out_degree[j]
            end
        end
    end
    r = @fiber d(e(0.0), n)
    @finch (r .= 0.0; @loop j r[j] = 1.0/n)
    rank = @fiber d(e(0.0), n)
    beta_score = (1 - damp)/n

    for step = 1:nsteps
        @finch (rank .= 0; @loop j i rank[i] += scaled_edges[i, j] * r[j])
        @finch (r .= 0.0; @loop i r[i] = beta_score + damp * rank[i])
    end
    return r
end

function bfs(edges, source=5)
    (n, m) = size(edges)
    edges = pattern!(edges)

    @assert n == m
    F = @fiber sbm(p(), n)
    _F = @fiber sbm(p(), n)
    @finch F[source] = true

    V = @fiber d(e(false), n)
    @finch V[source] = true

    P = @fiber d(e(0), n)
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


# Inputs:
#   edges: 2D matrix of edge weights with Inf for unconnected edges
#   source: vertex to start
# Output:
#   dists: an array of tuples (d, n) where d is the shortest distance and n the parent node in the path
function bellmanford(edges, source=1)
    (n, m) = size(edges)
    @assert n == m

    dists_prev = @fiber(d(e((Inf, 0)), n))
    dists_prev[source] = (0.0, 0)
    dists = @fiber(d(e((Inf, 0)), n))
    active_prev = @fiber(sbm(p(), n))
    active_prev[source] = true
    active = @fiber(sbm(p(), n))
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

# Inputs:
#   edges: undirected adjacency matrix. Requires edges to be 1 and non-edges 0.
# Output:
#   number of triangles in graph
function tricount(edges)
    (n, m) = size(edges)
    @assert n == m

    #store lower triangles
    L = @fiber d(sl(e(0), n), n)
    @finch begin
        L .= 0
        @loop j begin
            @loop i L[i,j] = lotrimask[i,j+1] * edges[i,j]
        end
    end

    triangles = Scalar(0)
    @finch @loop j k i triangles[] +=  L[i, k] * L[k, j] * L[i, j]

    return triangles[]
end