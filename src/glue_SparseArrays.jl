using SparseArrays

function fiber(arr::SparseMatrixCSC{Tv, Ti}, default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (m, n) = size(arr)
    arr = permutedims(arr)
    return Fiber(Dense(SparseList{Ti}(Element{zero(Tv)}(arr.nzval), n, arr.colptr, arr.rowval), m))
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