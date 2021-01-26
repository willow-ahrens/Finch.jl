module FiberArrays

abstract type AbstractFiberArray{T, F, N} <: AbstractArray{T, N} end

struct DenseFiberArray{T, F, N}
    
end

end

abstract type AbstractFiberArray{T, N, V} <: AbstractArray{T, N}

Base.size(arr::AbstractFiberArray{T, N}) = _size(arr)

_size(arr) = (dimension(arr), _size(value(arr))...)

Base.getindex(arr::AbstractFiberArray{T, N}, inds::Vararg{N}) where {T, N} = _getindex(arr, inds...)

_getindex(arr::AbstractFiberArray, i, tail...) = getfiber(child(arr), )[tail...]



struct DenseMode{T, N, V}
    I::Int
    v::V
end

dimension(mode::DenseMode) = mode.I

struct DenseFiberArray{T, V} <: AbstractVector{T, N}
    j::Int
    v::V
end

getfiber(arr::DenseFiberArray, j) = DenseFiber(j, arr)

Base.size(vec::DenseFiber) = vec.I

Base.getindex(vec::DenseFiber, i) = (vec.j - 1) * vec.I + i


struct SparseMode{Ti}
    I::Int
    pos::Vector{Ti}
    idx::Vector{Ti}
end

Base.size(mode::SparseMode) = (mode.I,)



