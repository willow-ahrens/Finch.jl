@testset "interface" begin
    @info "Testing Finch Interface"
    
    using Finch: LazyTensor

    f() = begin
    A = LazyTensor(Tensor(Dense(SparseList(Element(0.0))), 2, 2))
    B = LazyTensor(ones(2, 2))
    C = map(*, A, B)
    x = LazyTensor(zeros(2))
    y = sum(C .* x, dims=1)
    z = copyto!(ones(2), y)
    D = permutedims(C, [2, 1])
    D += C
    Finch.compute((z, D))
    end

    f()
    display(@elapsed(f()))
end