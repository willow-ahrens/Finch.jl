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
#          or -1 if a negative weight cycle is found
function bellmanford(edges, source=1)
    (n, m) = size(edges)
    @assert n == m

    init_dists = [(Inf, -1) for i=1:n]
    init_dists[source] = (0.0, -1)
    dists_prev = @fiber(d(e((Inf, -1))), init_dists)
    dists_buffer = @fiber(d(e((Inf, -1)), n))
    dists_next = @fiber(d(e((Inf, -1)), n))
    modified = Scalar(false)

    for iter = 1:n  
        @finch @loop j i dists_buffer[j] <<minby>>= (first(dists_prev[i]) + edges[i, j], i)
        @finch @loop j dists_next[j] = minby(dists_prev[j], dists_buffer[j])

        modified = Scalar(false)
        @finch @loop i modified[] |= first(dists_next[i]) != first(dists_prev[i])
        if !modified[]
            break
        end
        dists_prev, dists_next = dists_next, dists_prev
    end

    return modified[] ? -1 : dists_prev
end