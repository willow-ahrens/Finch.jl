@kwdef mutable struct VirtualAbstractArray <: AbstractVirtualTensor
    ex
    eltype
    ndims
end

function virtual_size(arr::VirtualAbstractArray, ctx::AbstractCompiler)
    dims = map(i -> Symbol(arr.ex, :_mode, i, :_stop), 1:arr.ndims)
    push!(ctx.code.preamble, quote
        ($(dims...),) = size($(arr.ex))
    end)
    return map(i->Extent(literal(1), value(dims[i], Int)), 1:arr.ndims)
end

function lower(arr::VirtualAbstractArray, ctx::AbstractCompiler,  ::DefaultStyle)
    return arr.ex
end

function virtualize(ex, ::Type{<:AbstractArray{T, N}}, ctx, tag=:tns) where {T, N}
    sym = freshen(ctx, tag)
    push!(ctx.preamble, :($sym = $ex))
    VirtualAbstractArray(sym, T, N)
end

function declare!(arr::VirtualAbstractArray, ctx::AbstractCompiler, init)
    push!(ctx.code.preamble, quote
        fill!($(arr.ex), $(ctx(init)))
    end)
    arr
end

freeze!(arr::VirtualAbstractArray, ctx::AbstractCompiler) = arr
thaw!(arr::VirtualAbstractArray, ctx::AbstractCompiler) = arr

instantiate_reader(arr::VirtualAbstractArray, ctx::AbstractCompiler, subprotos, protos...) = arr
instantiate_updater(arr::VirtualAbstractArray, ctx::AbstractCompiler, subprotos, protos...) = arr

FinchNotation.finch_leaf(x::VirtualAbstractArray) = virtual(x)

virtual_default(::VirtualAbstractArray, ctx) = 0
virtual_eltype(arr::VirtualAbstractArray, ctx) = arr.eltype
virtual_data_rep(arr::VirtualAbstractArray, ctx) = (DenseData^(arr.ndims))(ElementData(zero(arr.eltype), arr.eltype))

default(a::AbstractArray) = default(typeof(a))
default(T::Type{<:AbstractArray}) = zero(eltype(T))

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

is_injective(tns::VirtualAbstractArray, ctx) = [true for _ in tns.ndims]
is_concurrent(tns::VirtualAbstractArray, ctx) = [true for _ in tns.ndims]
is_atomic(tns::VirtualAbstractArray, ctx) = true