@testset "initializers" begin
    @testset "dropdefaults!" begin
        for data in [
            (default = false, A = Bool[]),
            (default = 0.0, A = Float64[]),
            (default = 1.0, A =
                [1.0, 1.0, 1.0, 0.0]),
            (default = 1.0, A =
                [1.0 1.0 1.0 0.0;
                 0.0 0.0 1.0 0.0]),
            (default = 0.0, A =
                [1.0 0.0 0.0 0.0;
                 0.0 0.0 2.0 0.0]),
            (default = false, A =
                [true  false false false;
                 false false true  false;;;
                 false false false false;
                 false false true  false;;;
                 false false false false;
                 false true  false false]),
            (default = 0.0, A =
                [3.0 0.0 0.0 0.0;
                 0.0 0.0 1.0 0.0;;;
                 0.0 0.0 0.0 0.0;
                 0.0 0.0 2.0 0.0;;;
                 0.0 0.0 0.0 0.0;
                 0.0 4.0 0.0 0.0]),
        ]

            idx = ((Int[] for n in ndims(data.A))...,)
            val = eltype(data.A)[]
            for I in CartesianIndices(data.A)
                if data.A[I] == data.default
                    map(push!, tuple(I), idx)
                    push!(val, data.A[i])
                end
            end

            res = @fiber(sc{ndims(arr)}(e(data.default)))
            dropdefaults!(res, data.A)

            @test size(res) == size(data.A)
            @test res.lvl.idx == idxs
            @test res.lvl.lvl.val == val
        end
    end
end