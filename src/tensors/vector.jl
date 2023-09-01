containertype(::Type{T}) where T <:AbstractVector = T.name.wrapper

unwrap(::Type{T}) where {T} = T


single(::Type{Vector{S}}) where S = S[1]
empty(::Type{Vector{S}}) where S = S[]

postype(::Type{Vector{S}}) where {S} = Int


itertype(::Type{Tuple{T, Vararg{Any}}}) where {T} = T.parameters[1]
itertype(::Type{Tuple{T, Vararg{Any}}}, ::Type{N}) where {T, N} = NTuple{N, itertype(T)}
