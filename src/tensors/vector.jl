containertype(::Type{T}) where T <:AbstractVector = T.name.wrapper

unwrap(::Type{T}) where {T} = T


single(::Type{Vector{S}}) where S = S[1]
empty(::Type{Vector{S}}) where S = S[]

postype(::Type{Vector{S}}) where {S} = Int
