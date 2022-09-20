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
        @test diff("ifelse53.jl", @finch_code @loop i y[] += ifelse(x[i], $a, $b))
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/59
    let
        B = @fiber d(3, e(0, [2, 4, 5]))
        A = @fiber d(6, e(0))
        @finch @loop i A[B[i]] = i
        @test reference_isequal(A, [0, 1, 0, 2, 3, 0])
    end
end