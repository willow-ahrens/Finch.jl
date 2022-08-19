@testset "repeat" begin
    A = Finch.Fiber(
        Repeat{0.0}(10, [1, 7], [1, 3, 5, 7, 9, 10], [2.0, 3.0, 4.0, 5.0, 6.0, 7.0]))

    @test diff("repeat_display.txt", sprint(show, MIME"text/plain"(), A))
    @test diff("repeat_print.txt", sprint(show, A))

    @test FiberArray(A) == [2.0, 3.0, 3.0, 4.0, 4.0, 5.0, 5.0, 6.0, 6.0, 7.0]

    B = @f(d(e(0.0)))

    @test diff("r_to_d.jl", @index_code @loop i B[i] = A[i])
    @index @loop i B[i] = A[i]
    @test FiberArray(B) == [2.0, 3.0, 3.0, 4.0, 4.0, 5.0, 5.0, 6.0, 6.0, 7.0]

    C = [1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3]

    @test diff("d_to_r.jl", @index_code @loop i A[i] = C[i])
    @index @loop i A[i] = C[i]

    @test A.lvl.idx[1:3] == [3, 7, 11]
    @test A.lvl.val[1:3] == [1.0, 2.0, 3.0]

    D = fiber(sparse([0, 0, 1, 0, 0, 0, 3, 0, 0]))
    @test diff("sl_to_r.jl", @index_code @loop i A[i] = D[i])

    @index @loop i A[i] = D[i]

    @test A.lvl.idx[1:5] == [2, 3, 6, 7, 9]
    @test A.lvl.val[1:5] == [0.0, 1.0, 0.0, 3.0, 0.0]
end