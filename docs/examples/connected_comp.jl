function dfs(node, edges, Visited)
    # Recursively visit neighbors of a node
    @finch Visited[node] = true
    @finch begin
        for j=_
            if (edges[j, node] == 1) && !(Visited[j])
                dfs(j, edges, Visited)
            end
        end
    end
end

function ConnectedComponents(edges)
    (n, m) = size(edges)
    @assert n == m 
    count = 0
    Visited = Tensor(Dense(Element(false)), n)

    for i in 1:n
        if !(Visited[i])  # avoid revisits
            dfs(i, edges, Visited)
            count += 1
        end
    end
    
    return count
end

# Example usage:
edges = [
    0 1 0 0 0;
    1 0 1 0 0;
    0 1 0 0 0;
    0 0 0 0 1;
    0 0 0 1 0
]

println(ConnectedComponents(edges))  # Output should be 2