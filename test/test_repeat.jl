@testset "Repeat" begin
    A = Finch.Fiber(
        RepeatRLE{0.0, Int64, Int64, Float64}(10, [1, 7], [1, 3, 5, 7, 9, 10], [2.0, 3.0, 4.0, 5.0, 6.0, 7.0]))

    @test diff("repeat_display.txt", sprint(show, MIME"text/plain"(), A))
    @test diff("repeat_print.txt", sprint(show, A))

    @test reference_isequal(A, [2.0, 3.0, 3.0, 4.0, 4.0, 5.0, 5.0, 6.0, 6.0, 7.0])

    B = @fiber(d{Int64}(e(0.0)))

    @test diff("r_to_d.jl", @finch_code @loop i B[i] = A[i])
    @finch @loop i B[i] = A[i]
    @test reference_isequal(B, [2.0, 3.0, 3.0, 4.0, 4.0, 5.0, 5.0, 6.0, 6.0, 7.0])

    C = [1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3]

    @test diff("d_to_r.jl", @finch_code @loop i A[i] = C[i])
    @finch @loop i A[i] = C[i]

    @test A.lvl.idx[1:3] == [3, 7, 11]
    @test A.lvl.val[1:3] == [1.0, 2.0, 3.0]

    D = fiber(sparse([0, 0, 1, 0, 0, 0, 3, 0, 0]))
    @test diff("sl_to_r.jl", @finch_code @loop i A[i] = D[i])

    @finch @loop i A[i] = D[i]

    @test A.lvl.idx[1:5] == [2, 3, 6, 7, 9]
    @test A.lvl.val[1:5] == [0.0, 1.0, 0.0, 3.0, 0.0]

    A = Finch.Fiber(
        SparseVBL(10, [1, 4], [3, 5, 9], [1, 2, 3, 6],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))

    B = Finch.Fiber(Dense(Element{0.0}()))
    @finch @loop i B[i] = A[i]

    @test reference_isequal(B, [0, 0, 2, 0, 3, 0, 4, 5, 6, 0])

    B = Finch.Fiber(SparseList(Element{0.0}()))
    @finch @loop i B[i] = A[i]

    @test reference_isequal(B, [0, 0, 2, 0, 3, 0, 4, 5, 6, 0])
    @test B.lvl.idx[1:5] == [3, 5, 7, 8, 9]

    C = Finch.Fiber(SparseVBL(Element{0.0}()))

    @finch @loop i C[i] = B[i]

    @test C.lvl.pos[1:2] == [1, 4]
    @test C.lvl.idx[1:3] == [3, 5, 9]
    @test C.lvl.ofs[1:4] == [1, 2, 3, 6]
end