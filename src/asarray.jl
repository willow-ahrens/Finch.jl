struct AsArray{T, N, Fbr} <: AbstractArray{T, N}
    fbr::Fbr
    function AsArray{T, N, Fbr}(fbr::Fbr) where {T, N, Fbr}
        @assert T == eltype(fbr)
        @assert N == ndims(fbr)
        new{T, N, Fbr}(fbr)
    end
end

AsArray(fbr::Fbr) where {Fbr} = AsArray{eltype(Fbr), ndims(Fbr), Fbr}(fbr)

Base.size(arr::AsArray) = size(arr.fbr)
Base.getindex(arr::AsArray{T, N}, i::Vararg{Int, N}) where {T, N} = arr.fbr[i...]
Base.getindex(arr::AsArray{T, N}, i::Vararg{Any, N}) where {T, N} = arr.fbr[i...]
Base.setindex!(arr::AsArray{T, N}, v, i::Vararg{Int, N}) where {T, N} = arr.fbr[i...] = v
Base.setindex!(arr::AsArray{T, N}, v, i::Vararg{Any, N}) where {T, N} = arr.fbr[i...] = v