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
        @finch @loop i A[B[i]] = i
        @test reference_isequal(A, [0, 1, 0, 2, 3, 0])
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/68
    let
        N = 3
        edges = dropdefaults!(@fiber(d(sl(e(false)))), [0 1 1; 1 0 1; 1 0 0])
        frontier_list = dropdefaults!(@fiber(sl(e(false))), [0, 1, 1])
        old_num_paths = copyto!(@fiber(d(e(0))), [3, 3, 3])
        old_visited = copyto!(@fiber(d(e(false))), [1, 0, 0])
        new_frontier = @fiber(d(e(false)))
        new_visited = @fiber(d(e(false)))
        B = @fiber(d(e(0)))
        @finch @loop k j begin
            new_frontier[j] <<$(Finch.or)>>= edges[j,k] && frontier_list[k] && !(old_visited[j])
            new_visited[j] <<$(Finch.and)>>= old_visited[j] || edges[j,k] && frontier_list[k] && !(old_visited[j])
            B[j] += edges[j,k] && frontier_list[k] && (old_num_paths[k]!=1) && !(old_visited[j])
       end
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
    
    @test check_output("fiber_as_idx.jl", @finch_code @loop i B[i] = A[I[i], i])
    @finch @loop i B[i] = A[I[i], i]

    @test B == [11, 12, 93, 34, 35]

    #https://github.com/willow-ahrens/Finch.jl/issues/101
    let
        t = @fiber(sl(sl(e(0.0))))
        X = @fiber(sl(sl(e(0.0))))
        A = @fiber(sl(sl(e(0.0))), SparseMatrixCSC([0 0 0 0; -1 -1 -1 -1; -2 -2 -2 -2; -3 -3 -3 -3]))
        @test_throws DimensionMismatch @finch @loop j i t[i, j] = min(X[i, j],  A[i, j])
        X = @fiber(sl(sl(e(0.0), 4), 4))
        @finch @loop j i t[i, j] = min(X[i, j],  A[i, j])
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
        @finch MyAlgebra() @loop j i t[i, j] = f(A[i,j], A[i,j], A[i,j])
        @test t == B .* 3
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/115

    let
        t = @fiber(sl(sl(e(0.0))))
        B = SparseMatrixCSC([0 0 0 0; -1 -1 -1 -1; -2 -2 -2 -2; -3 -3 -3 -3])
        A = dropdefaults(copyto!(@fiber(sl(sl(e(0.0)))), B))
        @test_throws Finch.FormatLimitation @finch MyAlgebra() @loop i j t[i, j] = A[i, j]
    end

    let
        t = @fiber(d(sl(e(0.0))))
        B = SparseMatrixCSC([0 0 0 0; -1 -1 -1 -1; -2 -2 -2 -2; -3 -3 -3 -3])
        A = dropdefaults(copyto!(@fiber(d(sl(e(0.0)))), B))
        @test_throws Finch.FormatLimitation @finch MyAlgebra() @loop i j t[i, j] = A[i, j]
    end

end