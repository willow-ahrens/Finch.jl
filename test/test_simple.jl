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
    end

    @finch begin
        z .= 0
        for i = _
            z[i] = x[i]
        end
    end


    @test z == y

    #=
    x = Tensor(Dense(Element(0.0)), [1, 1, 1, 2, 2, 2, 0, 0, 0, 2, 2, 0])
    y = Tensor(SparseRLE(Element(0.0)))
    display(@finch_code begin
        y .= 0
        for i = _
            y[i] = x[i]
        end
    end)
    @finch begin
        y .= 0
        for i = _
            y[i] = x[i]
        end
    end

    x = Tensor(Dense(Dense(Element(0.0))), [1 1 0 0; 1 1 0 0; 0 0 0 4])
    y = Tensor(SparseRLE(SparseList(Element(0.0))))
    display(@finch_code begin
        y .= 0
        for i = _, j = _
            y[j, i] = x[j, i]
        end
    end)
    @finch begin
        y .= 0
        for i = _, j = _
            y[j, i] = x[j, i]
        end
    end
    println(y)
    x = Tensor(Dense(Element(0.0)), [1, 1, 1, 2, 2, 2, 0, 0, 0, 2, 2, 0])
    y = Tensor(DenseRLE(Element(0.0)))
    display(@finch_code begin
        y .= 0
        for i = _
            y[i] = x[i]
        end
    end)

    @finch begin
        y .= 0
        for i = _
            y[i] = x[i]
        end
    end

    println(y)
    =#
end