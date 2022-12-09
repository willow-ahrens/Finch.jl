@testset "issues" begin
    #https://github.com/willow-ahrens/Finch.jl/issues/51
    let
        x = @fiber d(3, e(0.0, [1, 2, 3]))
        y = Scalar{0.0}()
        @finch @loop i j y[] += min(x[i], x[j])
        @test y[] == 14
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/53
    let
        x = @fiber sl(10, [1, 5], [1, 3, 7, 8], p())
        y = Scalar{0.0}()
        @finch @loop i y[] += ifelse(x[i], 3, -1)
        @test y[] == 6
        a = 3
        b = -1
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/59
    let
        B = @fiber d(3, e(0, [2, 4, 5]))
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
end