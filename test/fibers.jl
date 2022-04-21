@testset "fibers" begin
    println("B(h)[i] = A(s)[i]")
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
    println(B)
    @test FiberArray(A) == FiberArray(B)

    println("A(s)[i] = B(h)[i]")

    ex = @index_program_instance @loop i A[i] += B[i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i A[i] += B[i]

    println(FiberArray(A))
    @test FiberArray(A) == FiberArray(B)

    println("A(ds)")

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

    println("B(hh)[i, j] = A(ds)[i, j]")

    B = Finch.Fiber(
        HollowHash{2}((3,5),
        Element{0.0}()))
    
    ex = @index_program_instance @loop i j B[i, j] += A[i, j]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i j B[i, j] += A[i, j] 

    println(FiberArray(B))

    println("C(s)[i] = B(h)[i] where B(h)[i] = A(s)[i]")
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

    println("B(c)[i] = A(s)[i]")
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

    println("A(s)[i] = B(c)[i]")

    ex = @index_program_instance @loop i A[i] += B[i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    println(A)
    println(B)

    @index @loop i A[i] += B[i]

    println(A)
    println(FiberArray(A))
    @test FiberArray(A) == FiberArray(B)

    println("B(cc)[i, j] = A(ds)[i, j]")

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

    println("C(s)[i] = B(c)[i] where B(c)[i] = A(s)[i]")
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


    println("C(s)[i] = A(s)[i] + B(s)[i]")

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


    println("C[i] = A(s)[i] + B(s)[i]")
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

    println("B[i] = A(ds)[j, i]")
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

    println("C(s)[i] = A(s)[i::gallop] + B(s)[i::gallop]")
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

    println("C(s)[i] = A(s)[i::gallop] * B(s)[i::gallop]")

    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        HollowList(10, [1, 5], [2, 5, 7, 8],
        Element{0.0}([1.0, 1.0, 1.0, 1.0])))
    C = Finch.Fiber(HollowList(10, Element{0.0}()))

    ex = @index_program_instance @loop i C[i] += A[i::gallop] * B[i::gallop]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i C[i] += A[i::gallop] * B[i::gallop]

    println(A)
    println(B)
    println(C)

    @test Finch.FiberArray(C) == [0.0, 0.0, 0.0, 0.0, 4.0, 0.0, 5.0, 0.0, 0.0, 0.0]
    println()

    @testset "defaultcheck" begin
        println("B(s)[i] = A(ds)[i, j]")
        A = Finch.Fiber(
            Solid(3, 
            HollowList(10, [1, 6, 6, 7], [1, 3, 5, 7, 9, 4],
            Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0, 4.0]))))
        B = Finch.Fiber(
            HollowList(3,
            Element{0.0}()))
    
        ex = @index_program_instance @loop i j B[i] += A[i, j]
        display(execute_code_lowered(:ex, typeof(ex)))
        println()
    
        @index @loop i j B[i] += A[i, j]
    
        println(FiberArray(B))
        @test B.lvl.idx[1:B.lvl.pos[2]-1] == [1, 3]
    
    end

    println("B[i] = A(ds)[j, i]")
    A = Fiber(
        Solid(4,
        HollowList(10, [1, 6, 9, 9, 10], [1, 3, 5, 7, 9, 3, 5, 8, 3],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0, 1.0, 1.0, 1.0, 7.0]))))
    B = Fiber(
        HollowByte(4,
        Element{0.0}()))

    ex = @index_program_instance @loop j i B[i] += A[j, i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i j B[j] += A[i, j]

    @test B.lvl.srt[1:6] == [(1, 1), (1, 3), (1, 5), (1, 7), (1, 8), (1, 9)]
end