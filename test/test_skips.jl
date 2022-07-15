@testset "skips" begin

    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Scalar{0.0}()

    @test diff("sieve_hl_cond.jl", @index_code (@loop j @sieve j == 1 B[] += A[j]))

    @index (@loop j @sieve j == 1 B[] += A[j])

    @test B() == 2.0

    @index (@loop j @sieve j == 2 B[] += A[j])

    @test B() == 0.0

    @test diff("sieve_hl_select.jl", @index_code (@loop j @sieve select[3, j] B[] += A[j]))

    @index (@loop j @sieve select[3, j] B[] += A[j])

    @test B() == 3.0

    @index (@loop j @sieve select[4, j] B[] += A[j])

    @test B() == 0.0

    @test diff("gather_hl.jl", @index_code (B[] += A[5]))

    @index (B[] += A[5])

    @test B() == 4.0

    println(B)

    @index (B[] += A[6])

    @test B() == 0.0

end