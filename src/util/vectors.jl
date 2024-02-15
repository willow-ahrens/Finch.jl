using Base: @propagate_inbounds

struct PlusOneVector{T} <: AbstractVector{T}
    data::AbstractVector{T}
end

@propagate_inbounds function Base.getindex(vec::PlusOneVector{T},
                                           index::Int) where {T}
    return vec.data[index] + 0x01
end

@propagate_inbounds function Base.getindex(vec::PlusOneVector{T},
                                           index::Vararg{Int}) where {T}
    return vec.data[index...] + 0x01
end

@propagate_inbounds function Base.setindex!(vec::PlusOneVector{T},
                                            val::T,
                                            index::Int) where {T}
    vec.data[index] = val - 0x01
end

@propagate_inbounds function Base.setindex!(vec::PlusOneVector{T},
                                            val::T,
                                            index::Vararg{Int}) where {T}
    vec.data[index...] = val - 0x01
end

Base.parent(vec::PlusOneVector{T}) where {T} = vec.data
Base.size(vec::PlusOneVector{T}) where {T} = size(vec.data)
Base.axes(vec::PlusOneVector{T}) where {T} = axes(vec.data)

function moveto(vec::PlusOneVector{T}, device) where {T}
    data = moveto(vec.data, device)
    return PlusOneVector{T}(data)
end

struct MinusEpsVector{T, S} <: AbstractVector{T}
    data::AbstractVector{S}
end

MinusEpsVector(data::AbstractVector{T}) where {T} = MinusEpsVector{Limit{T}, T}(data)

@propagate_inbounds function Base.getindex(vec::MinusEpsVector{T},
                                           index::Int) where {T}
    return minus_eps(vec.data[index])
end

@propagate_inbounds function Base.getindex(vec::MinusEpsVector{T},
                                           index::Vararg{Int}) where {T}
    return minus_eps(vec.data[index...])
end

@propagate_inbounds function Base.setindex!(vec::MinusEpsVector{Limit{T}},
                                            val::Limit{T},
                                            index::Int) where {T}
    Base.@boundscheck begin
        @assert val.sign == tiny_negative()
    end
    vec.data[index] = val.val
end

@propagate_inbounds function Base.setindex!(vec::MinusEpsVector{Limit{T}},
                                            val::Limit{T},
                                            index::Vararg{Int}) where {T}
    Base.@boundscheck begin
        @assert val.sign == tiny_negative()
    end
    vec.data[index...] = val.val
end

Base.parent(vec::MinusEpsVector{T}) where {T} = vec.data
Base.size(vec::MinusEpsVector{T}) where {T} = size(vec.data)
Base.axes(vec::MinusEpsVector{T}) where {T} = axes(vec.data)

function moveto(vec::MinusEpsVector{T}, device) where {T}
    data = moveto(vec.data, device)
    return MinusEpsVector{T}(data)
end

struct PlusEpsVector{T, S} <: AbstractVector{T}
    data::AbstractVector{S}
end

PlusEpsVector(data::AbstractVector{T}) where {T} = PlusEpsVector{Limit{T}, S}(data)

@propagate_inbounds function Base.getindex(vec::PlusEpsVector{T},
                                           index::Int) where {T}
    return plus_eps(vec.data[index])
end

@propagate_inbounds function Base.getindex(vec::PlusEpsVector{T},
                                           index::Vararg{Int}) where {T}
    return plus_eps(vec.data[index...])
end

@propagate_inbounds function Base.setindex!(vec::PlusEpsVector{Limit{T}},
                                            val::Limit{T},
                                            index::Int) where {T}
    Base.@boundscheck begin
        @assert val.sign == tiny_positive()
    end
    vec.data[index] = val.val
end

@propagate_inbounds function Base.setindex!(vec::PlusEpsVector{Limit{T}},
                                            val::Limit{T},
                                            index::Vararg{Int}) where {T}
    Base.@boundscheck begin
        @assert val.sign == tiny_positive()
    end
    vec.data[index...] = val.val
end

Base.parent(vec::PlusEpsVector{T}) where {T} = vec.data
Base.size(vec::PlusEpsVector{T}) where {T} = size(vec.data)
Base.axes(vec::PlusEpsVector{T}) where {T} = axes(vec.data)

function moveto(vec::PlusEpsVector{T}, device) where {T}
    data = moveto(vec.data, device)
    return PlusEpsVector{T}(data)
end

struct FillVector{X, T} <: AbstractVector{T}
end

FillVector(X) = FillVector{X}(T)
FillVector{X}() where {X} = FillVector{X, typeof(X)}()

@propagate_inbounds function Base.getindex(vec::FillVector{X},
                                           index::Int) where {X}
    return X
end

@propagate_inbounds function Base.getindex(vec::FillVector{X},
                                           index::Vararg{Int}) where {X}
    return X
end

@propagate_inbounds function Base.setindex!(vec::FillVector{X},
                                            val::T,
                                            index::Int) where {X, T}
    Base.@boundscheck begin
        @assert val == X
    end
    return nothing
end

@propagate_inbounds function Base.setindex!(vec::FillVector{X},
                                            val::T,
                                            index::Vararg{Int}) where {X, T}
    Base.@boundscheck begin
        @assert val == X
    end
    return nothing
end

Base.parent(vec::FillVector{X}) where {X} = X
Base.size(vec::FillVector{X}) where {X} = ()
Base.axes(vec::FillVector{X}) where {X} = ()

moveto(vec::FillVector, device) = vec