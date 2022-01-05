@testset "fibers" begin
    A = Finch.Fiber{Float64}((
        DenseLevel(3),
        SparseLevel{Float64}(5, [1, 4, 6, 8], [1, 2, 5, 2, 4, 3, 5]),
        ScalarLevel{Float64}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0])
    ))
    @test A == [
        1.0  1.0  0.0  0.0  1.0;
        0.0  1.0  0.0  1.0  0.0;
        0.0  0.0  1.0  0.0  1.0;
    ]
end