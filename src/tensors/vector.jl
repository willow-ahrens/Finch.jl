containertype(::Type{T}) where T <:AbstractVector = T.name.wrapper

single(::Type{Vector{S}}) where S = S[1]
empty(::Type{Vector{S}}) where S = S[]


single(::Type{AbstractVector{S}}) where S = S[1]
empty(::Type{AbstractVector{S}}) where S = S[]

postype(::Type{Vector{S}}) where {S} = Int