using SparseArrays

function fiber(arr::SparseMatrixCSC{Tv, Ti}, default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (m, n) = size(arr)
    arr = permutedims(arr)
    return Fiber(Dense(m, SparseList{Ti}(n, arr.colptr, arr.rowval, Element{zero(Tv)}(arr.nzval))), Environment())
end

function fiber(arr::SparseVector{Tv, Ti}, default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (n,) = size(arr)
    return Fiber(SparseList{Ti}(n, [1, length(arr.nzind) + 1], copy(arr.nzind), Element{zero(Tv)}(arr.nzval)), Environment())
end

function fiber!(arr::SparseVector{Tv, Ti}, default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (n,) = size(arr)
    return Fiber(SparseList{Ti}(n, [1, length(arr.nzind) + 1], arr.nzind, Element{zero(Tv)}(arr.nzval)), Environment())
end