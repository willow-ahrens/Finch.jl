@testset "fibers" begin
    println("B(h)[i] = A(s)[i]")
    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        HollowHash{1}((10,),
        Element{0.0}()))

    @test diff("hl_to_hh", @index_code_lowered @loop i B[i] += A[i])

    @index @loop i B[i] += A[i]

    println(FiberArray(B))
    println(B)
    @test FiberArray(A) == FiberArray(B)

    println("A(s)[i] = B(h)[i]")

    @test diff("hh_to_hs", @index_code_lowered @loop i A[i] += B[i])

    @index @loop i A[i] += B[i]

    println(FiberArray(A))
    @test FiberArray(A) == FiberArray(B)

    println("A(ds)")

    A = Fiber(
        Solid(3, 
        HollowList(5, [1, 4, 6, 8], [1, 2, 5, 2, 4, 3, 5],
        Element{0.0}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]))))
    @test ndims(FiberArray(A)) == 2
    @test size(FiberArray(A)) == (3, 5)
    @test axes(FiberArray(A)) == (1:3, 1:5)
    @test eltype(FiberArray(A)) == Float64
    @test FiberArray(A) == [
        1.0  1.0  0.0  0.0  1.0;
        0.0  1.0  0.0  1.0  0.0;
        0.0  0.0  1.0  0.0  1.0;
    ]

    println("B(hh)[i, j] = A(ds)[i, j]")

    B = Finch.Fiber(
        HollowHash{2}((3,5),
        Element{0.0}()))
    
    @test diff("s_hl_to_hh2", @index_code_lowered @loop i j B[i, j] += A[i, j])

    @index @loop i j B[i, j] += A[i, j] 

    println(FiberArray(B))

    println("C(s)[i] = B(h)[i] where B(h)[i] = A(s)[i]")
    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        HollowHash{1}((0,),
        Element{0.0}()))
    C = Finch.Fiber(
        HollowList(10, 
        Element{0.0}()))

    @test diff("hl_to_hh_to_hl", @index_code_lowered (@loop i C[i] += B[i]) where (@loop i B[i] += A[i]))

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

    @test diff("hl_to_hc", @index_code_lowered @loop i B[i] += A[i])

    @index @loop i B[i] += A[i]

    println(B)
    println(FiberArray(B))
    @test FiberArray(A) == FiberArray(B)

    println("A(s)[i] = B(c)[i]")

    @test diff("hc_to_hl", @index_code_lowered @loop i A[i] += B[i])

    println(A)
    println(B)

    @index @loop i A[i] += B[i]

    println(A)
    println(FiberArray(A))
    @test FiberArray(A) == FiberArray(B)

    println("B(cc)[i, j] = A(ds)[i, j]")

    A = Fiber(
        Solid(3, 
        HollowList(5, [1, 4, 6, 8], [1, 2, 5, 2, 4, 3, 5],
        Element{0.0}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]))))

    B = Finch.Fiber(
        HollowCoo{2}((3,5),
        Element{0.0}()))
    
    @test diff("s_hl_to_hc2", @index_code_lowered @loop i j B[i, j] += A[i, j])

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

    @test diff("hl_to_hc_to_hl", @index_code_lowered (@loop i C[i] += B[i]) where (@loop i B[i] += A[i]))

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

    @test diff("hl_plus_hl_to_hl", @index_code_lowered @loop i C[i] += A[i] + B[i])

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

    @test diff("hl_plus_hl_to_vec", @index_code_lowered @loop i C[i] += A[i] + B[i])

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

    @test diff("s_hl_sum_2_to_vec", @index_code_lowered @loop j i B[i] += A[j, i])

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

    @test diff("hl_gallop_plus_hl_gallop_to_hl", @index_code_lowered @loop i C[i] += A[i::gallop] + B[i::gallop])

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

    @test diff("hl_gallop_times_hl_gallop_to_hl", @index_code_lowered @loop i C[i] += A[i::gallop] * B[i::gallop])

    @index @loop i C[i] += A[i::gallop] * B[i::gallop]

    println(A)
    println(B)
    println(C)

    @test Finch.FiberArray(C) == [0.0, 0.0, 0.0, 0.0, 4.0, 0.0, 5.0, 0.0, 0.0, 0.0]
    println()

    println("B(s)[i] = A(ds)[i, j]")
    A = Finch.Fiber(
        Solid(3, 
        HollowList(10, [1, 6, 6, 7], [1, 3, 5, 7, 9, 4],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0, 4.0]))))
    B = Finch.Fiber(
        HollowList(3,
        Element{0.0}()))

    @test diff("s_hl_sum_2_to_hl", @index_code_lowered @loop i j B[j] += A[i, j])

    @index @loop i j B[i] += A[i, j]

    println(FiberArray(B))
    @test B.lvl.idx[1:B.lvl.pos[2]-1] == [1, 3]

    println("B[i] = A(ds)[j, i]")
    A = Fiber(
        Solid(4,
        HollowList(10, [1, 6, 9, 9, 10], [1, 3, 5, 7, 9, 3, 5, 8, 3],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0, 1.0, 1.0, 1.0, 7.0]))))
    B = Fiber(
        HollowByte(4,
        Element{0.0}()))

    @test diff("s_hl_sum_2_to_hb", @index_code_lowered @loop i j B[j] += A[i, j])

    @index @loop i j B[j] += A[i, j]

    @test B.lvl.srt[1:6] == [(1, 1), (1, 3), (1, 5), (1, 7), (1, 8), (1, 9)]
end