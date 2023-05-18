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

        @testset "tricount" begin
            size, sparsity = 100, 0.5
            input = sprand(size, size, sparsity)
            input = SparseMatrixCSC(Symmetric(input))
            
            graphs_input = SimpleDiGraph(input)
            finch_input = @fiber(d(sl(e(0.0))), input)
        
            expected = sum(Graphs.triangles(graphs_input))
            output = FinchApps.tricount(finch_input) * 6
            
            @test expected == output
        end

        @testset "brandes_bc" begin
            size, sparsity = 10, 0.5
            input = sprand(size, size, sparsity)
            
            graphs_input = SimpleDiGraph(input)
            finch_input = pattern!(@fiber(d(sl(e(0.0))), input))
        
            expected = Graphs.betweenness_centrality(graphs_input, normalize=false)
            output = FinchApps.brandes_bc(finch_input)
            
            @test expected == output
        end
    end

    @testset "linalg" begin
        @testset "spgemm" begin
            m, n, k = (32, 32, 32)
            p = 0.1
            A_ref = sprand(Int, m, k, p)
            B_ref = sprand(Int, k, n, p)
            C_ref = A_ref * B_ref
            A = @fiber(d(sl(e(0))), A_ref)
            B = @fiber(d(sl(e(0))), B_ref)

            for (key, fn) in [
                (:spgemm_inner, FinchApps.spgemm_inner),
                (:spgemm_gustavson, FinchApps.spgemm_gustavson),
                (:spgemm_outer, FinchApps.spgemm_outer),
            ]
                C = fn(A, B)
                @test C == C_ref
            end
        end
    end
end
