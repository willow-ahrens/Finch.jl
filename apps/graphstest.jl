function testpagerank()
    size, sparsity = 30, 0.5
    input = getRandomAdj(size, size, sparsity)

    graphs_input = Graphs.SimpleDiGraph(transpose(input))
    finch_input = @fiber(d(sl(e(0.0))), input)

    expected = Graphs.pagerank(graphs_input, 0.85, 20)
    output = pagerank(finch_input)

    tol = 1e-6
    for i = 1:size
        @test abs(output[i] - expected[i]) < tol 
    end
end

function testbfs()
    size, sparsity = 50, 0.5
    source = rand(1:size)
    input = getRandomAdj(size, size, sparsity)

    graphs_input = Graphs.SimpleDiGraph(transpose(input))
    finch_input = @fiber(d(sl(e(0.0))), input) 

    expected = Graphs.bfs_parents(graphs_input, source)
    output = bfs(finch_input, source)

    for i = 1:size
        @test output[i] == expected[i]
    end
end

function testbellmanford() 
    size, sparsity = 100, 0.5
    source = rand(1:size)
    input = sprand(size, size, sparsity)
    
    graphs_input = convertAdjToGraph(input)
    finch_input = redefault!(@fiber(d(sl(e(0.0))), input), Inf)
    
    expected = Graphs.bellman_ford_shortest_paths(graphs_input, source)
    output = bellmanford(finch_input, source)

    #Check that outputs match
    for i = 1:size
        output_dist, output_parent = output[i]
        expected_dist = expected.dists[i]
        expected_parent = expected.parents[i]

        #Match different output formats
        output_no_parent = (output_parent == -1)
        expected_no_parent = (expected_parent == 0)
        output_unconnected = (isinf(output_dist))
        expected_unconnected = (isinf(expected_dist))

        if expected_no_parent
            @test output_no_parent 
        else
            @test output_parent == expected_parent 
        end

        if expected_unconnected
            @test output_unconnected 
        else
            @test output_dist == expected_dist 
        end
    end
end