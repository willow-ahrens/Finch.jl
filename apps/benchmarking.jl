using BenchmarkTools
using SparseArrays
using MatrixDepot
using Finch
using Graphs

include("apps.jl")

matrices = ["SNAP/soc-Epinions1"]

function main()
    for mtx in matrices
        println("matrix: ", mtx)

        ### PAGERANK ------------------- ###
        # FINCH implementation
        println("Pagerank Finch.jl")
        display(@benchmark FinchApps.pagerank(data) setup=(data=$(pattern!(fiber(SparseMatrixCSC(matrixdepot(mtx)))))))

        # Graphs.jl implementation
        println("Pagerank Graphs.jl")
        display(@benchmark Graphs.pagerank(data, 0.85, 20) setup=(data=$(Graphs.SimpleDiGraph(transpose(matrixdepot(mtx))))))


        ### BFS --------
        # FINCH implementation
        println("BFS Finch.jl")
        display(@benchmark FinchApps.bfs(data, 1) setup=(data=$(pattern!(fiber(SparseMatrixCSC(matrixdepot(mtx)))))))

        # Graphs.jl implementation
        println("BFS Graphs.jl")
        display(@benchmark Graphs.bfs_parents(data, 1) setup=(data=$(Graphs.SimpleDiGraph(transpose(matrixdepot(mtx))))))

        ### BELLMAN-FORD ------------------- ###
        # FINCH implementation
        println("Bellman Finch.jl")
        display(@benchmark FinchApps.bellmanford(data, 1) setup=(data=$(redefault!(fiber(SparseMatrixCSC(matrixdepot(mtx))), Inf))))

        # Graphs.jl implementation
        println("Bellman Graphs.jl")
        display(@benchmark Graphs.bellman_ford_shortest_paths(data, 1) setup=(data=$(Graphs.SimpleDiGraph(transpose(matrixdepot(mtx))))))


        ### TRIANGLE COUNT ------------------- ###
        println("Triangle Finch.jl")
        display(@benchmark FinchApps.tricount(data) setup=(data=$(pattern!(fiber(SparseMatrixCSC(matrixdepot(mtx)))))))

        # Graphs.jl implementation
        println("Triangle Graphs.jl")
        display(@benchmark Graphs.triangles(data) setup=(data=$(Graphs.SimpleDiGraph(transpose(matrixdepot(mtx))))))

        ### BRANDES ------------------- ###
        # FINCH implementation
        # @benchmark brandes_bc(data, 1:4) setup=(data=$(pattern!(fiber(SparseMatrixCSC(matrixdepot("SNAP/soc-Epinions1"))))))

        # Graphs.jl implementation
        # @benchmark Graphs.betweenness_centrality(data, 1:4, normalize=false) setup=(data=Graphs.SimpleDiGraph(transpose(matrixdepot("SNAP/soc-Epinions1"))))
    end
end

main()