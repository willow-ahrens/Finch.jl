using SparseArrays
using CIndices

@testset "issues" begin
    @info "Testing Github Issues"
    #https://github.com/willow-ahrens/Finch.jl/issues/51
    let
        x = Fiber!(Dense(Element(0.0)), [1, 2, 3])
        y = Scalar{0.0}()
        @finch for i=_, j=_; y[] += min(x[i], x[j]) end
        @test y[] == 14
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/53
    let
        x = Fiber!(SparseList(Pattern()), fsparse(([1, 3, 7, 8],), [true, true, true, true], (10,)))
        y = Scalar{0.0}()
        @finch for i=_; y[] += ifelse(x[i], 3, -1) end
        @test y[] == 6
        a = 3
        b = -1
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/59
    let
        B = Fiber!(Dense(Element(0)), [2, 4, 5])
        A = Fiber!(Dense(Element(0), 6))
        @finch (A .= 0; for i=_; A[B[i]] = i end)
        @test reference_isequal(A, [0, 1, 0, 2, 3, 0])
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/61
    I = copyto!(Fiber!(RepeatRLE(0)), [1, 1, 9, 3, 3])
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
    A = copyto!(Fiber!(Dense(Dense(Element(0)))), A)
    B = Fiber!(Dense(Element(0)))
    
    @test check_output("fiber_as_idx.jl", @finch_code (B .= 0; for i=_; B[i] = A[I[i], i] end))
    @finch (B .= 0; for i=_; B[i] = A[I[i], i] end)

    @test B == [11, 12, 93, 34, 35]

    #https://github.com/willow-ahrens/Finch.jl/issues/101
    let
        t = Fiber!(SparseList(SparseList(Element(0.0))))
        X = Fiber!(SparseList(SparseList(Element(0.0))))
        A = Fiber!(SparseList(SparseList(Element(0.0))), SparseMatrixCSC([0 0 0 0; -1 -1 -1 -1; -2 -2 -2 -2; -3 -3 -3 -3]))
        @test_throws DimensionMismatch @finch (t .= 0; for j=_, i=_; t[i, j] = min(X[i, j],  A[i, j]) end)
        X = Fiber!(SparseList(SparseList(Element(0.0), 4), 4))
        @finch (t .= 0; for j=_, i=_; t[i, j] = min(X[i, j],  A[i, j]) end)
        @test t == A
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/115

    let
        function f(a::Float64, b::Float64, c::Float64)
            return a+b+c
        end 
        struct MyAlgebra115 <: Finch.AbstractAlgebra end
        Finch.virtualize(ex, ::Type{MyAlgebra115}, ::Finch.JuliaContext) = MyAlgebra115()
        t = Fiber!(SparseList(SparseList(Element(0.0))))
        B = SparseMatrixCSC([0 0 0 0; -1 -1 -1 -1; -2 -2 -2 -2; -3 -3 -3 -3])
        A = dropdefaults(copyto!(Fiber!(SparseList(SparseList(Element(0.0)))), B))
        @finch algebra=MyAlgebra115() (t .= 0; for j=_, i=_; t[i, j] = f(A[i,j], A[i,j], A[i,j]) end)
        @test t == B .* 3
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/115

    let
        t = Fiber!(SparseList(SparseList(Element(0.0))))
        B = SparseMatrixCSC([0 0 0 0; -1 -1 -1 -1; -2 -2 -2 -2; -3 -3 -3 -3])
        A = dropdefaults(copyto!(Fiber!(SparseList(SparseList(Element(0.0)))), B))
        @test_logs (:warn, "Performance Warning: non-concordant traversal of t[i, j] (hint: most arrays prefer column major or first index fast, run in fast mode to ignore this warning)") match_mode=:any @test_throws Finch.FinchProtocolError @finch (t .= 0; for i=_, j=_; t[i, j] = A[i, j] end)
    end

    let
        t = Fiber!(Dense(SparseList(Element(0.0))))
        B = SparseMatrixCSC([0 0 0 0; -1 -1 -1 -1; -2 -2 -2 -2; -3 -3 -3 -3])
        A = dropdefaults(copyto!(Fiber!(Dense(SparseList(Element(0.0)))), B))
        @test_logs (:warn, "Performance Warning: non-concordant traversal of t[i, j] (hint: most arrays prefer column major or first index fast, run in fast mode to ignore this warning)") match_mode=:any @test_throws Finch.FinchProtocolError @finch (t .= 0; for i=_, j=_; t[i, j] = A[i, j] end)
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/129

    let
        a = Fiber!(Dense(Element(0)), [1, 3, 7, 2])

        x = Scalar((0, 0))
        @finch for i=_; x[] <<maxby>>= (a[i], i) end
        @test x[][2] == 3

        y = Scalar(0 => 0)
        @finch for i=_; y[] <<maxby>>= a[i] => i end
        @test y[][2] == 3
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/124

    let
        A = sparse([3, 4, 3, 4], [1, 2, 3, 3], [1.1, 2.2, 3.3, 4.4], 4, 3)

        B = Fiber!(Dense(SparseList(Element(0.0))))

        @finch (B .= 0; for j=_, i=_; B[i, j] = A[i, j] end)

        @test Structure(B) == Structure(fiber(A))

        v = SparseVector(10, [1, 6, 7, 9], [1.1, 2.2, 3.3, 4.4])

        w = Fiber!(SparseList(Element(0.0)))

        @finch (w .= 0; for i=_; w[i] = v[i] end)

        @test Structure(w) == Structure(fiber(v))
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/99
    let 
        m = 4; n = 3; ptr_c = [0, 3, 3, 5]; idx_c = [1, 2, 3, 0, 2]; val_c = [1.1, 2.2, 3.3, 4.4, 5.5];

        ptr_jl = unsafe_wrap(Array, reinterpret(Ptr{CIndex{Int}}, pointer(ptr_c)), length(ptr_c); own = false)
        idx_jl = unsafe_wrap(Array, reinterpret(Ptr{CIndex{Int}}, pointer(idx_c)), length(idx_c); own = false)
        A = Fiber(Dense(SparseList{CIndex{Int}}(Element{0.0, Float64, CIndex{Int}}(val_c), m, ptr_jl, idx_jl), n))

        @test A == [0.0 0.0 4.4; 1.1 0.0 0.0; 2.2 0.0 5.5; 3.3 0.0 0.0]
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/121
    let
        io = IOBuffer()
        y = [2.0, Inf, Inf, 1.0, 3.0, Inf]
        yf = Fiber!(SparseList(Element(Inf)), y)
        println(io, "Fiber!(SparseList(Element(Inf)), $y):")
        println(io, yf)

        x = Scalar(Inf)

        @test check_output("specialvals_minimum_inf.jl", @finch_code (for i=_; x[] <<min>>= yf[i] end))
        @finch for i=_; x[] <<min>>= yf[i] end
        @test x[] == 1.0

        @test check_output("specialvals_repr_inf.txt", String(take!(io)))

        io = IOBuffer()
        y = [2.0, NaN, NaN, 1.0, 3.0, NaN]
        yf = Fiber!(SparseList(Element(NaN)), y)
        println(io, "Fiber!(SparseList(Element(NaN)), $y):")
        println(io, yf)

        x = Scalar(Inf)

        @test check_output("specialvals_minimum_nan.jl", @finch_code (for i=_; x[] <<min>>= yf[i] end))
        @finch for i=_; x[] <<min>>= yf[i] end
        @test isequal(x[], NaN)

        @test check_output("specialvals_repr_nan.txt", String(take!(io)))

        io = IOBuffer()
        y = [2.0, missing, missing, 1.0, 3.0, missing]
        yf = Fiber!(SparseList(Element{missing, Union{Float64,Missing}}()), y)
        println(io, "Fiber!(SparseList(Element(missing)), $y):")
        println(io, yf)

        x = Scalar(Inf)

        @test check_output("specialvals_minimum_missing.jl", @finch_code (for i=_; x[] <<min>>= yf[i] end))
        @finch for i=_; x[] <<min>>= coalesce(yf[i], missing, Inf) end
        @test x[] == 1.0

        @test check_output("specialvals_repr_missing.txt", String(take!(io)))

        io = IOBuffer()
        y = [2.0, nothing, nothing, 1.0, 3.0, Some(1.0), nothing]
        yf = Fiber!(SparseList(Element{nothing, Union{Float64,Nothing,Some{Float64}}}()), y)
        println(io, "Fiber!(SparseList(Element(nothing)), $y):")
        println(io, yf)

        x = Scalar(Inf)

        @test check_output("specialvals_minimum_nothing.jl", @finch_code (for i=_; x[] <<min>>= something(yf[i], nothing, Inf) end))
        @finch for i=_; x[] <<min>>= something(yf[i], nothing, Inf) end
        @test x[] == 1.0

        @test check_output("specialvals_repr_nothing.txt", String(take!(io)))
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/118

    let
        io = IOBuffer()
        A = [0.0 1.0 0.0 2.0; 0.0 1.0 0.0 3.0; 0.0 0.0 2.0 0.0]
        B = Fiber!(Dense(SparseList(Element(0.0))), A)
        C = Fiber!(Dense(SparseList(Element(Inf))))
        @finch (C .= Inf; for j = _, i = _ C[i, j] = ifelse(B[i, j] == 0, Inf, B[i, j]) end)

        println(io, "A :", A)
        println(io, "C :", C)
        println(io, "redefault!(B, Inf) :", redefault!(B, Inf))
        println(io, redefault!(B, Inf))
        println(io, C)
        @test Structure(C) == Structure(redefault!(B, Inf))
        @test check_output("issue118.txt", String(take!(io)))
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/97

    let
        @test_throws DimensionMismatch A = Fiber!(Dense(SparseList(Element(0.0))), [0, 1])
        A = fsprand((10, 11), 0.5)
        B = Fiber!(Dense(SparseList(Element(0.0))))
        C = fsprand((10, 10), 0.5)
        @test_throws DimensionMismatch @finch (A .= 0; for j=_, i=_; A[i, j] = B[i] end)
        @test_throws DimensionMismatch @finch (A .= 0; for j=_, i=_; A[i] = B[i, j] end)
        @test_throws DimensionMismatch @finch (A .= 0; for j=_, i=_; A[i, j] = B[i, j] + C[i, j] end)
        @test_throws DimensionMismatch copyto!(Fiber!(SparseList(Element(0.0))), A)
        @test_throws DimensionMismatch dropdefaults!(Fiber!(SparseList(Element(0.0))), A)

        A = fsprand((10, 11), 0.5)
        B = fsprand((10, 10), 0.5)
        @test_throws Finch.FinchProtocolError @finch for j=_, i=_; A[i, j] = B[i, follow(j)] end
        @test_throws ArgumentError Fiber!(SparseCOO(Element(0.0)))
        @test_throws ArgumentError Fiber!(SparseHash(Element(0.0)))
        @test_throws ArgumentError Fiber!(SparseList(Element("hello")))
    end

    #https://github.com/willow-ahrens/Finch.jl/pull/197

    let
        io = IOBuffer()

        @repl io A = Fiber!(Dense(SparseTriangle{2}(Element(0.0))), collect(reshape(1:27, 3, 3, 3)))
        @repl io C = Scalar(0)
        @repl io @finch for k=_, j=_, i=_; C[] += A[i, j, k] end

        check_output("pull197.txt", String(take!(io)))
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/70

    let
        A = Fiber!(Dense(SparseList(Element(0.0))))
        B = typeof(Fiber!(Dense(SparseList(Element(0.0)))))
        eval(@finch_kernel function copy_array(A, B)
            A .= 0
            for j = _, i = _
                A[i, j] = B[i, j]
            end
        end)
        C = Fiber!(Dense(SparseList(Element(0.0))))
        D = Fiber!(Dense(SparseList(Element(0.0))), fsprand((5, 5), 0.5))
        C = copy_array(C, D).A
        @test C == D
    end

        #https://github.com/willow-ahrens/Finch.jl/issues/243

    let
        @test_throws Finch.ScopeError (@finch begin
            let x = 0
                let x = 0
                end
            end
        end)

    end

    #https://github.com/willow-ahrens/Finch.jl/issues/278

    let
        A = [1.0 2.0 3.0; 4.0 5.0 6.0; 7.0 8.0 9.0]
        x = Scalar{0.0}()
        @finch (x .= 0; for i = _ x[] += A[i, i] end)
        @test x[] == 15.0
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/267
    let
        A = ones(3, 3)
        B = ones(3, 3)
        C = zeros(3, 3)
        alpha=beta=1
        @finch begin
            for j=_
                for i=_
                    C[i, j] *= beta
                end
                for k=_
                    let foo = alpha * B[k, j]
                        for i=_
                            C[i, j] += foo*A[i, k]
                        end
                    end
                end
            end
        end
        @test C == A * B
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/284
    let
        C = Fiber!(Dense(Dense(Element(0.0))), [1 0; 0 1])
        w = Fiber!(Dense(Dense(Element(0.0))), [0 0; 0 0])
        @finch mode=fastfinch begin 
            for j = _, i = _
                C[i, j] += 1
            end
            for j = _, i = _ 
                w[j, i] = C[i, j] 
            end
            for i = _, j = _
                C[j, i] = w[j, i]
            end
        end
        @test C == [2.0 1.0; 1.0 2.0]
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/286
    let 
        A = [1 0; 0 1]
        #note that A[i, j] is ignored here, as the temp local is never used
        @finch (for j=_, i=_; let temp = A[i, j]; end end)
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/288
    let
        A = zeros(3, 3, 3)
        C = zeros(3, 3, 3)
        X = zeros(3, 3)
        check_output("issue288_concordize_let.jl", @finch_code mode=fastfinch begin
            for k=_, j=_, i=_
                let temp1 = X[i, j]
                    for l=_
                        let temp3 = A[i, l, k]
                            if uptrimask[i+1, l]
                                C[i, j, k] += temp1 * temp3
                            end
                        end
                    end
                end
            end
        end)
        check_output("issue288_concordize_double_let.jl", @finch_code mode=fastfinch begin
            for k=_, j=_, i=_
                let temp1 = X[i, j]
                    for l=_
                        let temp3 = A[i, l, k]
                            if uptrimask[i+1, l]
                                C[i, j, k] += temp1 * temp3
                            end
                        end
                        let temp4 = A[i, l, k]
                            if uptrimask[i+1, l]
                                C[i, j, k] += temp1 * temp4
                            end
                        end
                    end
                end
            end
        end)
    end
end
