using SparseArrays

function fiber(arr::SparseMatrixCSC{Tv, Ti}, default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (m, n) = size(arr)
    return Fiber(Dense(SparseList{Ti}(Element{zero(Tv)}(arr.nzval), m, arr.colptr, arr.rowval), n))
end

function fiber(arr::SparseVector{Tv, Ti}, default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (n,) = size(arr)
    return Fiber(SparseList{Ti}(Element{zero(Tv)}(arr.nzval), n, [1, length(arr.nzind) + 1], copy(arr.nzind)))
end

function fiber!(arr::SparseVector{Tv, Ti}, default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (n,) = size(arr)
    return Fiber(SparseList{Ti}(Element{zero(Tv)}(arr.nzval), n, [1, length(arr.nzind) + 1], arr.nzind))
end