@testset "fibers" begin

    A_3 = Element{0.0}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0])
    A_2 = HollowList(5, A_3, [1, 4, 6, 8], [1, 2, 5, 2, 4, 3, 5])
    A_1 = Solid(3, A_2)
    A = Finch.FiberArray(Fiber(A_1))
    @test ndims(A) == 2
    @test size(A) == (3, 5)
    @test axes(A) == (1:3, 1:5)
    @test eltype(A) == Float64
    @test A == [
        1.0  1.0  0.0  0.0  1.0;
        0.0  1.0  0.0  1.0  0.0;
        0.0  0.0  1.0  0.0  1.0;
    ]

    #=
    println("fiber(s) = fiber(s) + fiber(s)")
    A_2 = Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])
    A_1 = HollowList(10, A_2, [1, 6], [1, 3, 5, 7, 9])
    A = Finch.Fiber(A_1)
    B_2 = Element{0.0}([1.0, 1.0, 1.0])
    B_1 = HollowList(10, B_1, [1, 4], [2, 5, 8])
    B = Finch.Fiber(B_1)
    C = Finch.Fiber(HollowList(10, Element{0.0}()))

    display(@macroexpand @index @loop i C[i] += A[i] + B[i])
    println()

    ex = @index_program_instance @loop i C[i] += A[i] + B[i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i C[i] += A[i] + B[i]

    println(A)
    println(B)
    println(C)

    @test C == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()


    println("dense = fiber(s) + fiber(s)")
    A_2 = Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])
    A_1 = HollowList(10, A_2, [1, 6], [1, 3, 5, 7, 9])
    A = Finch.Fiber(A_1)
    B_2 = Element{0.0}([1.0, 1.0, 1.0])
    B_1 = HollowList(10, B_1, [1, 4], [2, 5, 8])
    B = Finch.Fiber(B_1)
    C = zeros(10)
    ex = @index_program_instance @loop i C[i] += A[i] + B[i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i C[i] += A[i] + B[i]

    println(A)
    println(B)
    println(C)

    @test C == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()

    println("dense[i] = fiber(d, s)[j, i]")
    A_3 = Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0, 1.0, 1.0, 1.0])
    A_2 = HollowList{0.0}(10, A_3, [1, 6, 9], [1, 3, 5, 7, 9, 2, 5, 8])
    A_1 = Solid(2, A_2)
    A = Finch.Fiber(A_1)
    B = zeros(10)
    ex = @index_program_instance @loop j i B[i] += A[j, i]

    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop j i B[i] += A[j, i]

    println(A)
    println(B)

    @test B == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()
    =#
end