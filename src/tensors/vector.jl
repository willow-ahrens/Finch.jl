containertype(::Type{T}) where T <:AbstractVector = T.name.wrapper

postype(::Type{Vector{S}}) where {S} = Int