@testset "simple" begin
    @info "Testing Simple Examples"

    x = Tensor(Sparse(Element(0.0)))
    y = Tensor(SparseList(Element(0.0)), sprand(10, 0.5))
    z = Tensor(SparseList(Element(0.0)), sprand(10, 0.5))

    @finch begin
        x .= 0
        for i = _
            x[i] = y[i]
        end
        return x
    end

    @finch begin
        z .= 0
        for i = _
            z[i] = x[i]
        end
        return z
    end


    @test z == y
end