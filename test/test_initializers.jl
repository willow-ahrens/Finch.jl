@testset "initializers" begin
    @testset "dropdefaults, ffindnz" begin
        for data in [
            (A = Bool[], default = false),
            (A = Float64[], default = 0.0),
        ]

        idxs = [Int[] for n in ndims(data.A)]
        vals = eltype(data.A)[]
        for I in CartesianIndices(data.A)
            if data.A[I] == data.default
                map(push!, tuple(I), idxs)
                push!(vals, data.A[i])
            end
        end

        ref(data) = findnz(sparse(data))
        res(data) = ffindnz(dropdefaults!(@fiber(sc{ndims(arr)}(e(zero(eltype(arr))))), arr))
        @test ref(data) == res(data)
    end
end