using SparseArrays
using Graphs, SimpleWeightedGraphs

include(joinpath(@__DIR__, "../apps/apps.jl"))

@testset "apps" begin
    @info "Testing Finch Applications"
    @testset "graphs" begin
        @testset "pagerank" begin
            size, sparsity = 30, 0.5
            input = sprand(size, size, sparsity)

            graphs_input = Graphs.SimpleDiGraph(transpose(input))
            finch_input = pattern!(fiber(input))

            expected = Graphs.pagerank(graphs_input, 0.85, 20)
            output = FinchApps.pagerank(finch_input; nsteps=20, damp = 0.85)

            tol = 1e-6

            output = copyto!(zeros(size), output)

            @test maximum(abs.(output .- expected)) < tol
        end

        @testset "bfs" begin
            size, sparsity = 50, 0.5
            source = rand(1:size)
            input = sprand(size, size, sparsity)
        
            graphs_input = Graphs.SimpleDiGraph(transpose(input))
            finch_input = @fiber(d(sl(e(0.0))), input) 
        
            expected = Graphs.bfs_parents(graphs_input, source)
            output = FinchApps.bfs(finch_input, source)
        
            @test output == expected
        end

        @testset "bellmanford" begin
            size, sparsity = 50, 0.5
            source = rand(1:size)
            input = sprand(size, size, sparsity)
            
            graphs_input = SimpleWeightedDiGraph(transpose(input))
            finch_input = redefault!(@fiber(d(sl(e(0.0))), input), Inf)
            
            expected = Graphs.bellman_ford_shortest_paths(graphs_input, source)
            output = FinchApps.bellmanford(finch_input, source)

            @test output == collect(zip(expected.dists, expected.parents))
        end
    end
end
