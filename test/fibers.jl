@testset "fibers" begin
    println("fiber(h) = fiber(s)")
    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        HollowHash{1}((10,),
        Element{0.0}()))

    ex = @index_program_instance @loop i B[i] += A[i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i B[i] += A[i]

    println(FiberArray(B))
    @test FiberArray(A) == FiberArray(B)

    println("fiber(s) = fiber(h)")

    ex = @index_program_instance @loop i A[i] += B[i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i A[i] += B[i]

    println(FiberArray(A))
    @test FiberArray(A) == FiberArray(B)

    println("fiber(d, s)")

    A = Finch.FiberArray(Fiber(
        Solid(3, 
        HollowList(5, [1, 4, 6, 8], [1, 2, 5, 2, 4, 3, 5],
        Element{0.0}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0])))))
    @test ndims(A) == 2
    @test size(A) == (3, 5)
    @test axes(A) == (1:3, 1:5)
    @test eltype(A) == Float64
    @test A == [
        1.0  1.0  0.0  0.0  1.0;
        0.0  1.0  0.0  1.0  0.0;
        0.0  0.0  1.0  0.0  1.0;
    ]

    println("fiber(hh) = fiber(d, s)")

    B = Finch.Fiber(
        HollowHash{2}((3,5),
        Element{0.0}()))
    
    ex = @index_program_instance @loop i j B[i, j] += A[i, j]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i j B[i, j] += A[i, j] 

    println(FiberArray(B))

    println("fiber(s) = fiber(h) where fiber(h) = fiber(s)")
    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        HollowHash{1}((10,),
        Element{0.0}()))
    C = Finch.Fiber(
        HollowList(10, 
        Element{0.0}()))

    ex = @index_program_instance (@loop i C[i] += B[i]) where (@loop i B[i] += A[i])
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index (@loop i C[i] += B[i]) where (@loop i B[i] += A[i])

    println(FiberArray(C))
    @test FiberArray(A) == FiberArray(C)

    println("fiber(c) = fiber(s)")
    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        HollowCoo{1}((10,),
        Element{0.0}()))

    ex = @index_program_instance @loop i B[i] += A[i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i B[i] += A[i]

    println(B)
    println(FiberArray(B))
    @test FiberArray(A) == FiberArray(B)

    println("fiber(s) = fiber(c)")

    ex = @index_program_instance @loop i A[i] += B[i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    println(A)
    println(B)

    @index @loop i A[i] += B[i]

    println("hello")
    println(A)

    println(FiberArray(A))
    @test FiberArray(A) == FiberArray(B)

    println("fiber(cc) = fiber(d, s)")

    A = Finch.FiberArray(Fiber(
        Solid(3, 
        HollowList(5, [1, 4, 6, 8], [1, 2, 5, 2, 4, 3, 5],
        Element{0.0}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0])))))

    B = Finch.Fiber(
        HollowCoo{2}((3,5),
        Element{0.0}()))
    
    ex = @index_program_instance @loop i j B[i, j] += A[i, j]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i j B[i, j] += A[i, j] 

    println(FiberArray(B))

    println("fiber(s) = fiber(c) where fiber(c) = fiber(s)")
    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        HollowCoo{1}((10,),
        Element{0.0}()))
    C = Finch.Fiber(
        HollowList(10, 
        Element{0.0}()))

    ex = @index_program_instance (@loop i C[i] += B[i]) where (@loop i B[i] += A[i])
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index (@loop i C[i] += B[i]) where (@loop i B[i] += A[i])

    println(FiberArray(C))
    @test FiberArray(A) == FiberArray(C)


    println("fiber(s) = fiber(s) + fiber(s)")

    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        HollowList(10, [1, 4], [2, 5, 8],
        Element{0.0}([1.0, 1.0, 1.0])))
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

    @test Finch.FiberArray(C) == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()


    println("dense = fiber(s) + fiber(s)")
    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        HollowList(10, [1, 4], [2, 5, 8],
        Element{0.0}([1.0, 1.0, 1.0])))
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
    A = Fiber(
        Solid(2,
        HollowList(10, [1, 6, 9], [1, 3, 5, 7, 9, 2, 5, 8],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0, 1.0, 1.0, 1.0]))))
    B = zeros(10)
    ex = @index_program_instance @loop j i B[i] += A[j, i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop j i B[i] += A[j, i]

    println(A)
    println(B)

    @test B == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()

    println("fiber(s) = fiber(gallop(s)) + fiber(gallop(s))")

    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        HollowList(10, [1, 4], [2, 5, 8],
        Element{0.0}([1.0, 1.0, 1.0])))
    C = Finch.Fiber(HollowList(10, Element{0.0}()))

    ex = @index_program_instance @loop i C[i] += A[i::gallop] + B[i::gallop]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i C[i] += A[i::gallop] + B[i::gallop]

    println(A)
    println(B)
    println(C)

    @test Finch.FiberArray(C) == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()

    #=
    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        HollowList(10, [1, 4], [2, 5, 8],
        Element{0.0}([1.0, 1.0, 1.0])))
    C = Finch.Fiber(HollowList(10, Element{0.0}()))

    ex = @index_program_instance @loop i C[i] += A[i::gallop] * B[i::gallop]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i C[i] += A[i::gallop] * B[i::gallop]

    println(A)
    println(B)
    println(C)

    @test Finch.FiberArray(C) == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()
    =#
end