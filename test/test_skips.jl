@testset "skips" begin

    A = @fiber(sl(e(0.0)), [2.0, 0.0, 3.0, 0.0, 4.0, 0.0, 5.0, 0.0, 6.0, 0.0])
    B = Scalar{0.0}()

    @test check_output("sieve_hl_cond.jl", @finch_code (B .= 0; @loop j if j == 1 B[] += A[j] end))

    @finch (B .= 0; @loop j if j == 1 B[] += A[j] end)

    @test B() == 2.0

    @finch (B .= 0; @loop j if j == 2 B[] += A[j] end)

    @test B() == 0.0

    @test check_output("sieve_hl_select.jl", @finch_code (@loop j if diagmask[3, j] B[] += A[j] end))

    @finch (B .= 0; @loop j if diagmask[3, j] B[] += A[j] end)

    @test B() == 3.0

    @finch (B .= 0; @loop j if diagmask[4, j] B[] += A[j] end)

    @test B() == 0.0

    @test check_output("gather_hl.jl", @finch_code (B[] += A[5]))

    @finch (B .= 0; B[] += A[5])

    @test B() == 4.0

    println(B)

    @finch (B .= 0; B[] += A[6])

    @test B() == 0.0

end