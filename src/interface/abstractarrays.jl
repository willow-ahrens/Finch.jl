@kwdef mutable struct VirtualAbstractArray <: AbstractVirtualTensor
    ex
    eltype
    ndims
    shape
end

function virtual_size(ctx::AbstractCompiler, arr::VirtualAbstractArray)
    return arr.shape
end

function lower(arr::VirtualAbstractArray, ctx::AbstractCompiler,  ::DefaultStyle)
    return arr.ex
end

function virtualize(ctx, ex, ::Type{<:AbstractArray{T, N}}, tag=:tns) where {T, N}
    sym = freshen(ctx, tag)
    dims = map(i -> Symbol(sym, :_mode, i, :_stop), 1:N)
    push!(ctx.preamble, quote
        $sym = $ex
        ($(dims...),) = size($ex)
    end)
    VirtualAbstractArray(sym, T, N, map(i->Extent(literal(1), value(dims[i], Int)), 1:N))
end

function declare!(arr::VirtualAbstractArray, ctx::AbstractCompiler, init)
    push!(ctx.code.preamble, quote
        fill!($(arr.ex), $(ctx(init)))
    end)
    arr
end

freeze!(arr::VirtualAbstractArray, ctx::AbstractCompiler) = arr
thaw!(arr::VirtualAbstractArray, ctx::AbstractCompiler) = arr

function instantiate(arr::VirtualAbstractArray, ctx::AbstractCompiler, mode, subprotos, protos...)
    val = freshen(ctx.code, :val)
    function nest(idx...)
        if length(idx) == arr.ndims
            if mode === reader
                Thunk(
                    preamble = quote
                        $val = $(arr.ex)[$(map(ctx, idx)...)]
                    end,
                    body = (ctx) -> VirtualScalar(nothing, arr.eltype, nothing#=We don't know what init is, but it won't be used here =#, gensym(), val)
                )
            else
                VirtualScalar(nothing, arr.eltype, nothing#=We don't know what init is, but it won't be used here=#, gensym(), :($(arr.ex)[$(map(ctx, idx)...)]))
            end
        else
            Furlable(
                body = (ctx, ext) -> Lookup(
                    body = (ctx, i) -> nest(i, idx...)
                )
            )
        end
    end
    Unfurled(
        arr = arr,
        body = nest()
    )
end

FinchNotation.finch_leaf(x::VirtualAbstractArray) = virtual(x)

virtual_default(ctx, ::VirtualAbstractArray) = 0
virtual_eltype(ctx, tns::VirtualAbstractArray) = tns.eltype

function virtual_moveto(vec::VirtualAbstractArray, ctx, device)
    ex = freshen(ctx.code, vec.ex)
    push!(ctx.code.preamble, quote
        $ex = $(vec.ex)
        $(vec.ex) = $moveto($(vec.ex), $(ctx(device)))
    end)
    push!(ctx.code.epilogue, quote
        $(vec.ex) = $ex
    end)
end

default(a::AbstractArray) = default(typeof(a))
default(T::Type{<:AbstractArray}) = zero(eltype(T))

"""
    Array(arr::Union{Tensor, SwizzleArray})

Construct an array from a tensor or swizzle. May reuse memory, will usually densify the tensor.
"""
function Base.Array(fbr::Union{Tensor, SwizzleArray})
    arr = Array{eltype(fbr)}(undef, size(fbr)...)
    return copyto!(arr, fbr)
end

struct AsArray{T, N, Fbr} <: AbstractArray{T, N}
    fbr::Fbr
    function AsArray{T, N, Fbr}(fbr::Fbr) where {T, N, Fbr}
        @assert T == eltype(fbr)
        @assert N == ndims(fbr)
        new{T, N, Fbr}(fbr)
    end
end

AsArray(fbr::Fbr) where {Fbr} = AsArray{eltype(Fbr), ndims(Fbr), Fbr}(fbr)

function Base.summary(io::IO, arr::AsArray)
    join(io, size(arr), "×")
    print(io, " ", typeof(arr.fbr))
    #print(io, " ")
    #summary(io, arr.fbr)
end

Base.size(arr::AsArray) = size(arr.fbr)
Base.getindex(arr::AsArray{T, N}, i::Vararg{Int, N}) where {T, N} = arr.fbr[i...]
Base.getindex(arr::AsArray{T, N}, i::Vararg{Any, N}) where {T, N} = arr.fbr[i...]
Base.setindex!(arr::AsArray{T, N}, v, i::Vararg{Int, N}) where {T, N} = arr.fbr[i...] = v
Base.setindex!(arr::AsArray{T, N}, v, i::Vararg{Any, N}) where {T, N} = arr.fbr[i...] = v

is_injective(tns::VirtualAbstractArray, ctx) = [true for _ in tns.ndims]
is_atomic(tns::VirtualAbstractArray, ctx) = true