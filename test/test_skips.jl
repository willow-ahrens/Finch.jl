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

    @testset "scansearch" begin
        for v in [
            [2, 3, 5, 7, 8, 10, 13, 14, 15, 17, 19, 21, 25, 26, 32, 35, 36, 38, 39, 40, 41, 42, 45, 47, 48, 51, 52, 54, 57, 58, 59, 60, 64, 68, 72, 78, 79, 82, 83, 87, 89, 95, 97, 98, 100],
            collect(-200:3:500)
        ]
            hi = length(v)
            for lo = 1:hi, i = lo:hi
                @test Finch.scansearch(v, v[i], lo, hi) == i
                @test Finch.scansearch(v, v[i] - 1, lo, hi) == ((i > lo && v[i-1] == v[i]-1) ? i-1 : i)
                @test Finch.scansearch(v, v[i] + 1, lo, hi) == i + 1
            end
        end
    end
end