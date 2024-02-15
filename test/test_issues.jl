using SparseArrays
using CIndices

@testset "issues" begin
    @info "Testing Github Issues"

    #https://github.com/willow-ahrens/Finch.jl/issues/358
    let
        A = Tensor(Dense(SparseList(Element(0))), [
          0 0 0 0 0;
          1 0 0 0 0;
          0 0 0 0 0
        ])
        B = Tensor(Dense(SparseList(Element(0))), [
          0 0 0 0 0;
          0 0 1 0 0;
          1 0 0 0 0
        ])
        C = Tensor(Dense(SparseList(Element(0))), [
          0 0 0 0 0;
          0 0 0 1 0;
          0 0 0 0 0
        ])
        D_ref = A .+ B
        E_ref = D_ref .+ C
        for D in [
            Tensor(Dense(SparseList(Element(0)))),
            Tensor(Dense(SparseHash{1}(Element(0)))),
            Tensor(Dense(SparseDict(Element(0)))),
            Tensor(Dense(Dense(Element(0)))),
        ]
            E = deepcopy(D)
            @finch mode=fastfinch begin
                D .= 0
                E .= 0
                for j = _, i = _
                    E[i, j] += A[i, j]
                end
                for j = _, i = _
                    E[i, j] += B[i, j]
                end
                for j = _, i = _
                    D[i, j] += E[i, j]
                end
                for j = _, i = _
                    E[i, j] += C[i, j]
                end
                return (D, E)
            end
            @test D == D_ref
            @test E == E_ref
        end
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/51
    let
        x = Tensor(Dense(Element(0.0)), [1, 2, 3])
        y = Scalar{0.0}()
        @finch for i=_, j=_; y[] += min(x[i], x[j]) end
        @test y[] == 14
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/53
    let
        x = Tensor(SparseList(Pattern()), fsparse([1, 3, 7, 8], [true, true, true, true], (10,)))
        y = Scalar{0.0}()
        @finch for i=_; y[] += ifelse(x[i], 3, -1) end
        @test y[] == 6
        a = 3
        b = -1
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/59
    let
        B = Tensor(Dense(Element(0)), [2, 4, 5])
        A = Tensor(Dense(Element(0)), 6)
        @finch (A .= 0; for i=_; A[B[i]] = i end; return A)
        @test reference_isequal(A, [0, 1, 0, 2, 3, 0])
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/61
    I = copyto!(Tensor(RepeatRLE(0)), [1, 1, 9, 3, 3])
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
    A = copyto!(Tensor(Dense(Dense(Element(0)))), A)
    B = Tensor(Dense(Element(0)))
    
    @test check_output("fiber_as_idx.jl", @finch_code (B .= 0; for i=_; B[i] = A[I[i], i] end; return B))
    @finch (B .= 0; for i=_; B[i] = A[I[i], i] end; return B)

    @test B == [11, 12, 93, 34, 35]

    #https://github.com/willow-ahrens/Finch.jl/issues/101
    let
        t = Tensor(SparseList(SparseList(Element(0.0))))
        X = Tensor(SparseList(SparseList(Element(0.0))))
        A = Tensor(SparseList(SparseList(Element(0.0))), SparseMatrixCSC([0 0 0 0; -1 -1 -1 -1; -2 -2 -2 -2; -3 -3 -3 -3]))
        @test_throws DimensionMismatch @finch (t .= 0; for j=_, i=_; t[i, j] = min(X[i, j],  A[i, j]) end; return t)
        X = Tensor(SparseList(SparseList(Element(0.0))), 4, 4)
        @finch (t .= 0; for j=_, i=_; t[i, j] = min(X[i, j],  A[i, j]) end; return t)
        @test t == A
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/115

    let
        function f(a::Float64, b::Float64, c::Float64)
            return a+b+c
        end 
        struct MyAlgebra115 <: Finch.AbstractAlgebra end
        Finch.virtualize(ex, ::Type{MyAlgebra115}, ::Finch.JuliaContext) = MyAlgebra115()
        t = Tensor(SparseList(SparseList(Element(0.0))))
        B = SparseMatrixCSC([0 0 0 0; -1 -1 -1 -1; -2 -2 -2 -2; -3 -3 -3 -3])
        A = dropdefaults(copyto!(Tensor(SparseList(SparseList(Element(0.0)))), B))
        @finch algebra=MyAlgebra115() (t .= 0; for j=_, i=_; t[i, j] = f(A[i,j], A[i,j], A[i,j]) end; return t)
        @test t == B .* 3
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/115

    let
        t = Tensor(SparseList(SparseList(Element(0.0))))
        B = SparseMatrixCSC([0 0 0 0; -1 -1 -1 -1; -2 -2 -2 -2; -3 -3 -3 -3])
        A = dropdefaults(copyto!(Tensor(SparseList(SparseList(Element(0.0)))), B))
        @test_logs (:warn, "Performance Warning: non-concordant traversal of t[i, j] (hint: most arrays prefer column major or first index fast, run in fast mode to ignore this warning)") match_mode=:any @test_throws Finch.FinchProtocolError @finch (t .= 0; for i=_, j=_; t[i, j] = A[i, j] end; return t)
    end

    let
        t = Tensor(Dense(SparseList(Element(0.0))))
        B = SparseMatrixCSC([0 0 0 0; -1 -1 -1 -1; -2 -2 -2 -2; -3 -3 -3 -3])
        A = dropdefaults(copyto!(Tensor(Dense(SparseList(Element(0.0)))), B))
        @test_logs (:warn, "Performance Warning: non-concordant traversal of t[i, j] (hint: most arrays prefer column major or first index fast, run in fast mode to ignore this warning)") match_mode=:any @test_throws Finch.FinchProtocolError @finch (t .= 0; for i=_, j=_; t[i, j] = A[i, j] end; return t)
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/129

    let
        a = Tensor(Dense(Element(0)), [1, 3, 7, 2])

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

        B = Tensor(Dense(SparseList(Element(0.0))))

        @finch (B .= 0; for j=_, i=_; B[i, j] = A[i, j] end; return B)

        @test Structure(B) == Structure(Tensor(A))

        v = SparseVector(10, [1, 6, 7, 9], [1.1, 2.2, 3.3, 4.4])

        w = Tensor(SparseList(Element(0.0)))

        @finch (w .= 0; for i=_; w[i] = v[i] end; return w)

        @test Structure(w) == Structure(Tensor(v))
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/99
    let 
        m = 4; n = 3; ptr_c = [0, 3, 3, 5]; idx_c = [1, 2, 3, 0, 2]; val_c = [1.1, 2.2, 3.3, 4.4, 5.5];

        ptr_jl = OffByOneVector(ptr_c)
        idx_jl = OffByOneVector(idx_c)
        A = Tensor(Dense(SparseList{Int}(Element{0.0, Float64, Int}(val_c), m, ptr_jl, idx_jl), n))

        @test A == [0.0 0.0 4.4; 1.1 0.0 0.0; 2.2 0.0 5.5; 3.3 0.0 0.0]
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/121
    let
        io = IOBuffer()
        y = [2.0, Inf, Inf, 1.0, 3.0, Inf]
        yf = Tensor(SparseList(Element(Inf)), y)
        println(io, "Tensor(SparseList(Element(Inf)), $y):")
        println(io, yf)

        x = Scalar(Inf)

        @test check_output("specialvals_minimum_inf.jl", @finch_code (for i=_; x[] <<min>>= yf[i] end))
        @finch for i=_; x[] <<min>>= yf[i] end
        @test x[] == 1.0

        @test check_output("specialvals_repr_inf.txt", String(take!(io)))

        io = IOBuffer()
        y = [2.0, NaN, NaN, 1.0, 3.0, NaN]
        yf = Tensor(SparseList(Element(NaN)), y)
        println(io, "Tensor(SparseList(Element(NaN)), $y):")
        println(io, yf)

        x = Scalar(Inf)

        @test check_output("specialvals_minimum_nan.jl", @finch_code (for i=_; x[] <<min>>= yf[i] end))
        @finch for i=_; x[] <<min>>= yf[i] end
        @test isequal(x[], NaN)

        @test check_output("specialvals_repr_nan.txt", String(take!(io)))

        io = IOBuffer()
        y = [2.0, missing, missing, 1.0, 3.0, missing]
        yf = Tensor(SparseList(Element{missing, Union{Float64,Missing}}()), y)
        println(io, "Tensor(SparseList(Element(missing)), $y):")
        println(io, yf)

        x = Scalar(Inf)

        @test check_output("specialvals_minimum_missing.jl", @finch_code (for i=_; x[] <<min>>= yf[i] end))
        @finch for i=_; x[] <<min>>= coalesce(yf[i], missing, Inf) end
        @test x[] == 1.0

        @test check_output("specialvals_repr_missing.txt", String(take!(io)))

        io = IOBuffer()
        y = [2.0, nothing, nothing, 1.0, 3.0, Some(1.0), nothing]
        yf = Tensor(SparseList(Element{nothing, Union{Float64,Nothing,Some{Float64}}}()), y)
        println(io, "Tensor(SparseList(Element(nothing)), $y):")
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
        B = Tensor(Dense(SparseList(Element(0.0))), A)
        C = Tensor(Dense(SparseList(Element(Inf))))
        @finch (C .= Inf; for j = _, i = _ C[i, j] = ifelse(B[i, j] == 0, Inf, B[i, j]) end; return C)

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
        @test_throws DimensionMismatch A = Tensor(Dense(SparseList(Element(0.0))), [0, 1])
        A = fsprand(10, 11, 0.5)
        B = Tensor(Dense(SparseList(Element(0.0))))
        C = fsprand(10, 10, 0.5)
        @test_throws DimensionMismatch @finch (A .= 0; for j=_, i=_; A[i, j] = B[i] end; return A)
        @test_throws DimensionMismatch @finch (A .= 0; for j=_, i=_; A[i] = B[i, j] end; return A)
        @test_throws DimensionMismatch @finch (A .= 0; for j=_, i=_; A[i, j] = B[i, j] + C[i, j] end; return A)
        @test_throws DimensionMismatch copyto!(Tensor(SparseList(Element(0.0))), A)
        @test_throws DimensionMismatch dropdefaults!(Tensor(SparseList(Element(0.0))), A)

        A = fsprand(10, 11, 0.5)
        B = fsprand(10, 10, 0.5)
        @test_throws Finch.FinchProtocolError @finch for j=_, i=_; A[i, j] = B[i, follow(j)] end
        @test_throws ArgumentError Tensor(SparseCOO(Element(0.0)))
        @test_throws ArgumentError Tensor(SparseHash(Element(0.0)))
        @test_throws ArgumentError Tensor(SparseList(Element("hello")))
    end

    #https://github.com/willow-ahrens/Finch.jl/pull/197

    let
        io = IOBuffer()

        @repl io A = Tensor(Dense(SparseTriangle{2}(Element(0.0))), collect(reshape(1:27, 3, 3, 3)))
        @repl io C = Scalar(0)
        @repl io @finch for k=_, j=_, i=_; C[] += A[i, j, k] end

        check_output("pull197.txt", String(take!(io)))
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/70

    let
        A = Tensor(Dense(SparseList(Element(0.0))))
        B = typeof(Tensor(Dense(SparseList(Element(0.0)))))
        eval(@finch_kernel function copy_array(A, B)
            A .= 0
            for j = _, i = _
                A[i, j] = B[i, j]
            end
            return A
        end)
        C = Tensor(Dense(SparseList(Element(0.0))))
        D = Tensor(Dense(SparseList(Element(0.0))), fsprand(5, 5, 0.5))
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
        @finch (x .= 0; for i = _ x[] += A[i, i] end; return x)
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
        C = Tensor(Dense(Dense(Element(0.0))), [1 0; 0 1])
        w = Tensor(Dense(Dense(Element(0.0))), [0 0; 0 0])
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

    #https://github.com/willow-ahrens/Finch.jl/issues/291
    let
        A = [1 2 3; 4 5 6; 7 8 9]
        x = Scalar(0.0)
        @finch mode=fastfinch for j=_, i=_; if i < j x[] += A[i, j] end end
        @test x[] == 11.0

        @finch mode=fastfinch (x .= 0; for i=_, j=_; if i < j x[] += A[j, i] end end)
        @test x[] == 19.0

        @finch mode=fastfinch (x .= 0; for j=_, i=_; if i <= j x[] += A[i, j] end end)
        @test x[] == 26.0

        @finch mode=fastfinch (x .= 0; for i=_, j=_; if i <= j x[] += A[j, i] end end)
        @test x[] == 34.0

        @finch mode=fastfinch (x .= 0; for j=_, i=_; if i > j x[] += A[i, j] end end)
        @test x[] == 19.0

        @finch mode=fastfinch (x .= 0; for i=_, j=_; if i > j x[] += A[j, i] end end)
        @test x[] == 11.0

        @finch mode=fastfinch (x .= 0; for j=_, i=_; if i >= j x[] += A[i, j] end end)
        @test x[] == 34.0

        @finch mode=fastfinch (x .= 0; for i=_, j=_; if i >= j x[] += A[j, i] end end)
        @test x[] == 26.0

        @finch mode=fastfinch (x .= 0; for j=_, i=_; if i == j x[] += A[i, j] end end)
        @test x[] == 15.0

        @finch mode=fastfinch (x .= 0; for i=_, j=_; if i == j x[] += A[j, i] end end)
        @test x[] == 15.0

        @finch mode=fastfinch (x .= 0; for j=_, i=_; if i != j x[] += A[i, j] end end)
        @test x[] == 30.0

        @finch mode=fastfinch (x .= 0; for i=_, j=_; if i != j x[] += A[j, i] end end)
        @test x[] == 30.0
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

    let
        A = Tensor(Dense(Dense(SparseList(Element(0.0)))), fsprand(10, 10, 10, 0.1))
        C = Tensor(Dense(Dense(Dense(Element(0.0)))), zeros((10, 10, 10)))
        X = Tensor(Dense(Dense(Element(0.0))), rand(10, 10))
        temp2 = Scalar(0.0)
        @finch begin
            for l=_, j=_, i=_
                let temp1 = X[i, j]
                    temp2 .= 0
                    for k=_
                        if uptrimask[k+1, i]
                            C[k, j, l] += temp1 * A[k, i, l]
                        end
                        if uptrimask[k, l]
                            temp2[] += X[k, j] * A[k, i, l]
                        end
                    end
                    C[i, j, l] += temp2[]
                end
            end
        end
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/52
    let
        s = ShortCircuitScalar(false, true)
        x = Tensor(SparseList(Element(false)), [false, true, true, false])
        y = Tensor(SparseList(Element(false)), [false, true, false, true])
        check_output("short_circuit.jl", @finch_code begin
            for i = _
                s[] |= x[i] && y[i]
            end
        end)

        c = Scalar(0)
        check_output("short_circuit_sum.jl", @finch_code begin
            for i = _
                let x_i = x[i]
                    s[] |= x_i && y[i]
                    c[] += x_i
                end
            end
        end)

        A = Tensor(Dense(SparseList(Element(false))), [false true true false; false true false false]')

        t = SparseShortCircuitScalar(false, true)

        check_output("short_circuit_bfs.jl", @finch_code begin
            x .= false
            for j = _
                t .= false
                for i = _
                    t[] |= A[i, j] && y[i]
                end
                x[j] = t[]
            end
        end)
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/313
    let
        edge_matrix = Tensor(SparseList(SparseList(Element(0.0))), 254, 254)
        edge_values = fsprand(254, 254, .001)
        @finch (edge_matrix .= 0; for j=_, i=_; edge_matrix[i,j] = edge_values[i,j]; end)
        output_matrix = Tensor(SparseDict(SparseDict(Element(0.0))), 254, 254)
        @finch (for v_4=_, v_3=_, v_2=_, v_5=_; output_matrix[v_2,v_5] += edge_matrix[v_5, v_4]*edge_matrix[v_2, v_3]*edge_matrix[v_3, v_4]; end)

        a_matrix = [1 0; 0 1]
        a_fiber = Tensor(SparseList(SparseList(Element(0.0))), 2, 2)
        copyto!(a_fiber, a_matrix)
        b_matrix = [0 1; 1 0]
        b_fiber = Tensor(SparseList(SparseList(Element(0.0))), 2, 2)
        copyto!(b_fiber, b_matrix)
        output_tensor = Tensor(SparseDict(SparseDict(Element(0.0))), 2, 2)

        @finch (output_tensor .=0; for j=_,i=_,k=_; output_tensor[i,k] += a_fiber[i,j] * b_fiber[k,j]; end; return output_tensor)
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/319
    let
        x = SparseMatrixCSC(spzeros(2,2))
        @test_throws Finch.FinchProtocolError @finch (x .= 0; return x)
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/321
    let
        A = fsprand(10, 10, 0.1)
        B = sparse(A)
        @test B isa SparseMatrixCSC
        @test B == A
        B = SparseMatrixCSC(A)
        @test B isa SparseMatrixCSC
        @test B == A
        A = fsprand(10, 0.1)
        B = sparse(A)
        @test B isa SparseVector
        @test B == A
        B = SparseVector(A)
        @test B isa SparseVector
        @test B == A
        A = fsprand(10, 10, 0.1)
        B = Array(A)
        @test B isa Array
        @test B == A
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/339
    let
        Output = Tensor(SparseList(Dense(Element(0),1),10))
        Point = Tensor(SparseList(Element{0}([1]), 10, [1,2], [1]))
        Kernel = Tensor(SparseList(Dense(Element{0}([1]),1), 10, [1,2], [2]))

        eval(@finch_kernel function test(Output, Point, Kernel) 
            Output .= 0
            for x = _
                for xx = _
                    for m = _
                        Output[m,x] += Point[x] * Kernel[m,xx]
                    end
                end
            end
            return Output
        end)

        test(Output, Point, Kernel)
        Ans = Tensor(SparseList{Int64}(Dense{Int64}(Element{0, Int64, Int64}([1]), 1), 10, [1, 2], [1]))
        @test Ans == Output
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/385
    let
        c = Scalar(0)
        @finch let a=1, b=2; c[] += a + b end
        @test c[] == 3
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/387

    A = zeros(2, 4, 3)
    A[1,:,:] = [0.0 0.0 4.4; 1.1 0.0 0.0; 0.0 0.0 0.0; 3.3 0.0 0.0]
    A[2,:,:] = [1.0 0.0 0.0; 0.0 0.0 0.0; 0.0 1.0 0.0; 3.3 0.0 0.0]

    permutation = (3, 1, 2)

    new_shape_1 = size(permutedims(A, permutation))

    t = Tensor(Dense(SparseList(SparseList(Element(0.0)))), A)
    st = swizzle(t, permutation...)
    # materialize swizzle
    new_shape_2 = size(Tensor(Dense(SparseList(SparseList(Element(0.0)))), st))

    @test new_shape_1 == new_shape_2

    @test swizzle(swizzle(zeros(3, 3, 3), 3, 1, 2), 3, 2, 1) isa Finch.SwizzleArray{(2, 1, 3), <:Array}

    #https://github.com/willow-ahrens/Finch.jl/issues/134
    let
        A = Tensor(Dense(Dense(Element(0.0))), rand(3, 3))
        x = Tensor(Dense(Element(0.0)), rand(3))
        y = Tensor(Dense(Element(0.0)), rand(3))

        check_output("cse_symv.jl", @finch_code begin
            for i=_, j=_
                y[i] += A[i, j] * x[j]
                y[j] += A[i, j] * x[i]
            end
        end)
    end
end