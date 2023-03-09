using SparseArrays

@testset "issues" begin
    #https://github.com/willow-ahrens/Finch.jl/issues/51
    let
        x = @fiber(d(e(0.0)), [1, 2, 3])
        y = Scalar{0.0}()
        @finch @loop i j y[] += min(x[i], x[j])
        @test y[] == 14
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/53
    let
        x = @fiber(sl(p()), fsparse(([1, 3, 7, 8],), [true, true, true, true], (10,)))
        y = Scalar{0.0}()
        @finch @loop i y[] += ifelse(x[i], 3, -1)
        @test y[] == 6
        a = 3
        b = -1
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/59
    let
        B = @fiber(d(e(0)), [2, 4, 5])
        A = @fiber(d(e(0), 6))
        @finch (A .= 0; @loop i A[B[i]] = i)
        @test reference_isequal(A, [0, 1, 0, 2, 3, 0])
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/61
    I = copyto!(@fiber(rl(0)), [1, 1, 9, 3, 3])
    A = [
        11 12 13 14 15;
        21 22 23 24 25;
        31 32 33 34 35;
        41 42 43 44 45;
        51 52 53 54 55;
        61 62 63 64 65;
        71 72 73 74 75;
        81 82 83 84 85;
        91 92 93 94 95]
    A = copyto!(@fiber(d(d(e(0)))), A)
    B = @fiber(d(e(0)))
    
    @test check_output("fiber_as_idx.jl", @finch_code (B .= 0; @loop i B[i] = A[I[i], i]))
    @finch (B .= 0; @loop i B[i] = A[I[i], i])

    @test B == [11, 12, 93, 34, 35]

    #https://github.com/willow-ahrens/Finch.jl/issues/101
    let
        t = @fiber(sl(sl(e(0.0))))
        X = @fiber(sl(sl(e(0.0))))
        A = @fiber(sl(sl(e(0.0))), SparseMatrixCSC([0 0 0 0; -1 -1 -1 -1; -2 -2 -2 -2; -3 -3 -3 -3]))
        @test_throws DimensionMismatch @finch (t .= 0; @loop j i t[i, j] = min(X[i, j],  A[i, j]))
        X = @fiber(sl(sl(e(0.0), 4), 4))
        @finch (t .= 0; @loop j i t[i, j] = min(X[i, j],  A[i, j]))
        @test t == A
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/115

    let
        function f(a::Float64, b::Float64, c::Float64)
            return a+b+c
        end 
        struct MyAlgebra <: Finch.AbstractAlgebra end
        Finch.register(MyAlgebra)
        t = @fiber(sl(sl(e(0.0))))
        B = SparseMatrixCSC([0 0 0 0; -1 -1 -1 -1; -2 -2 -2 -2; -3 -3 -3 -3])
        A = dropdefaults(copyto!(@fiber(sl(sl(e(0.0)))), B))
        @finch MyAlgebra() (t .= 0; @loop j i t[i, j] = f(A[i,j], A[i,j], A[i,j]))
        @test t == B .* 3
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/115

    let
        t = @fiber(sl(sl(e(0.0))))
        B = SparseMatrixCSC([0 0 0 0; -1 -1 -1 -1; -2 -2 -2 -2; -3 -3 -3 -3])
        A = dropdefaults(copyto!(@fiber(sl(sl(e(0.0)))), B))
        @test_throws Finch.FormatLimitation @finch MyAlgebra() (t .= 0; @loop i j t[i, j] = A[i, j])
    end

    let
        t = @fiber(d(sl(e(0.0))))
        B = SparseMatrixCSC([0 0 0 0; -1 -1 -1 -1; -2 -2 -2 -2; -3 -3 -3 -3])
        A = dropdefaults(copyto!(@fiber(d(sl(e(0.0)))), B))
        @test_throws Finch.FormatLimitation @finch MyAlgebra() (t .= 0; @loop i j t[i, j] = A[i, j])
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/129

    let
        a = @fiber(d(e(0)), [1, 3, 7, 2])

        x = Scalar((0, 0))
        @finch @loop i x[] <<maxby>>= (a[i], i)
        @test x[][2] == 3

        y = Scalar(0 => 0)
        @finch @loop i y[] <<maxby>>= a[i] => i
        @test y[][2] == 3
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/124

    let
        A = sparse([3, 4, 3, 4], [1, 2, 3, 3], [1.1, 2.2, 3.3, 4.4], 4, 3)

        B = @fiber(d(sl(e(0.0))))

        @finch (B .= 0; @loop j i B[i, j] = A[i, j])

        @test isstructequal(B, fiber(A))

        v = SparseVector(10, [1, 6, 7, 9], [1.1, 2.2, 3.3, 4.4])

        w = @fiber(sl(e(0.0)))

        @finch (w .= 0; @loop i w[i] = v[i])

        @test isstructequal(w, fiber(v))
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/121

    let
        io = IOBuffer()
        y = [2.0, Inf, Inf, 1.0, 3.0, Inf]
        yf = @fiber(sl(e(Inf)), y)
        println(io, "@fiber(sl(e(Inf)), $y):")
        println(io, yf)

        x = Scalar(Inf)

        @test check_output("specialvals_minimum_inf.jl", @finch_code (for i=_; x[] <<min>>= yf[i] end))
        @finch for i=_; x[] <<min>>= yf[i] end
        @test x[] == 1.0

        @test check_output("specialvals_repr_inf.txt", String(take!(io)))

        io = IOBuffer()
        y = [2.0, NaN, NaN, 1.0, 3.0, NaN]
        yf = @fiber(sl(e(NaN)), y)
        println(io, "@fiber(sl(e(NaN)), $y):")
        println(io, yf)

        x = Scalar(Inf)

        @test check_output("specialvals_minimum_nan.jl", @finch_code (for i=_; x[] <<min>>= yf[i] end))
        @finch for i=_; x[] <<min>>= yf[i] end
        @test isequal(x[], NaN)

        @test check_output("specialvals_repr_nan.txt", String(take!(io)))

        y = [2.0, missing, missing, 1.0, 3.0, missing]
        yf = @fiber(sl(e{missing, Union{Float64,Missing}}()), y)
        println(io, "@fiber(sl(e(missing)), $y):")
        println(io, yf)

        x = Scalar(Inf)

        @test check_output("specialvals_minimum_missing.jl", @finch_code (for i=_; x[] <<min>>= yf[i] end))
        @finch for i=_; x[] <<min>>= coalesce(yf[i], missing, Inf) end
        @test x[] == 1.0

        @test check_output("specialvals_repr_missing.txt", String(take!(io)))
    end

end