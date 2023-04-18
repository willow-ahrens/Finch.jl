function getRandomAdj(m,n,sparsity)
    nnz = convert(Int64, round(m*n*sparsity))
    return sparse(rand(1:m, nnz), rand(1:n, nnz), ones(Int64, (nnz,)), m, n, max)
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