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

lower(tns::VirtualScalar, ctx::AbstractCompiler, ::DefaultStyle) = tns.ex
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
    push!(ctx.code.preamble, quote
        $(tns.ex).val = $(ctx(tns.val))
    end)
    return tns
end
instantiate(tns::VirtualScalar, ctx, mode, subprotos) = tns

function lower_access(ctx::AbstractCompiler, node, tns::VirtualScalar)
    @assert isempty(node.idxs)
    return tns.val
end

function short_circuit_cases(tns::VirtualScalar, ctx, op)
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
    push!(ctx.code.preamble, quote
        $(tns.ex).val = $(ctx(tns.val))
    end)
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

mutable struct ShortCircuitScalar{D, Tv, B}# <: AbstractArray{Tv, 0}
    val::Tv
end

ShortCircuitScalar(D, args...) = ShortCircuitScalar{D}(args...)
ShortCircuitScalar{D}(args...) where {D} = ShortCircuitScalar{D, typeof(D)}(args...)
ShortCircuitScalar{D, Tv}(B, args...) where {D, Tv} = ShortCircuitScalar{D, Tv, B}(args...)
ShortCircuitScalar{D, Tv, B}() where {D, Tv, B} = ShortCircuitScalar{D, Tv, B}(D)

@inline Base.ndims(::Type{<:ShortCircuitScalar}) = 0
@inline Base.size(::ShortCircuitScalar) = ()
@inline Base.axes(::ShortCircuitScalar) = ()
@inline Base.eltype(::ShortCircuitScalar{D, Tv}) where {D, Tv} = Tv
@inline default(::Type{<:ShortCircuitScalar{D}}) where {D} = D
@inline default(::ShortCircuitScalar{D}) where {D} = D

(tns::ShortCircuitScalar)() = tns.val
@inline Base.getindex(tns::ShortCircuitScalar) = tns.val

struct VirtualShortCircuitScalar
    ex
    Tv
    D
    B
    name
    val
end

lower(tns::VirtualShortCircuitScalar, ctx::AbstractCompiler, ::DefaultStyle) = :($ShortCircuitScalar{$(tns.D), $(tns.Tv), $(tns.B)}($(tns.val)))
function virtualize(ex, ::Type{ShortCircuitScalar{D, Tv, B}}, ctx, tag) where {D, Tv, B}
    sym = freshen(ctx, tag)
    val = Symbol(tag, :_val) #TODO hmm this is risky
    push!(ctx.preamble, quote
        $sym = $ex
        $val = $sym.val
    end)
    VirtualShortCircuitScalar(sym, Tv, D, B, tag, val)
end

virtual_size(::VirtualShortCircuitScalar, ctx) = ()

virtual_default(tns::VirtualShortCircuitScalar, ctx) = tns.D
virtual_eltype(tns::VirtualShortCircuitScalar, ctx) = tns.Tv

FinchNotation.finch_leaf(x::VirtualShortCircuitScalar) = virtual(x)

function declare!(tns::VirtualShortCircuitScalar, ctx, init)
    push!(ctx.code.preamble, quote
        $(tns.val) = $(ctx(init))
    end)
    tns
end

function thaw!(tns::VirtualShortCircuitScalar, ctx)
    return tns
end

function freeze!(tns::VirtualShortCircuitScalar, ctx)
    push!(ctx.code.preamble, quote
        $(tns.ex).val = $(ctx(tns.val))
    end)
    return tns
end
instantiate(tns::VirtualShortCircuitScalar, ctx, mode, subprotos) = tns

function lower_access(ctx::AbstractCompiler, node, tns::VirtualShortCircuitScalar)
    @assert isempty(node.idxs)
    return tns.val
end

function short_circuit_cases(tns::VirtualShortCircuitScalar, ctx, op)
    if isannihilator(ctx.algebra, op, literal(tns.B))
        [:($(tns.val) == $(tns.B)) => Null()]
    else
        []
    end
end

mutable struct SparseShortCircuitScalar{D, Tv, B}# <: AbstractArray{Tv, 0}
    val::Tv
    dirty::Bool
