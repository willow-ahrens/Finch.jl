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

lower(ctx::AbstractCompiler, tns::VirtualScalar, ::DefaultStyle) = tns.ex
function virtualize(ctx, ex, ::Type{Scalar{D, Tv}}, tag) where {D, Tv}
    sym = freshen(ctx, tag)
    val = Symbol(tag, :_val) #TODO hmm this is risky
    push!(ctx.preamble, quote
        $sym = $ex
        $val = $sym.val
    end)
    VirtualScalar(sym, Tv, D, tag, val)
end

virtual_moveto(ctx, lvl::VirtualScalar, arch) = lvl

virtual_size(ctx, ::VirtualScalar) = ()

virtual_default(ctx, tns::VirtualScalar) = tns.D
virtual_eltype(tns::VirtualScalar, ctx) = tns.Tv

FinchNotation.finch_leaf(x::VirtualScalar) = virtual(x)

function declare!(ctx, tns::VirtualScalar, init)
    push!(ctx.code.preamble, quote
        $(tns.val) = $(ctx(init))
    end)
    tns
end

function thaw!(ctx, tns::VirtualScalar)
    return tns
end

function freeze!(ctx, tns::VirtualScalar)
    push!(ctx.code.preamble, quote
        $(tns.ex).val = $(ctx(tns.val))
    end)
    return tns
end
instantiate(ctx, tns::VirtualScalar, mode, subprotos) = tns

function lower_access(ctx::AbstractCompiler, node, tns::VirtualScalar)
    @assert isempty(node.idxs)
    return tns.val
end

function short_circuit_cases(ctx, tns::VirtualScalar, op)
    if isannihilator(ctx, virtual_default(ctx, tns), op)
        [:(tns.val == 0) => Simplify(Fill(Null()))]
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

lower(ctx::AbstractCompiler, tns::VirtualSparseScalar, ::DefaultStyle) = :($SparseScalar{$(tns.D), $(tns.Tv)}($(tns.val), $(tns.dirty)))
function virtualize(ctx, ex, ::Type{SparseScalar{D, Tv}}, tag) where {D, Tv}
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

virtual_size(ctx, ::VirtualSparseScalar) = ()

virtual_default(ctx, tns::VirtualSparseScalar) = tns.D
virtual_eltype(tns::VirtualSparseScalar, ctx) = tns.Tv

virtual_moveto(ctx, lvl::VirtualSparseScalar, arch) = lvl

function declare!(ctx, tns::VirtualSparseScalar, init)
    push!(ctx.code.preamble, quote
        $(tns.val) = $(ctx(init))
        $(tns.dirty) = false
    end)
    tns
end

function thaw!(ctx, tns::VirtualSparseScalar)
    return tns
end

function freeze!(ctx, tns::VirtualSparseScalar)
    push!(ctx.code.preamble, quote
        $(tns.ex).val = $(ctx(tns.val))
    end)
    return tns
end

instantiate(ctx, tns::VirtualSparseScalar, mode::Updater, subprotos) = tns
function instantiate(ctx, tns::VirtualSparseScalar, mode::Reader, subprotos)
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

mutable struct ShortCircuitScalar{D, Tv}# <: AbstractArray{Tv, 0}
    val::Tv
end

ShortCircuitScalar(D, args...) = ShortCircuitScalar{D}(args...)
ShortCircuitScalar{D}(args...) where {D} = ShortCircuitScalar{D, typeof(D)}(args...)
ShortCircuitScalar{D, Tv}() where {D, Tv} = ShortCircuitScalar{D, Tv}(D)

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
    name
    val
end

lower(ctx::AbstractCompiler, tns::VirtualShortCircuitScalar, ::DefaultStyle) = :($ShortCircuitScalar{$(tns.D), $(tns.Tv)}($(tns.val)))
function virtualize(ctx, ex, ::Type{ShortCircuitScalar{D, Tv}}, tag) where {D, Tv}
    sym = freshen(ctx, tag)
    val = Symbol(tag, :_val) #TODO hmm this is risky
    push!(ctx.preamble, quote
        $sym = $ex
        $val = $sym.val
    end)
    VirtualShortCircuitScalar(sym, Tv, D, tag, val)
end

