@testset "interface" begin
    @info "Testing Finch Interface"
    
    using Finch: LogicTensor

    A = LogicTensor(Tensor(Dense(SparseList(Element(0.0))), 2, 2))
    B = LogicTensor(ones(2, 2))
    C = map(*, A, B)
    x = LogicTensor(zeros(2))
    y = sum(C .* x, dims=1)
    z = copyto!(ones(2), y)
    D = permutedims(C, [2, 1])
    D += C
    Finch.compute((z, D))
    Finch.compute((z, D))
end