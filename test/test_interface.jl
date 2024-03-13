using Finch: AsArray

@testset "interface" begin
    @info "Testing Finch Interface"
    A = Tensor(SparseList(Element(0.0)), fsparse([1, 3, 5, 7, 9], [2.0, 3.0, 4.0, 5.0, 6.0], (10,)))
    B = Tensor(SparseList(Element(0.0)), A)
    @test A == B

    A = [0.0 0.0 0.0 0.0; 1.0 0.0 0.0 1.0]
    B = Tensor(Dense(SparseList(Element(0.0))), A)
    C = Tensor(Dense(Dense(Element(0.0))), A)
    @test A == B

    A = [0 0; 0 0]
    B = Tensor(Dense(Dense(Element(0.0))), A)
    @test A == B

    A = Tensor(Dense(Element(0.0)), [0, 0, 0, 0])
    B = Tensor(Dense(Element(0.0)), [0, 0, 0, 0, 0])
    @test size(A) != size(B) && A != B

    A = [0 0 0 0 1 0 0 1]
    B = Tensor(Dense(SparseList(Element(0))), [0 0 0 0; 1 0 0 1])
    @test size(A) != size(B) && A != B

    A = Tensor(Dense(SparseList(Element(0.0))), [1 0 0 0; 1 1 0 0; 1 1 1 0])
    B = [0 0 0 0; 1 1 0 0; 1 1 1 0]
    @test size(A) == size(B) && A != B
    C = Tensor(Dense(SparseList(Element(0.0))), [0 0 0 0; 1 1 0 0; 1 1 1 0])
    @test B == C

    A = [NaN, 0.0, 3.14, 0.0]
    B = Tensor(SparseList(Element(0.0)), [NaN, 0.0, 3.14, 0.0])
    C = Tensor(SparseList(Element(0.0)), [NaN, 0.0, 3.14, 0.0])
    D = [1.0, 2.0, 4.0, 8.0]
    @test isequal(A, B)
    @test isequal(A, C)
    @test isequal(B, C)
    @test isequal(B, A)
    @test !isequal(A, D)
    @test A != B

    let
        io = IOBuffer()
        println(io, "getindex tests")

        A = Tensor(SparseList(Dense(SparseList(Element{0.0}(collect(1:30).* 1.01), 5, [1, 3, 6, 8, 12, 14, 17, 20, 24, 27, 27, 28, 31], [2, 3, 3, 4, 5, 2, 3, 1, 3, 4, 5, 2, 4, 2, 4, 5, 2, 3, 5, 1, 3, 4, 5, 2, 3, 4, 2, 1, 2, 3]), 3), 4, [1, 5], [1, 2, 3, 4]))

        print(io, "A = ")
        show(io, MIME("text/plain"), A)
        println(io)

        for inds in [(1, 2, 3), (1, 1, 1), (1, :, 3), (:, 1, 3), (:, :, 3), (:, :, :)]
            print(io, "A["); join(io, inds, ","); print(io, "] = ")
            show(io, MIME("text/plain"), A[inds...])
            println(io)
        end

        @test check_output("base/getindex.txt", String(take!(io)))
    end

    let
        io = IOBuffer()
        println(io, "setindex! tests")

        @repl io A = Tensor(Dense(Dense(Element(0.0))), 10, 12)
        @repl io A[1, 4] = 3
        @repl io AsArray(A)
        @repl io A[4:6, 6] = 5:7
        @repl io AsArray(A)
        @repl io A[9, :] = 1:12
        @repl io AsArray(A)

        @test check_output("base/setindex.txt", String(take!(io)))
    end

    let
        io = IOBuffer()
        println(io, "broadcast tests")

        @repl io A = Tensor(Dense(SparseList(Element(0.0))), [0.0 0.0 4.4; 1.1 0.0 0.0; 2.2 0.0 5.5; 3.3 0.0 0.0])
        @repl io B = [1, 2, 3, 4]
        @repl io C = A .+ B true
        @repl io AsArray(C)
        @repl io D = A .* B true
        @repl io AsArray(D)
        @repl io E = ifelse.(A .== 0, 1, 2)
        @repl io AsArray(E)

        @test check_output("base/broadcast.txt", String(take!(io)))
    end

    let
        io = IOBuffer()
        println(io, "reduce tests")

        @repl io A = Tensor(Dense(SparseList(Element(0.0))), [0.0 0.0 4.4; 1.1 0.0 0.0; 2.2 0.0 5.5; 3.3 0.0 0.0])
        @repl io reduce(+, A, dims=(1,))
        @repl io reduce(+, A, dims=1)
        @repl io reduce(+, A, dims=(2,))
        @repl io reduce(+, A, dims=2)
        @repl io reduce(+, A, dims=(1,2))
        @repl io reduce(+, A, dims=:)

        @test check_output("base/reduce.txt", String(take!(io)))
    end

    let
        io = IOBuffer()
        println(io, "countstored tests")

        @repl io A = Tensor(Dense(SparseList(Element(0.0))), [0.0 0.0 4.4; 1.1 0.0 0.0; 2.2 0.0 5.5; 3.3 0.0 0.0])
        @repl io countstored(A)
        @repl io A = Tensor(SparseCOO{2}(Element(0.0)), [0.0 0.0 4.4; 1.1 0.0 0.0; 2.2 0.0 5.5; 3.3 0.0 0.0])
        @repl io countstored(A)
        @repl io A = Tensor(Dense(Dense(Element(0.0))), [0.0 0.0 4.4; 1.1 0.0 0.0; 2.2 0.0 5.5; 3.3 0.0 0.0])
        @repl io countstored(A)
        @repl io A = Tensor(SparseList(Dense(Element(0.0))), [0.0 0.0 4.4; 1.1 0.0 0.0; 2.2 0.0 5.5; 3.3 0.0 0.0])
        @repl io countstored(A)

        @test check_output("base/countstored.txt", String(take!(io)))
    end

    let
        io = IOBuffer()
        println(io, "+,-, *, / tests")

        @repl io A = Tensor(Dense(SparseList(Element(0.0))), [0.0 0.0 4.4; 1.1 0.0 0.0; 2.2 0.0 5.5; 3.3 0.0 0.0])
        @repl io A + 1
        @repl io 1 + A
        @repl io A + A
        @repl io 2 * A
        @repl io A * 3
        @repl io A / 3
        @repl io 3 / A

        @test check_output("base/asmd.txt", String(take!(io)))
    end

    let
        A_ref = [0.0 0.0 4.4; 1.1 0.0 0.0; 2.2 0.0 5.5; 3.3 0.0 0.0]
        A_ref = A_ref * floatmax()/sum(A_ref)
        A= Tensor(Dense(SparseList(Element(0.0))), A_ref)
        @test sum(A) == sum(A_ref)
        @test minimum(A) == minimum(A_ref)
        @test maximum(A) == maximum(A_ref)
        @test extrema(A) == extrema(A_ref)
        @test norm(A) == norm(A_ref)
        @test norm(A, -Inf) == norm(A_ref, -Inf)
        @test norm(A, 0) == norm(A_ref, 0)
        @test norm(A, 1) == norm(A_ref, 1)
        @test norm(A, 1.5) == norm(A_ref, 1.5)
        @test norm(A, Inf) == norm(A_ref, Inf)
    end

    A = Tensor(Dense(SparseList(Element(0.0))), [0.0 0.0 4.4; 1.1 0.0 0.0; 2.2 0.0 5.5; 3.3 0.0 0.0])
    B = Tensor(Dense(SparseList(Element(0.0))), [0.0 0.0 4.4; 1.1 0.0 0.0; 2.2 0.0 5.5; 3.3 0.0 0.0])
    C = lazy(A)
    D = lazy(B)
    E = (C + D) * 0.5
    F = compute(E)
    @test F == A

    let
        A = Tensor(Dense(SparseList(Element(0))), [0 0 44; 11 0 0; 22 00 55; 33 0 0])
        B = Tensor(Dense(SparseList(Element(0))), [0 0 44; 11 0 0; 22 00 55; 33 0 0])
        c_correct = Tensor(Dense(Dense(Element(0))), [1936 0 2420 0; 0 121 242 363; 2420 242 3509 726; 0 363 726 1089])
        c = compute(tensordot(lazy(A), lazy(B), ((2, ), (2,)), init=0))
        @test c == c_correct
    end
end