end

SparseShortCircuitScalar(D, args...) = SparseShortCircuitScalar{D}(args...)
SparseShortCircuitScalar{D}(args...) where {D} = SparseShortCircuitScalar{D, typeof(D)}(args...)
SparseShortCircuitScalar{D, Tv}(B, args...) where {D, Tv} = SparseShortCircuitScalar{D, Tv, B}(args...)
SparseShortCircuitScalar{D, Tv, B}() where {D, Tv, B} = SparseShortCircuitScalar{D, Tv, B}(D, false)
SparseShortCircuitScalar{D, Tv, B}(val) where {D, Tv, B} = SparseShortCircuitScalar{D, Tv, B}(val, true)

@inline Base.ndims(::Type{<:SparseShortCircuitScalar}) = 0
@inline Base.size(::SparseShortCircuitScalar) = ()
@inline Base.axes(::SparseShortCircuitScalar) = ()
@inline Base.eltype(::SparseShortCircuitScalar{D, Tv}) where {D, Tv} = Tv
@inline default(::Type{<:SparseShortCircuitScalar{D}}) where {D} = D
@inline default(::SparseShortCircuitScalar{D}) where {D} = D

(tns::SparseShortCircuitScalar)() = tns.val
@inline Base.getindex(tns::SparseShortCircuitScalar) = tns.val

struct VirtualSparseShortCircuitScalar
    ex
    Tv
    D
    B
    name
    val
    dirty
end

lower(tns::VirtualSparseShortCircuitScalar, ctx::AbstractCompiler, ::DefaultStyle) = :($SparseShortCircuitScalar{$(tns.D), $(tns.Tv), $(tns.B)}($(tns.val), $(tns.dirty)))
function virtualize(ex, ::Type{SparseShortCircuitScalar{D, Tv, B}}, ctx, tag) where {D, Tv, B}
    sym = freshen(ctx, tag)
    val = Symbol(tag, :_val) #TODO hmm this is risky
    dirty = Symbol(tag, :_dirty) #TODO hmm this is risky
    push!(ctx.preamble, quote
        $sym = $ex
        $val = $sym.val
        $dirty = $sym.dirty
    end)
    VirtualSparseShortCircuitScalar(sym, Tv, D, B, tag, val, dirty)
end

virtual_size(::VirtualSparseShortCircuitScalar, ctx) = ()

virtual_default(tns::VirtualSparseShortCircuitScalar, ctx) = tns.D
virtual_eltype(tns::VirtualSparseShortCircuitScalar, ctx) = tns.Tv

function declare!(tns::VirtualSparseShortCircuitScalar, ctx, init)
    push!(ctx.code.preamble, quote
        $(tns.val) = $(ctx(init))
        $(tns.dirty) = false
    end)
    tns
end

function thaw!(tns::VirtualSparseShortCircuitScalar, ctx)
    return tns
end

function freeze!(tns::VirtualSparseShortCircuitScalar, ctx)
    push!(ctx.code.preamble, quote
        $(tns.ex).val = $(ctx(tns.val))
    end)
    return tns
end

instantiate(tns::VirtualSparseShortCircuitScalar, ctx, mode::Updater, subprotos) = tns
function instantiate(tns::VirtualSparseShortCircuitScalar, ctx, mode::Reader, subprotos)
    Switch([
        value(tns.dirty, Bool) => tns,
        true => Simplify(Fill(tns.D)),
    ])
end

FinchNotation.finch_leaf(x::VirtualSparseShortCircuitScalar) = virtual(x)

function lower_access(ctx::AbstractCompiler, node, tns::VirtualSparseShortCircuitScalar)
    @assert isempty(node.idxs)
    push!(ctx.code.preamble, quote
        $(tns.dirty) = true
    end)
    return tns.val
end

function short_circuit_cases(tns::VirtualSparseShortCircuitScalar, ctx, op)
    if isannihilator(ctx.algebra, op, literal(tns.B))
        [:($(tns.val) == $(tns.B)) => Null()]
    else
        []
    end
end