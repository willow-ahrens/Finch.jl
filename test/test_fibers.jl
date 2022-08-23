@testset "fibers" begin
    A = fsprand((10, 10), 0.5)
    B = fsprand((10, 10), 0.5)
    C = similar(B)
    @finch @loop i j C[i, j] = A[i, j] + B[i, j]

    println("B(h)[i] = A(s)[i]")
    A = Finch.Fiber(
        SparseList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseHash{1}((10,),
        Element{0.0}()))

    @test diff("sl_to_sh.jl", @finch_code @loop i B[i] += A[i])

    @finch @loop i B[i] += A[i]

    println(FiberArray(B))
    println(B)
    @test FiberArray(A) == FiberArray(B)

    println("A(s)[i] = B(h)[i]")

    @test diff("sh_to_sl.jl", @finch_code @loop i A[i] += B[i])

    @finch @loop i A[i] += B[i]

    println(FiberArray(A))
    @test FiberArray(A) == FiberArray(B)

    println("A(dsl)")

    A = Fiber(
        Dense(3, 
        SparseList(5, [1, 4, 6, 8], [1, 2, 5, 2, 4, 3, 5],
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

    println("B(shsh)[i, j] = A(dsl)[i, j]")

    B = Finch.Fiber(
        SparseHash{2}((3,5),
        Element{0.0}()))
    
    @test diff("d_sl_to_sh2.jl", @finch_code @loop i j B[i, j] += A[i, j])

    @finch @loop i j B[i, j] += A[i, j] 

    println(FiberArray(B))

    println("C(s)[i] = B(h)[i] where B(h)[i] = A(s)[i]")
    A = Finch.Fiber(
        SparseList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseHash{1}((0,),
        Element{0.0}()))
    C = Finch.Fiber(
        SparseList(10, 
        Element{0.0}()))

    @test diff("sl_to_sh_to_sl.jl", @finch_code (@loop i C[i] += B[i]) where (@loop i B[i] += A[i]))

    @finch (@loop i C[i] += B[i]) where (@loop i B[i] += A[i])

    println(FiberArray(C))
    @test FiberArray(A) == FiberArray(C)


    println("B(sc)[i] = A(sl)[i]")
    A = Finch.Fiber(
        SparseList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseCoo{1}((10,),
        Element{0.0}()))

    @test diff("sl_to_sc.jl", @finch_code @loop i B[i] += A[i])

    @finch @loop i B[i] += A[i]

    println(B)
    println(FiberArray(B))
    @test FiberArray(A) == FiberArray(B)

    println("A(sl)[i] = B(sc)[i]")

    @test diff("sc_to_sl.jl", @finch_code @loop i A[i] += B[i])

    println(A)
    println(B)

    @finch @loop i A[i] += B[i]

    println(A)
    println(FiberArray(A))
    @test FiberArray(A) == FiberArray(B)

    println("B(sc2)[i, j] = A(dsl)[i, j]")

    A = Fiber(
        Dense(3, 
        SparseList(5, [1, 4, 6, 8], [1, 2, 5, 2, 4, 3, 5],
        Element{0.0}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]))))

    B = Finch.Fiber(
        SparseCoo{2}((3,5),
        Element{0.0}()))
    
    @test diff("d_sl_to_sc2.jl", @finch_code @loop i j B[i, j] += A[i, j])

    @finch @loop i j B[i, j] += A[i, j] 

    println(FiberArray(B))

    println("C(s)[i] = B(c)[i] where B(c)[i] = A(s)[i]")
    A = Finch.Fiber(
        SparseList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseCoo{1}((10,),
        Element{0.0}()))
    C = Finch.Fiber(
        SparseList(10, 
        Element{0.0}()))

    @test diff("sl_to_sc_to_sl.jl", @finch_code (@loop i C[i] += B[i]) where (@loop i B[i] += A[i]))

    @finch (@loop i C[i] += B[i]) where (@loop i B[i] += A[i])

    println(FiberArray(C))
    @test FiberArray(A) == FiberArray(C)


    println("C(s)[i] = A(s)[i] + B(s)[i]")

    A = Finch.Fiber(
        SparseList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseList(10, [1, 4], [2, 5, 8],
        Element{0.0}([1.0, 1.0, 1.0])))
    C = Finch.Fiber(SparseList(10, Element{0.0}()))

    @test diff("sl_plus_sl_to_sl.jl", @finch_code @loop i C[i] += A[i] + B[i])

    @finch @loop i C[i] += A[i] + B[i]

    println(A)
    println(B)
    println(C)

    @test Finch.FiberArray(C) == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()


    println("C[i] = A(s)[i] + B(s)[i]")
    A = Finch.Fiber(
        SparseList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseList(10, [1, 4], [2, 5, 8],
        Element{0.0}([1.0, 1.0, 1.0])))
    C = zeros(10)

    @test diff("sl_plus_sl_to_vec.jl", @finch_code @loop i C[i] += A[i] + B[i])

    @finch @loop i C[i] += A[i] + B[i]

    println(A)
    println(B)
    println(C)

    @test C == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()

    println("B[i] = A(ds)[j, i]")
    A = Fiber(
        Dense(2,
        SparseList(10, [1, 6, 9], [1, 3, 5, 7, 9, 2, 5, 8],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0, 1.0, 1.0, 1.0]))))
    B = zeros(10)

    @test diff("d_sl_sum_2_to_vec.jl", @finch_code @loop j i B[i] += A[j, i])

    @finch @loop j i B[i] += A[j, i]

    println(A)
    println(B)

    @test B == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()

    println("C(s)[i] = A(s)[i::gallop] + B(s)[i::gallop]")
    A = Finch.Fiber(
        SparseList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseList(10, [1, 4], [2, 5, 8],
        Element{0.0}([1.0, 1.0, 1.0])))
    C = Finch.Fiber(SparseList(10, Element{0.0}()))

    @test diff("sl_gallop_plus_sl_gallop_to_sl.jl", @finch_code @loop i C[i] += A[i::gallop] + B[i::gallop])

    @finch @loop i C[i] += A[i::gallop] + B[i::gallop]

    println(A)
    println(B)
    println(C)

    @test Finch.FiberArray(C) == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()

    println("C(s)[i] = A(s)[i::gallop] * B(s)[i::gallop]")

    A = Finch.Fiber(
        SparseList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseList(10, [1, 5], [2, 5, 7, 8],
        Element{0.0}([1.0, 1.0, 1.0, 1.0])))
    C = Finch.Fiber(SparseList(10, Element{0.0}()))

    @test diff("sl_gallop_times_sl_gallop_to_sl.jl", @finch_code @loop i C[i] += A[i::gallop] * B[i::gallop])

    @finch @loop i C[i] += A[i::gallop] * B[i::gallop]

    println(A)
    println(B)
    println(C)

    @test Finch.FiberArray(C) == [0.0, 0.0, 0.0, 0.0, 4.0, 0.0, 5.0, 0.0, 0.0, 0.0]
    println()

    println("B(sl)[i] += A(dsl)[i, j]")
    A = Finch.Fiber(
        Dense(3, 
        SparseList(10, [1, 6, 6, 7], [1, 3, 5, 7, 9, 4],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0, 4.0]))))
    B = Finch.Fiber(
        SparseList(3,
        Element{0.0}()))

    @test diff("d_sl_sum_2_to_sl.jl", @finch_code @loop i j B[j] += A[i, j])

    @finch @loop i j B[i] += A[i, j]

    println(FiberArray(B))
    @test B.lvl.idx[1:B.lvl.pos[2]-1] == [1, 3]

    println("B[i] = A(dsl)[j, i]")
    A = Fiber(
        Dense(4,
        SparseList(10, [1, 6, 9, 9, 10], [1, 3, 5, 7, 9, 3, 5, 8, 3],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0, 1.0, 1.0, 1.0, 7.0]))))
    B = Fiber(
        SparseByte(4,
        Element{0.0}()))

    @test diff("d_sl_sum_2_to_sb.jl", @finch_code @loop i j B[j] += A[i, j])

    @finch @loop i j B[j] += A[i, j]

    @test B.lvl.srt[1:6] == [(1, 1), (1, 3), (1, 5), (1, 7), (1, 8), (1, 9)]
end