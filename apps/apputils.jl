function getRandomAdj(m,n,sparsity)
    rows = []
    cols = []
    for i=1:m
        for j = 1:n
            if rand() < sparsity
                push!(rows, i)
                push!(cols, j)
            end
        end
    end
    nnz = size(rows)[1]
    return sparse(rows, cols, ones(Int64, (nnz,)), m, n, max)
end

function convertAdjToGraph(adj)
    destinations = Array{Int64}(undef, 0)
    compressed_dests = adj.colptr
    for i = 1:adj.n
        for j = compressed_dests[i]:compressed_dests[i+1]-1
            append!(destinations, i)
        end
    end
    sources = adj.rowval
    weights = adj.nzval
    return SimpleWeightedDiGraph(sources, destinations, weights)
end

function randomLower(n, sparsity)
    rows = []
    cols = []
    for i=1:n
        for j = 1:i
            if rand() < sparsity
                push!(rows, i)
                push!(cols, j)
            end
        end
    end
    nnz = size(rows)[1]
    return sparse(rows, cols, ones(Int64, (nnz,)), n, n, max)
end

using SparseArrays
randomLower(5, 0.5)