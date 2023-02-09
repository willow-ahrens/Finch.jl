@testset "fibers" begin
    A = fsprand((10, 10), 0.5)
    B = fsprand((10, 10), 0.5)
    C = similar(B)
    @finch @loop i j C[i, j] = A[i, j] + B[i, j]

    println("B(h)[i] = A(s)[i]")
    A = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseHash{1, Tuple{Int64}, Int64}((10,),
        Element{0.0}()))

    @test check_output("sl_to_sh.jl", @finch_code @loop i B[i] += A[i])

    @finch @loop i B[i] += A[i]

    println(B)
    @test reference_isequal(A, B)

    println("A(s)[i] = B(h)[i]")

    @test check_output("sh_to_sl.jl", @finch_code @loop i A[i] += B[i])

    @finch @loop i A[i] += B[i]

    println(A)
    @test reference_isequal(A, B)

    println("A(dsl)")

    A = Fiber(
        Dense{Int64}(3, 
        SparseList{Int64, Int64}(5, [1, 4, 6, 8], [1, 2, 5, 2, 4, 3, 5],
        Element{0.0}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]))))
    @test ndims(A) == 2
    @test size(A) == (3, 5)
    @test axes(A) == (1:3, 1:5)
    @test eltype(A) == Float64
    @test reference_isequal(A, [
        1.0  1.0  0.0  0.0  1.0;
        0.0  1.0  0.0  1.0  0.0;
        0.0  0.0  1.0  0.0  1.0;
    ])

    println("B(shsh)[i, j] = A(dsl)[i, j]")

    B = Finch.Fiber(
        SparseHash{2, Tuple{Int64, Int64}, Int64}((3,5),
        Element{0.0}()))
    
    @test check_output("d_sl_to_sh2.jl", @finch_code @loop i j B[i, j] += A[i, j])

    @finch @loop i j B[i, j] += A[i, j] 

    println(B)

    println("C(s)[i] = B(h)[i] where B(h)[i] = A(s)[i]")
    A = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseHash{1, Tuple{Int64}, Int64}((0,),
        Element{0.0}()))
    C = Finch.Fiber(
        SparseList{Int64, Int64}(10, 
        Element{0.0}()))

    @test check_output("sl_to_sh_to_sl.jl", @finch_code (@loop i C[i] += B[i]) where (@loop i B[i] += A[i]))

    @finch (@loop i C[i] += B[i]) where (@loop i B[i] += A[i])

    println(C)
    @test reference_isequal(A, C)


    println("B(sc)[i] = A(sl)[i]")
    A = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseCoo{1, Tuple{Int64}, Int64}((10,),
        Element{0.0}()))

    @test check_output("sl_to_sc.jl", @finch_code @loop i B[i] += A[i])

    @finch @loop i B[i] += A[i]

    println(B)
    @test reference_isequal(A, B)

    println("A(sl)[i] = B(sc)[i]")

    @test check_output("sc_to_sl.jl", @finch_code @loop i A[i] += B[i])

    println(A)
    println(B)

    @finch @loop i A[i] += B[i]

    println(A)
    @test reference_isequal(A, B)

    println("B(sc2)[i, j] = A(dsl)[i, j]")

    A = Fiber(
        Dense{Int64}(3, 
        SparseList{Int64, Int64}(5, [1, 4, 6, 8], [1, 2, 5, 2, 4, 3, 5],
        Element{0.0}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]))))

    B = Finch.Fiber(
        SparseCoo{2, Tuple{Int64, Int64}, Int64}((3,5),
        Element{0.0}()))
    
    @test check_output("d_sl_to_sc2.jl", @finch_code @loop i j B[i, j] += A[i, j])

    @finch @loop i j B[i, j] += A[i, j] 

    println(B)

    println("C(s)[i] = B(c)[i] where B(c)[i] = A(s)[i]")
    A = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseCoo{1, Tuple{Int64}, Int64}((10,),
        Element{0.0}()))
    C = Finch.Fiber(
        SparseList{Int64, Int64}(10, 
        Element{0.0}()))

    @test check_output("sl_to_sc_to_sl.jl", @finch_code (@loop i C[i] += B[i]) where (@loop i B[i] += A[i]))

    @finch (@loop i C[i] += B[i]) where (@loop i B[i] += A[i])

    println(C)
    @test reference_isequal(A, C)


    println("C(s)[i] = A(s)[i] + B(s)[i]")

    A = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 4], [2, 5, 8],
        Element{0.0}([1.0, 1.0, 1.0])))
    C = Finch.Fiber(SparseList{Int64, Int64}(10, Element{0.0}()))

    @test check_output("sl_plus_sl_to_sl.jl", @finch_code @loop i C[i] += A[i] + B[i])

    @finch @loop i C[i] += A[i] + B[i]

    println(A)
    println(B)
    println(C)

    @test reference_isequal(C, [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0])
    println()


    println("C[i] = A(s)[i] + B(s)[i]")
    A = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 4], [2, 5, 8],
        Element{0.0}([1.0, 1.0, 1.0])))
    C = zeros(10)

    @test check_output("sl_plus_sl_to_vec.jl", @finch_code @loop i C[i] += A[i] + B[i])

    @finch @loop i C[i] += A[i] + B[i]

    println(A)
    println(B)
    println(C)

    @test C == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()

    println("B[i] = A(ds)[j, i]")
    A = Fiber(
        Dense{Int64}(2,
        SparseList{Int64, Int64}(10, [1, 6, 9], [1, 3, 5, 7, 9, 2, 5, 8],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0, 1.0, 1.0, 1.0]))))
    B = zeros(10)

    @test check_output("d_sl_sum_2_to_vec.jl", @finch_code @loop j i B[i] += A[j, i])

    @finch @loop j i B[i] += A[j, i]

    println(A)
    println(B)

    @test B == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()

    println("C(s)[i] = A(s)[i::gallop] + B(s)[i::gallop]")
    A = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 4], [2, 5, 8],
        Element{0.0}([1.0, 1.0, 1.0])))
    C = Finch.Fiber(SparseList{Int64, Int64}(10, Element{0.0}()))

    @test check_output("sl_gallop_plus_sl_gallop_to_sl.jl", @finch_code @loop i C[i] += A[i::gallop] + B[i::gallop])

    @finch @loop i C[i] += A[i::gallop] + B[i::gallop]

    println(A)
    println(B)
    println(C)

    @test reference_isequal(C, [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0])
    println()

    println("C(s)[i] = A(s)[i::gallop] * B(s)[i::gallop]")

    A = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 5], [2, 5, 7, 8],
        Element{0.0}([1.0, 1.0, 1.0, 1.0])))
    C = Finch.Fiber(SparseList{Int64, Int64}(10, Element{0.0}()))

    @test check_output("sl_gallop_times_sl_gallop_to_sl.jl", @finch_code @loop i C[i] += A[i::gallop] * B[i::gallop])

    @finch @loop i C[i] += A[i::gallop] * B[i::gallop]

    println(A)
    println(B)
    println(C)

    @test reference_isequal(C, [0.0, 0.0, 0.0, 0.0, 4.0, 0.0, 5.0, 0.0, 0.0, 0.0])
    println()

    println("B(sl)[i] += A(dsl)[i, j]")
    A = Finch.Fiber(
        Dense{Int64}(3, 
        SparseList{Int64, Int64}(10, [1, 6, 6, 7], [1, 3, 5, 7, 9, 4],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0, 4.0]))))
    B = Finch.Fiber(
        SparseList{Int64, Int64}(3,
        Element{0.0}()))

    @test check_output("d_sl_sum_2_to_sl.jl", @finch_code @loop i j B[j] += A[i, j])

    @finch @loop i j B[i] += A[i, j]

    println(B)
    @test B.lvl.idx[1:B.lvl.pos[2]-1] == [1, 3]

    println("B[i] = A(dsl)[j, i]")
    A = Fiber(
        Dense{Int64}(4,
        SparseList{Int64, Int64}(10, [1, 6, 9, 9, 10], [1, 3, 5, 7, 9, 3, 5, 8, 3],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0, 1.0, 1.0, 1.0, 7.0]))))
    B = Fiber(
        SparseBytemap{Int64, Int64}(4,
        Element{0.0}()))

    @test check_output("d_sl_sum_2_to_sb.jl", @finch_code @loop i j B[j] += A[i, j])

    @finch @loop i j B[j] += A[i, j]

    @test B.lvl.srt[1:6] == [(1, 1), (1, 3), (1, 5), (1, 7), (1, 8), (1, 9)]

    r = Scalar(0.0)
    B = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 5], [2, 5, 7, 8],
        Element{0.0}([2.0, 1.0, 1.0, 1.0])))

    @finch @loop i r[] <<choose(0)>>= B[i]

    @test r[] == 2.0

    C = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 4], [3, 4, 8],
        Element{0.0}([3.0, 3.0, 3.0, 3.0])))
    A = similar(B)

    @finch @loop i A[i] = choose(0)(B[i], C[i])
end