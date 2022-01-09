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

    println("dense = fiber(s) + fiber(s)")
    A = Finch.Fiber{Float64}((
        SparseLevel{Float64}(10, [1, 6], [1, 3, 5, 7, 9, 11]),
        ScalarLevel{Float64}([2.0, 3.0, 4.0, 5.0, 6.0]),
    ))
    B = Finch.Fiber{Float64}((
        SparseLevel{Float64}(10, [1, 5], [2, 5, 8, 11]),
        ScalarLevel{Float64}([1.0, 1.0, 1.0]),
    ))
    C = zeros(10)
    ex = @I @loop i C[i] += A[i] + B[i]

    display(execute_code_lowered(:ex, typeof(ex)))
    println()
    execute(ex)

    println(A)
    println(B)
    println(C)

    @test C == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()

    println("dense[i] = fiber(d, s)[j, i]")
    A = Finch.Fiber{Float64}((
        DenseLevel(2),
        SparseLevel{Float64}(10, [1, 7, 11], [1, 3, 5, 7, 9, 11, 2, 5, 8, 11]),
        ScalarLevel{Float64}([2.0, 3.0, 4.0, 5.0, 6.0, Inf, 1.0, 1.0, 1.0]),
    ))
    B = zeros(10)
    ex = @I @loop j i B[i] += A[j, i]

    display(execute_code_lowered(:ex, typeof(ex)))
    println()
    execute(ex)

    println(A)
    println(B)

    @test B == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()
end