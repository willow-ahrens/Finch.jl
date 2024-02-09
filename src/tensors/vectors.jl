using Base: @propagate_inbounds

struct OffByOneVector{T} <: AbstractVector{T}
    data::AbstractVector{T}
end

@propagate_inbounds function Base.getindex(vector::OffByOneVector{T},
                                           index::Int) where {T}
    return vector.data[index] + 0x01
end

@propagate_inbounds function Base.getindex(vector::OffByOneVector{T},
                                           index::Vararg{Int}) where {T}
    return vector.data[index...] + 0x01
end

@propagate_inbounds function Base.setindex!(vector::OffByOneVector{T},
                                            val::T,
                                            index::Int) where {T}
    vector.data[index] = val - 0x01
end

@propagate_inbounds function Base.setindex!(vector::OffByOneVector{T},
                                            val::T,
                                            index::Vararg{Int}) where {T}
    vector.data[index...] = val - 0x01
end

Base.parent(vector::OffByOneVector{T}) where {T} = vector.data
Base.size(vector::OffByOneVector{T}) where {T} = size(vector.data)
Base.axes(vector::OffByOneVector{T}) where {T} = axes(vector.data)

function moveto(vector::OffByOneVector{T}, device) where {T}
    data = moveto(vector.data, device)
    return OffByOneVector{T}(data)
end
