mutable struct Scalar{D, Tv}# <: AbstractArray{Tv, 0}
    val::Tv
end

Scalar(D, args...) = Scalar{D}(args...)
Scalar{D}(args...) where {D} = Scalar{D, typeof(D)}(args...)
Scalar{D, Tv}() where {D, Tv} = Scalar{D, Tv}(D)

@inline Base.ndims(::Type{<:Scalar}) = 0
@inline Base.size(::Scalar) = ()
@inline Base.axes(::Scalar) = ()
@inline Base.eltype(::Scalar{D, Tv}) where {D, Tv} = Tv
@inline default(::Type{<:Scalar{D}}) where {D} = D
@inline default(::Scalar{D}) where {D} = D

(tns::Scalar)() = tns.val
@inline Base.getindex(tns::Scalar) = tns.val

struct VirtualScalar
    ex
    Tv
    D
    name
    val
end

lower(tns::VirtualScalar, ctx::AbstractCompiler, ::DefaultStyle) = :($Scalar{$(tns.D), $(tns.Tv)}($(tns.val)))
function virtualize(ex, ::Type{Scalar{D, Tv}}, ctx, tag) where {D, Tv}
    sym = freshen(ctx, tag)
    val = Symbol(tag, :_val) #TODO hmm this is risky
    push!(ctx.preamble, quote
        $sym = $ex
        $val = $sym.val
    end)
    VirtualScalar(sym, Tv, D, tag, val)
end

virtual_size(::VirtualScalar, ctx) = ()

virtual_default(tns::VirtualScalar, ctx) = Some(tns.D)
virtual_eltype(tns::VirtualScalar, ctx) = tns.Tv

FinchNotation.finch_leaf(x::VirtualScalar) = virtual(x)

function declare!(tns::VirtualScalar, ctx, init)
    push!(ctx.code.preamble, quote
        $(tns.val) = $(ctx(init))
    end)
    tns
end

function thaw!(tns::VirtualScalar, ctx)
    return tns
end

function freeze!(tns::VirtualScalar, ctx)
    return tns
end
instantiate_reader(tns::VirtualScalar, ctx, subprotos) = tns
instantiate_updater(tns::VirtualScalar, ctx, subprotos) = tns

function lower_access(ctx::AbstractCompiler, node, tns::VirtualScalar)
    @assert isempty(node.idxs)
    return tns.val
end

struct VirtualDirtyScalar
    ex
    Tv
    D
    name
    val
    dirty
end

virtual_size(::VirtualDirtyScalar, ctx) = ()

virtual_default(tns::VirtualDirtyScalar, ctx) = Some(tns.D)
virtual_eltype(tns::VirtualDirtyScalar, ctx) = tns.Tv

instantiate_reader(tns::VirtualDirtyScalar, ctx, subprotos) = tns
instantiate_updater(tns::VirtualDirtyScalar, ctx, subprotos) = tns

FinchNotation.finch_leaf(x::VirtualDirtyScalar) = virtual(x)

function lower_access(ctx::AbstractCompiler, node, tns::VirtualDirtyScalar)
    @assert isempty(node.idxs)
    push!(ctx.code.preamble, quote
        $(tns.dirty) = true
    end)
    return tns.val
end
