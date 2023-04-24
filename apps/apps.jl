module Apps

using Finch
using SparseArrays
using Graphs, SimpleWeightedGraphs
using Test

export pagerank
export bfs
export bellmanford

include("graphs.jl")
include("graphstest.jl")
include("apputils.jl")

function testapps() 
    trials = 10
    tests = [
        # ("pagerank", testpagerank),
        # ("bfs", testbfs),
        # ("bellmanford", testbellmanford),
        ("trianglecount", testtricount),
    ]

    for test in tests
        failures = 0
        @testset "$(test[1])" begin
            for i=1:trials
                try
                    test[2]()
                catch
                    failures += 1
                    println("Failed test on $(test[1])")
                end
            end
            if failures == 0
                println("Passed all tests on $(test[1])")
            end
        end
    end
end

testapps()

end