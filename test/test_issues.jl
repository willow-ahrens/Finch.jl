@testset "issues" begin

    #https://github.com/willow-ahrens/Finch.jl/issues/51
    let
        x = @fiber d(3, e(0.0, [1, 2, 3]))
        y = Scalar{0.0}()
        @finch @loop i j y[] += min(x[i], x[j])
        @test y[] == 14
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/59
    let
        B = @fiber d(3, e(0, [2, 4, 5]))
        A = @fiber d(6, e(0))
        @finch @loop i A[B[i]] = i
        @test reference_isequal(A, [0, 2, 0, 4, 5, 0])
    end


end