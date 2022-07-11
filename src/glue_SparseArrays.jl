using SparseArrays

function fiber(arr::SparseMatrixCSC{Tv, Ti}, default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (m, n) = size(arr)
    return Fiber(Solid(m, HollowList{Ti}(n, copy(arr.colptr), copy(arr.rowval), Element{zero(Tv)}(copy(arr.nzval)))))
end

function fiber!(arr::SparseMatrixCSC{Tv, Ti}, default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (m, n) = size(arr)
    return Fiber(Solid(m, HollowList{Ti}(n, arr.colptr, arr.rowval, Element{zero(Tv)}(arr.nzval))))
end

function fiber(arr::SparseVector{Tv, Ti}, default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (n,) = size(arr)
    return Fiber(HollowList{Ti}(n, [1, length(arr.nzind) + 1], copy(arr.nzind), Element{zero(Tv)}(arr.nzval)))
end

function fiber!(arr::SparseVector{Tv, Ti}, default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (n,) = size(arr)
    return Fiber(HollowList{Ti}(n, [1, length(arr.nzind) + 1], arr.nzind, Element{zero(Tv)}(arr.nzval)))
end