using Finch: AsArray

@testset "interface" begin
    @info "Testing Finch Interface"

    @testset "concordize" begin
        using Finch.FinchLogic
        A = alias(:A)
        B = alias(:B)
        C = alias(:C)
        i = field(:i)
        j = field(:j)
        k = field(:k)
        prgm_in = plan(
            query(A, table(0, i, j)),
            query(B, table(0, i, j)),
            query(C, aggregate(+, 0, mapjoin(*,
                reorder(relabel(A, i, k), i, k, j),
                reorder(relabel(B, j, k), i, k, j)
            ))),
            produces(C))
        B_2 = alias(:B_2)
        prgm_out = plan(
            query(A, table(0, i, j)),
            query(B, table(0, i, j)),
            query(B_2, reorder(relabel(B, i, j), j, i)),
            query(C, aggregate(+, 0, mapjoin(*,
                reorder(relabel(A, i, k), i, k, j),
                reorder(relabel(B_2, k, j), i, k, j)
            ))),
            produces(C))
        @test Finch.concordize(prgm_in) == prgm_out
    
        prgm_in = plan(produces())
        prgm_out = plan(produces())
        @test Finch.concordize(prgm_in) == prgm_out
    
        prgm_in = plan(
            query(A, table(0, i, j)),
            query(B, table(0, i, j)),
            query(C, mapjoin(+,
                reorder(relabel(A, i, j), j, i),
                reorder(relabel(B, j, i), i, j)
            )),
            produces(C)
        )
        A_2 = alias(:A_2)
        prgm_out = plan(
            query(A, table(0, i, j)),
            query(A_2, reorder(relabel(A, i, j), j, i)),
            query(B, table(0, i, j)),
            query(B_2, reorder(relabel(B, i, j), j, i)),
            query(C, mapjoin(+,
                reorder(relabel(A_2, j, i), j, i),
                reorder(relabel(B_2, i, j), i, j)
            )),
            produces(C)
        )
        @test Finch.concordize(prgm_in) == prgm_out
    
        prgm_in = plan(
            query(A, table(0, i, j)),
            query(B, reorder(relabel(A, i, j), i, j)),
            produces(B)
        )
        prgm_out = plan(
            query(A, table(0, i, j)),
            query(B, reorder(relabel(A, i, j), i, j)),
            produces(B)
        )
        @test Finch.concordize(prgm_in) == prgm_out
    
        D = alias(:D)
        prgm_in = plan(
            query(A, table(0, i, j)),
            query(B, table(0, i, j)),
            query(C, reorder(relabel(A, i, j), j, i)),
            query(D, reorder(relabel(B, j, i), i, j)),
            produces(C, D)
        )
        prgm_out = plan(
            query(A, table(0, i, j)),
            query(A_2, reorder(relabel(A, i, j), j, i)),
            query(B, table(0, i, j)),
            query(B_2, reorder(relabel(B, i, j), j, i)),
            query(C, reorder(relabel(A_2, j, i), j, i)),
            query(D, reorder(relabel(B_2, i, j), i, j)),
            produces(C, D)
        )
        @test Finch.concordize(prgm_in) == prgm_out
    
        prgm_in = plan(
            query(A, table(0, i, j)),
            query(B, table(0, i, j)),
            query(C, mapjoin(+,
                reorder(relabel(A, i, k), k, i),
                reorder(relabel(B, k, j), j, k)
            )),
            produces(C)
        )
        C_2 = alias(:C_2)
        prgm_out = plan(
            query(A, table(0, i, j)),
            query(A_2, reorder(relabel(A, i, j), j, i)),
            query(B, table(0, i, j)),
            query(B_2, reorder(relabel(B, i, j), j, i)),
            query(C, mapjoin(+,
                reorder(relabel(A_2, k, i), k, i),
                reorder(relabel(B_2, j, k), j, k)
            )),
            produces(C)
        )
        @test Finch.concordize(prgm_in) == prgm_out
    
        prgm_in = plan(
            query(A, table(0)),
            query(B, reorder(relabel(A, ), )),
            produces(B)
        )
        prgm_out = plan(
            query(A, table(0)),
            query(B, reorder(relabel(A, ), )),
            produces(B)
        )
        @test Finch.concordize(prgm_in) == prgm_out
    
        prgm_in = plan(
            query(A, table(0, i, j, k)),
            query(B, reorder(relabel(A, i, j, k), k, j, i)),
            query(C, reorder(relabel(A, i, j, k), j, k, i)),
            query(D, mapjoin(*, 
                reorder(relabel(B, k, j, i), i, j, k),
                reorder(relabel(C, j, k, i), i, j, k)
            )),
            produces(D)
        )
        A_3 = alias(:A_3)
        C_2 = alias(:C_2)
        prgm_out = plan(
            query(A, table(0, i, j, k)),
            query(A_2, reorder(relabel(A, i, j, k), k, j, i)),
            query(A_3, reorder(relabel(A, i, j, k), j, k, i)),
            query(B, reorder(relabel(A_2, k, j, i), k, j, i)),
            query(B_2, reorder(relabel(B, k, j, i), i, j, k)),
            query(C, reorder(relabel(A_3, j, k, i), j, k, i)),
            query(C_2, reorder(relabel(C, j, k, i), i, j, k)),
            query(D, mapjoin(*, 
                reorder(relabel(B_2, i, j, k), i, j, k),
                reorder(relabel(C_2, i, j, k), i, j, k)
            )),
            produces(D)
        )
        @test Finch.concordize(prgm_in) == prgm_out
    end
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

        @test check_output("interface/getindex.txt", String(take!(io)))
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

        @test check_output("interface/setindex.txt", String(take!(io)))
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

        @test check_output("interface/broadcast.txt", String(take!(io)))
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

        @test check_output("interface/reduce.txt", String(take!(io)))
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

        @test check_output("interface/countstored.txt", String(take!(io)))
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

        @test check_output("interface/asmd.txt", String(take!(io)))
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

    let
        A = Tensor(Dense(SparseList(Element(0.0))), [0.0 0.0 4.4; 1.1 0.0 0.0; 2.2 0.0 5.5; 3.3 0.0 0.0])
        B = Tensor(Dense(SparseList(Element(0.0))), [0.0 0.0 4.4; 1.1 0.0 0.0; 2.2 0.0 5.5; 3.3 0.0 0.0])
        C = lazy(A)
        D = lazy(B)
        E = (C + D) * 0.5
        F = compute(E)
        @test F == A
    end

    let
        A = Tensor(Dense(SparseList(Element(0))), [0 0 44; 11 0 0; 22 00 55; 33 0 0])
        B = Tensor(Dense(SparseList(Element(0))), [0 0 44; 11 0 0; 22 00 55; 33 0 0])
        c_correct = Tensor(Dense(Dense(Element(0))), [1936 0 2420 0; 0 121 242 363; 2420 242 3509 726; 0 363 726 1089])
        c = compute(tensordot(lazy(A), lazy(B), ((2, ), (2,)), init=0))
        @test c == c_correct
    end

    let
        A = lazy(Tensor(Dense(SparseList(Element(0))), [0 0 44; 11 0 0; 22 00 55; 33 0 0]))
        B = lazy(Tensor(Dense(SparseList(Element(0))), [0 0 44; 11 0 0; 22 00 55; 33 0 0]'))
        c_correct = Tensor(Dense(Dense(Element(0))), [1936 0 2420 0; 0 121 242 363; 2420 242 3509 726; 0 363 726 1089])
        c = compute(sum(A[:, :, nothing] .* B[nothing, :, :], dims=[2]))
        @test c == c_correct
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/457
    let
        A = zeros(2, 3, 3)
        A[1, :, :] = [1 2 3; 4 5 6; 7 8 9]
        A[2, :, :] = [1 1 1; 2 2 2; 3 3 3]
        perm = (2, 3, 1)
        A_t = permutedims(A, perm)

        A_tns = Tensor(Dense(Dense(Dense(Element(0.0)))), A)
        A_sw = swizzle(A_tns, perm...)
        A_lazy = lazy(A_sw)

        A_result = compute(A_lazy)

        @test Array(A_result) == A_t
        @test permutedims(A_tns, perm) == A_t
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/481
    let
        r = fsprand(1, 10, 10, 0.01)
        r_tns = Tensor(Dense(Dense(Dense(Element(0.0)))), r)
        @test r_tns + r_tns == 2 * r_tns
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/487
    #=
    let
        a = fsprand(100, 1, 0.8)
        b = fsprand(100, 1, 0.8)

        permutedims(broadcast(.+, permutedims(a, (2, 1)), permutedims(b, (2, 1))), (2, 1))  # passes

        a_l = lazy(a)
        b_l = lazy(b)

        plan = permutedims(broadcast(.+, permutedims(a_l, (2, 1)), permutedims(b_l, (2, 1))), (2, 1))
        compute(plan)  # fails
    end
    =#

end
