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

virtual_default(tns::VirtualScalar, ctx) = tns.D
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
instantiate(tns::VirtualScalar, ctx, mode, subprotos) = tns

function lower_access(ctx::AbstractCompiler, node, tns::VirtualScalar)
    @assert isempty(node.idxs)
    return tns.val
end

function get_brakes(tns::VirtualScalar, ctx, op)
    if isannihilator(ctx, virtual_default(tns, ctx), op)
        [:(tns.val == 0) => Null()]
    else
        []
    end
end

mutable struct SparseScalar{D, Tv}# <: AbstractArray{Tv, 0}
    val::Tv
    dirty::Bool
end

SparseScalar(D, args...) = SparseScalar{D}(args...)
SparseScalar{D}(args...) where {D} = SparseScalar{D, typeof(D)}(args...)
SparseScalar{D, Tv}() where {D, Tv} = SparseScalar{D, Tv}(D, false)
SparseScalar{D, Tv}(val) where {D, Tv} = SparseScalar{D, Tv}(val, true)

@inline Base.ndims(::Type{<:SparseScalar}) = 0
@inline Base.size(::SparseScalar) = ()
@inline Base.axes(::SparseScalar) = ()
@inline Base.eltype(::SparseScalar{D, Tv}) where {D, Tv} = Tv
@inline default(::Type{<:SparseScalar{D}}) where {D} = D
@inline default(::SparseScalar{D}) where {D} = D

(tns::SparseScalar)() = tns.val
@inline Base.getindex(tns::SparseScalar) = tns.val

struct VirtualSparseScalar
    ex
    Tv
    D
    name
    val
    dirty
end

lower(tns::VirtualSparseScalar, ctx::AbstractCompiler, ::DefaultStyle) = :($SparseScalar{$(tns.D), $(tns.Tv)}($(tns.val), $(tns.dirty)))
function virtualize(ex, ::Type{SparseScalar{D, Tv}}, ctx, tag) where {D, Tv}
    sym = freshen(ctx, tag)
    val = Symbol(tag, :_val) #TODO hmm this is risky
    dirty = Symbol(tag, :_dirty) #TODO hmm this is risky
    push!(ctx.preamble, quote
        $sym = $ex
        $val = $sym.val
        $dirty = $sym.dirty
    end)
    VirtualSparseScalar(sym, Tv, D, tag, val, dirty)
end

virtual_size(::VirtualSparseScalar, ctx) = ()

virtual_default(tns::VirtualSparseScalar, ctx) = tns.D
virtual_eltype(tns::VirtualSparseScalar, ctx) = tns.Tv

function declare!(tns::VirtualSparseScalar, ctx, init)
    push!(ctx.code.preamble, quote
        $(tns.val) = $(ctx(init))
        $(tns.dirty) = false
    end)
    tns
end

function thaw!(tns::VirtualSparseScalar, ctx)
    return tns
end

function freeze!(tns::VirtualSparseScalar, ctx)
    return tns
end

instantiate(tns::VirtualSparseScalar, ctx, mode::Updater, subprotos) = tns
function instantiate(tns::VirtualSparseScalar, ctx, mode::Reader, subprotos)
    Switch(
        tns.dirty => tns,
        true => Simplify(Fill(tns.D)),
    )
end

FinchNotation.finch_leaf(x::VirtualSparseScalar) = virtual(x)

function lower_access(ctx::AbstractCompiler, node, tns::VirtualSparseScalar)
    @assert isempty(node.idxs)
    push!(ctx.code.preamble, quote
        $(tns.dirty) = true
    end)
    return tns.val
end

mutable struct ScalarBrake{D, Tv, B}# <: AbstractArray{Tv, 0}
    val::Tv
end

ScalarBrake(D, args...) = ScalarBrake{D}(args...)
ScalarBrake{D}(args...) where {D} = ScalarBrake{D, typeof(D)}(args...)
ScalarBrake{D, Tv}(B, args...) where {D, Tv} = ScalarBrake{D, Tv, B}(args...)
ScalarBrake{D, Tv, B}() where {D, Tv, B} = ScalarBrake{D, Tv, B}(D)

@inline Base.ndims(::Type{<:ScalarBrake}) = 0
@inline Base.size(::ScalarBrake) = ()
@inline Base.axes(::ScalarBrake) = ()
@inline Base.eltype(::ScalarBrake{D, Tv}) where {D, Tv} = Tv
@inline default(::Type{<:ScalarBrake{D}}) where {D} = D
@inline default(::ScalarBrake{D}) where {D} = D

(tns::ScalarBrake)() = tns.val
@inline Base.getindex(tns::ScalarBrake) = tns.val

struct VirtualScalarBrake
    ex
    Tv
    D
    B
    name
    val
end

lower(tns::VirtualScalarBrake, ctx::AbstractCompiler, ::DefaultStyle) = :($ScalarBrake{$(tns.D), $(tns.Tv), $(tns.B)}($(tns.val)))
function virtualize(ex, ::Type{ScalarBrake{D, Tv, B}}, ctx, tag) where {D, Tv, B}
    sym = freshen(ctx, tag)
    val = Symbol(tag, :_val) #TODO hmm this is risky
    push!(ctx.preamble, quote
        $sym = $ex
        $val = $sym.val
    end)
    VirtualScalarBrake(sym, Tv, D, B, tag, val)
end

virtual_size(::VirtualScalarBrake, ctx) = ()

virtual_default(tns::VirtualScalarBrake, ctx) = tns.D
virtual_eltype(tns::VirtualScalarBrake, ctx) = tns.Tv

FinchNotation.finch_leaf(x::VirtualScalarBrake) = virtual(x)

function declare!(tns::VirtualScalarBrake, ctx, init)
    push!(ctx.code.preamble, quote
        $(tns.val) = $(ctx(init))
    end)
    tns
end

function thaw!(tns::VirtualScalarBrake, ctx)
    return tns
end

function freeze!(tns::VirtualScalarBrake, ctx)
    return tns
end
instantiate(tns::VirtualScalarBrake, ctx, mode, subprotos) = tns

function lower_access(ctx::AbstractCompiler, node, tns::VirtualScalarBrake)
    @assert isempty(node.idxs)
    return tns.val
end

function get_brakes(tns::VirtualScalarBrake, ctx, op)
    if isannihilator(ctx.algebra, op, literal(tns.B))
        [:($(tns.val) == $(tns.B)) => Null()]
    else
        []
    end
end