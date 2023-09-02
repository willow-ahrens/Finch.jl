containertype(::Type{T}) where T <:AbstractVector = T.name.wrapper

unwrap(::Type{T}) where {T} = T


single(::Type{Vector{S}}) where S = S[1]
empty(::Type{Vector{S}}) where S = S[]

postype(::Type{Vector{S}}) where {S} = Int


indextype(::Type{Tuple{T, Vararg{Any}}}) where {T} = indextype(T)
indextype(::Type{Tuple{T}}) where {T} = indextype(T)
indextype(::Type{T}) where {T} = T
# indextype(::Type{T}, ::Type{N}) where {T, N} = indextype(indextype(T), N)
# function indextype(::Type{Tuple{T, Vararg{Any}}}, ::Type{N}) where {T, N}
#     if N > 0
#         return  NTuple{N, indextype(T)}
#     else
#         return indextype(T)
#     end
# end

function tuplize(::Type{T}, N::Int) where {T}
    if N > 1
        return  NTuple{N, T}
    else
        return Tuple{T}
    end
end



struct ForceCopyArray{T, N} <: AbstractArray{T, N}
    data::Array{T, N}
    function ForceCopyArray(arr:: AbstractArray{T, N}) where {T, N}
        copied = copy(arr)
        new{T, N}(arr)
    end
end


struct NoCopyArray{T, N} <: AbstractArray{T, N}
    data::Array{T, N}
end