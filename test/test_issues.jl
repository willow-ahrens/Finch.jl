@testset "issues" begin

    #https://github.com/willow-ahrens/Finch.jl/issues/51
    let
        x = @fiber d(3, e(0.0, [1, 2, 3]))
        y = Scalar{0.0}()
        @finch @loop i j y[] += min(x[i], x[j])
        @test y[] == 14
    end

end