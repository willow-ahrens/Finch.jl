@testset "interface" begin
    @info "Testing Finch Interface"
    
    using Finch: LogicTensor

    A = LogicTensor(zeros(2, 2))
    B = LogicTensor(ones(2, 2))
    C = map(+, A, B)
    x = LogicTensor(zeros(2))
    y = sum(C .* x, dims=1)
    Finch.compute(y)
end