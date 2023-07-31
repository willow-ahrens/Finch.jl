@testset "index" begin
    @info "Testing Index Expressions"

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

    using SparseArrays

    A_ref = sprand(10, 0.5); B_ref = sprand(10, 0.5); C_ref = vcat(A_ref, B_ref)
    A = fiber(SparseVector{Float64, Int64}(A_ref)); B = fiber(SparseVector{Float64, Int64}(B_ref)); C = @fiber(sl{Int64}(e(0.0), 20))
    @test check_output("concat_offset_permit.jl", @finch_code (C .= 0; @loop i C[i] = coalesce(A[~i], B[~(i - 10)])))
    @finch (C .= 0; @loop i C[i] = coalesce(A[~i], B[~(i - 10)]))
    @test reference_isequal(C, C_ref)

    F = fiber(Int64[1,1,1,1,1])

    @test check_output("sparse_conv.jl", @finch_code (C .= 0; @loop i j C[i] += (A[i] != 0) * coalesce(A[j - i + 3], 0) * F[j]))
    @finch (C .= 0; @loop i j C[i] += (A[i] != 0) * coalesce(A[j - i + 3], 0) * F[j])
    C_ref = zeros(10)
    for i = 1:10
        if A_ref[i] != 0
            for j = 1:5
                k = (j - (i - 3))
                if 1 <= k <= 10
                    C_ref[i] += A_ref[k]
                end
            end
        end
    end
    @test reference_isequal(C, C_ref)

    I = 2:4
    @test check_output("sparse_window.jl", @finch_code (C .= 0; @loop i C[i] = A[I[i]]))
    @finch (C .= 0; @loop i C[i] = A[I[i]])
    @test reference_isequal(C, [A(2), A(3), A(4)])

    @finch (C .= 0; @loop i C[i] = I[i])
    @test reference_isequal(C, [2, 3, 4])

    y = Array{Any}(undef, 4)
    x = @fiber(d(e(0.0)), zeros(2))
    X = Finch.permissive(x, true)
    
    @finch for i = _; y[i] := X[i] end

    @test isequal(y, [0.0, 0.0, missing, missing])

    y = Array{Any}(undef, 4)

    @finch for i = _; y[i] := Finch.permissive(x, true)[i] end

    @test isequal(y, [0.0, 0.0, missing, missing])

    y = Array{Any}(undef, 4)

    @finch begin
        z = Finch.permissive(x, true)
        for i = _; y[i] := z[i] end
    end

    @test isequal(y, [0.0, 0.0, missing, missing])

    @finch begin
        for i = 1:4; y[i] := x[~i] end
    end

    @test isequal(y, [0.0, 0.0, missing, missing])

    let
        io = IOBuffer()
        println(io, "chunkmask tests")

        @repl io A = @fiber(d(d(e(0.0), 15), 3))
        @repl io @finch begin
            m = Finch.chunkmask(5, 1:15)
            for i = _
                for j = _
                    A[j, i] = m[j, i]
                end
            end
        end
        @repl io AsArray(A)

        @repl io A = @fiber(d(d(e(0.0), 14), 3))
        @repl io @finch begin
            m = Finch.chunkmask(5, 1:14)
            for i = _
                for j = _
                    A[j, i] = m[j, i]
                end
            end
        end
        @repl io AsArray(A)
        
        @test check_output("chunkmask.txt", String(take!(io)))
    end

end