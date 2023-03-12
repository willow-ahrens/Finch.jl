using Finch: AsArray

@testset "meta" begin
    A = @fiber(sl(e(0.0)), fsparse(([1, 3, 5, 7, 9],), [2.0, 3.0, 4.0, 5.0, 6.0], (10,)))
    B = @fiber(sl(e(0.0)), A)
    @test A == B

    A = [0.0 0.0 0.0 0.0; 1.0 0.0 0.0 1.0]
    B = @fiber(d(sl(e(0.0))), A)
    C = @fiber(d(d(e(0.0))), A)
    @test A == B

    A = [0 0; 0 0]
    B = @fiber(d(d(e(0.0))), A)
    @test A == B

    A = @fiber(d(e(0.0)), [0, 0, 0, 0])
    B = @fiber(d(e(0.0)), [0, 0, 0, 0, 0])
    @test size(A) != size(B) && A != B
        
    A = [0 0 0 0 1 0 0 1]
    B = @fiber(d(sl(e(0))), [0 0 0 0; 1 0 0 1])
    @test size(A) != size(B) && A != B

    A = @fiber(d(sl(e(0.0))), [1 0 0 0; 1 1 0 0; 1 1 1 0])
    B = [0 0 0 0; 1 1 0 0; 1 1 1 0]
    @test size(A) == size(B) && A != B
    C = @fiber(d(sl(e(0.0))), [0 0 0 0; 1 1 0 0; 1 1 1 0])
    @test B == C
    
    A = [NaN, 0.0, 3.14, 0.0]
    B = @fiber(sl(e(0.0)), [NaN, 0.0, 3.14, 0.0])
    C = @fiber(sl(e(0.0)), [NaN, 0.0, 3.14, 0.0])
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

        A = Fiber(SparseList(Dense(SparseList(Element{0.0, Float64}([0.42964847422015195, 0.2031714500596491, 0.15465920941339906, 0.7687749158979389, 0.7341385030927726, 0.24323897961505359, 0.6396769413452026, 0.3155879025843188, 0.9861228587523698, 0.3368597276563293, 0.7453901638237799, 0.3490376859294666, 0.6561601277204799, 0.32494812689888863, 0.8013385593156314, 0.5791333682715981, 0.2327141702137452, 0.0670060505589255, 0.9099846919632137, 0.5770116734780164, 0.20099348394031835, 0.3960969730220265, 0.9141572970982442, 0.579353005205582, 0.010579392993321113, 0.26595745832859163, 0.9155119673442403, 0.3015204766311739, 0.09694825410946628, 0.03454012053008504]), 5, [1, 3, 6, 8, 12, 14, 17, 20, 24, 27, 27, 28, 31], [2, 3, 3, 4, 5, 2, 3, 1, 3, 4, 5, 2, 4, 2, 4, 5, 2, 3, 5, 1, 3, 4, 5, 2, 3, 4, 2, 1, 2, 3]), 3), 4, [1, 5], [1, 2, 3, 4]))

        print(io, "A = ")
        show(io, MIME("text/plain"), A)
        println(io)

        for inds in [(1, 2, 3), (1, 1, 1), (1, :, 3), (:, 1, 3), (:, :, 3), (:, :, :)]
            print(io, "A["); join(io, inds, ","); print(io, "] = ")
            show(io, MIME("text/plain"), A[inds...])
            println(io)
        end
        
        @test check_output("getindex.txt", String(take!(io)))
    end

    let
        io = IOBuffer()
        println(io, "setindex! tests")

        @repl io A = @fiber(d(d(e(0.0), 10), 12))
        @repl io A[1, 4] = 3
        @repl io AsArray(A)
        @repl io A[4:6, 6] = 5:7
        @repl io AsArray(A)
        @repl io A[9, :] = 1:12
        @repl io AsArray(A)
        
        @test check_output("setindex.txt", String(take!(io)))
    end

    let
        io = IOBuffer()
        println(io, "broadcast tests")

        @repl io A = @fiber(d(sl(e(0.0), 10), 12))
        @repl io B = rand(10)
        @repl io C = A .+ B
        
        @test check_output("broadcast.txt", String(take!(io)))
    end
    
end