using BenchmarkTools
using SparseArrays
using MatrixDepot
using Finch
using Graphs

include("graphs.jl")

### PAGERANK ------------------- ###
# FINCH implementation
@benchmark pagerank(data) setup=(data=$(pattern!(fiber(SparseMatrixCSC(matrixdepot("SNAP/soc-Epinions1"))))))

# Graphs.jl implementation
# @benchmark Graphs.pagerank(data, 0.85, 20) setup=(data=Graphs.SimpleDiGraph(transpose(matrixdepot("SNAP/soc-Epinions1"))))


### BFS --------
# FINCH implementation
# @benchmark bfs(data, 1) setup=(data=$(pattern!(fiber(SparseMatrixCSC(matrixdepot("SNAP/soc-Epinions1"))))))

# Graphs.jl implementation
# @benchmark Graphs.bfs_parents(graphs_input, 1) setup=(data=Graphs.SimpleDiGraph(transpose(matrixdepot("SNAP/soc-Epinions1"))))


### BELLMAN-FORD ------------------- ###
# FINCH implementation
# @benchmark bellmanford(data, 1) setup=(data=$(pattern!(fiber(SparseMatrixCSC(matrixdepot("Newman/netscience"))))))

# Graphs.jl implementation
# @benchmark Graphs.bellman_ford_shortest_paths(data, 1) setup=(data=Graphs.SimpleDiGraph(transpose(matrixdepot("Newman/netscience"))))


### TRIANGLE COUNT ------------------- ###
# FINCH implementation
# @benchmark tricount(data) setup=(data=$(pattern!(fiber(SparseMatrixCSC(matrixdepot("SNAP/soc-Epinions1"))))))

# Graphs.jl implementation
# @benchmark Graphs.triangles(data) setup=(data=Graphs.SimpleDiGraph(transpose(matrixdepot("SNAP/soc-Epinions1"))))


### BRANDES ------------------- ###
# FINCH implementation
# @benchmark brandes_bc(data, 1:4) setup=(data=$(pattern!(fiber(SparseMatrixCSC(matrixdepot("SNAP/soc-Epinions1"))))))

# Graphs.jl implementation
# @benchmark Graphs.betweenness_centrality(data, 1:4, normalize=false) setup=(data=Graphs.SimpleDiGraph(transpose(matrixdepot("SNAP/soc-Epinions1"))))
