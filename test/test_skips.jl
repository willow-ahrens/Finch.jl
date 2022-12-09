@testset "skips" begin

    A = Finch.Fiber(
        SparseList{Int64}(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Scalar{0.0}()

    @test diff("sieve_hl_cond.jl", @finch_code (@loop j @sieve j == 1 B[] += A[j]))

    @finch (@loop j @sieve j == 1 B[] += A[j])

    @test B() == 2.0

    @finch (@loop j @sieve j == 2 B[] += A[j])

    @test B() == 0.0

    @test diff("sieve_hl_select.jl", @finch_code (@loop j @sieve select[3, j] B[] += A[j]))

    @finch (@loop j @sieve select[3, j] B[] += A[j])

    @test B() == 3.0

    @finch (@loop j @sieve select[4, j] B[] += A[j])

    @test B() == 0.0

    @test diff("gather_hl.jl", @finch_code (B[] += A[5]))

    @finch (B[] += A[5])

    @test B() == 4.0

    println(B)

    @finch (B[] += A[6])

    @test B() == 0.0

end