virtual_size(ctx, ::VirtualShortCircuitScalar) = ()

virtual_default(ctx, tns::VirtualShortCircuitScalar) = tns.D
virtual_eltype(tns::VirtualShortCircuitScalar, ctx) = tns.Tv

FinchNotation.finch_leaf(x::VirtualShortCircuitScalar) = virtual(x)

function declare!(ctx, tns::VirtualShortCircuitScalar, init)
    push!(ctx.code.preamble, quote
        $(tns.val) = $(ctx(init))
    end)
    tns
end

function thaw!(ctx, tns::VirtualShortCircuitScalar)
    return tns
end

function freeze!(ctx, tns::VirtualShortCircuitScalar)
    push!(ctx.code.preamble, quote
        $(tns.ex).val = $(ctx(tns.val))
    end)
    return tns
end
instantiate(ctx, tns::VirtualShortCircuitScalar, mode, subprotos) = tns

function lower_access(ctx::AbstractCompiler, node, tns::VirtualShortCircuitScalar)
    @assert isempty(node.idxs)
    return tns.val
end

virtual_moveto(ctx, lvl::VirtualShortCircuitScalar, arch) = lvl

function short_circuit_cases(ctx, tns::VirtualShortCircuitScalar, op)
    [:(Finch.isannihilator($(ctx.algebra), $(ctx(op)), $(tns.val))) => Simplify(Fill(Null()))]
end

mutable struct SparseShortCircuitScalar{D, Tv}# <: AbstractArray{Tv, 0}
    val::Tv
    dirty::Bool
end

SparseShortCircuitScalar(D, args...) = SparseShortCircuitScalar{D}(args...)
SparseShortCircuitScalar{D}(args...) where {D} = SparseShortCircuitScalar{D, typeof(D)}(args...)
SparseShortCircuitScalar{D, Tv}() where {D, Tv} = SparseShortCircuitScalar{D, Tv}(D, false)
SparseShortCircuitScalar{D, Tv}(val) where {D, Tv} = SparseShortCircuitScalar{D, Tv}(val, true)

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
    name
    val
    dirty
end

lower(ctx::AbstractCompiler, tns::VirtualSparseShortCircuitScalar, ::DefaultStyle) = :($SparseShortCircuitScalar{$(tns.D), $(tns.Tv)}($(tns.val), $(tns.dirty)))
function virtualize(ctx, ex, ::Type{SparseShortCircuitScalar{D, Tv}}, tag) where {D, Tv}
    sym = freshen(ctx, tag)
    val = Symbol(tag, :_val) #TODO hmm this is risky
    dirty = Symbol(tag, :_dirty) #TODO hmm this is risky
    push!(ctx.preamble, quote
        $sym = $ex
        $val = $sym.val
        $dirty = $sym.dirty
    end)
    VirtualSparseShortCircuitScalar(sym, Tv, D, tag, val, dirty)
end

virtual_size(ctx, ::VirtualSparseShortCircuitScalar) = ()

virtual_default(ctx, tns::VirtualSparseShortCircuitScalar) = tns.D
virtual_eltype(tns::VirtualSparseShortCircuitScalar, ctx) = tns.Tv

virtual_moveto(ctx, lvl::VirtualSparseShortCircuitScalar, arch) = lvl

function declare!(ctx, tns::VirtualSparseShortCircuitScalar, init)
    push!(ctx.code.preamble, quote
        $(tns.val) = $(ctx(init))
        $(tns.dirty) = false
    end)
    tns
end

function thaw!(ctx, tns::VirtualSparseShortCircuitScalar)
    return tns
end

function freeze!(ctx, tns::VirtualSparseShortCircuitScalar)
    push!(ctx.code.preamble, quote
        $(tns.ex).val = $(ctx(tns.val))
    end)
    return tns
end

instantiate(ctx, tns::VirtualSparseShortCircuitScalar, mode::Updater, subprotos) = tns
function instantiate(ctx, tns::VirtualSparseShortCircuitScalar, mode::Reader, subprotos)
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

function short_circuit_cases(ctx, tns::VirtualSparseShortCircuitScalar, op)
    [:(Finch.isannihilator($(ctx.algebra), $(ctx(op)), $(tns.val))) => Simplify(Fill(Null()))]
end