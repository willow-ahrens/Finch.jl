@testset "issues" begin
    #https://github.com/willow-ahrens/Finch.jl/issues/51
    let
        x = Fiber(Dense(3, Element(0.0, [1, 2, 3])), Environment())
        y = Scalar{0.0}()
        @finch @loop i j y[] += min(x[i], x[j])
        @test y[] == 14
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/53
    let
        x = Fiber(SparseList(10, [1, 5], [1, 3, 7, 8], Pattern()), Environment())
        y = Scalar{0.0}()
        @finch @loop i y[] += ifelse(x[i], 3, -1)
        @test y[] == 6
        a = 3
        b = -1
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/59
    let
        B = Fiber(DenseLevel(3, Element(0, [2, 4, 5])))
        A = @fiber d(6, e(0))
        @finch @loop i A[B[i]] = i
        @test reference_isequal(A, [0, 1, 0, 2, 3, 0])
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/68
    let
        N = 3
        edges = dropdefaults!(@fiber(d(sl(e(false)))), [0 1 1; 1 0 1; 1 0 0])
        frontier_list = dropdefaults!(@fiber(sl(e(false))), [0 1 1])
        old_num_paths = copyto!(@fiber(d(e(0))), [3, 3, 3])
        old_visited = copyto!(@fiber(d(e(false))), [1, 0, 0])
        new_frontier = @fiber(d(e(false)))
        new_visited = @fiber(d(e(false)))
        B = @fiber(d(e(0)))
        @finch @loop j k begin
            new_frontier[j] <<$(Finch.or)>>= edges[j,k] && frontier_list[k] && !(old_visited[j])
            new_visited[j] <<$(Finch.and)>>= old_visited[j] || edges[j,k] && frontier_list[k] && !(old_visited[j])
            B[j] += edges[j,k] && frontier_list[k] && old_num_paths[k] && !(old_visited[j])
       end
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/61
    I = copyto!(@fiber(rl{0, Int64, Int64}()), [1, 1, 1, 3, 3, 1, 5, 5, 5])
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
    A = copyto!(@fiber(d{Int64}(d{Int64}(e(0)))), A)
    B = @fiber(d{Int64}(e(0)))
    
    @test diff("fiber_as_idx.jl", @finch_code @loop i B[i] = A[i, I[i]])
    @finch @loop i B[i] = A[i, I[i]]

    B_ref = Fiber(Dense{Int64}(9, Element(0, [11, 21, 31, 43, 53, 61, 75, 85, 95])), Environment())

    @test isstructequal(B, B_ref)
    
    
end