using LinearAlgebra 

function testpagerank()
    size, sparsity = 30, 0.5
    input = getRandomAdj(size, size, sparsity)

    graphs_input = Graphs.SimpleDiGraph(transpose(input))
    finch_input = @fiber(d(sl(e(0.0))), input)

    expected = Graphs.pagerank(graphs_input, 0.85, 20)
    output = pagerank(finch_input)

    tol = 1e-6
    correct = true
    for i = 1:size
        correct &= abs(output[i] - expected[i]) < tol 
    end
    @test correct
end

function testbfs()
    size, sparsity = 50, 0.5
    source = rand(1:size)
    input = getRandomAdj(size, size, sparsity)

    graphs_input = Graphs.SimpleDiGraph(transpose(input))
    finch_input = @fiber(d(sl(e(0.0))), input) 

    expected = Graphs.bfs_parents(graphs_input, source)
    output = bfs(finch_input, source)

    correct = true
    for i = 1:size
        correct &= output[i] == expected[i]
    end
    @test correct
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
    correct = true
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
            correct &= output_no_parent 
        else
            correct &= output_parent == expected_parent 
        end

        if expected_unconnected
            correct &= output_unconnected 
        else
            correct &= output_dist == expected_dist 
        end
    end
    @test correct
end

function testtricount()
    size, sparsity = 1000, 0.5
    input = randomLower(size, sparsity)
    
    graphs_input = convertAdjToGraph(input)
    finch_input = @fiber(d(sl(e(0.0))), input)

    expected = sum(Graphs.triangles(graphs_input))
    output = tricount(finch_input)
    
    @test expected == output
end