module SparseArraysExt 

using Finch
using Finch: AbstractCompiler, DefaultStyle, Extent
using Finch: Unfurled, Furlable, Stepper, Jumper, Run, Fill, Lookup, Simplify, Sequence, Phase, Thunk, Spike 
using Finch: virtual_size, virtual_default, getstart, getstop, freshen, SwizzleArray
using Finch: FinchProtocolError
using Finch.FinchNotation

using Base: @kwdef

isdefined(Base, :get_extension) ? (using SparseArrays) : (using ..SparseArrays)

function Finch.Fiber(arr::SparseMatrixCSC{Tv, Ti}) where {Tv, Ti}
    (m, n) = size(arr)
    return Fiber(Dense(SparseList{Ti}(Element{zero(Tv)}(arr.nzval), m, arr.colptr, arr.rowval), n))
end

function Finch.Fiber(arr::SparseVector{Tv, Ti}) where {Tv, Ti}
    (n,) = size(arr)
    return Fiber(SparseList{Ti}(Element{zero(Tv)}(arr.nzval), n, [1, length(arr.nzind) + 1], arr.nzind))
end

"""
    SparseMatrixCSC(arr::Union{Fiber, SwizzleArray})

Construct a sparse matrix from a fiber or swizzle. May reuse the underlying storage if possible.
"""
function SparseArrays.SparseMatrixCSC(arr::Union{Fiber, SwizzleArray})
    default(arr) === zero(eltype(arr)) || throw(ArgumentError("SparseArrays, a Julia stdlib, only supports zero default values, was given $(default(arr)) as default"))
    return SparseMatrixCSC(Fiber(Dense(SparseList(Element(0.0))), arr))
end

function SparseArrays.SparseMatrixCSC(arr::Fiber{<:Dense{Ti, <:SparseList{Ti, Ptr, Idx, <:Element{D, Tv}}}}) where {D, Ti, Ptr, Idx, Tv}
    D === zero(Tv) || throw(ArgumentError("SparseArrays, a Julia stdlib, only supports zero default values, was given $D as default"))
    return SparseMatrixCSC{Tv, Ti}(size(arr)..., arr.lvl.lvl.ptr, arr.lvl.lvl.idx, arr.lvl.lvl.lvl.val)
end

"""
    sparse(arr::Union{Fiber, SwizzleArray})

Construct a SparseArray from a Fiber or Swizzle. May reuse the underlying storage if possible.
"""
function SparseArrays.sparse(fbr::Union{Fiber, SwizzleArray})
    if ndims(fbr) == 1
        return SparseVector(fbr)
    elseif ndims(fbr) == 2
        return SparseMatrixCSC(fbr)
    else
        throw(ArgumentError("SparseArrays, a Julia stdlib, only supports 1-D and 2-D arrays, was given a $(ndims(fbr))-D array"))
    end
end

@kwdef mutable struct VirtualSparseMatrixCSC
    ex
    Tv
    Ti
end

function Finch.virtual_size(arr::VirtualSparseMatrixCSC, ctx::AbstractCompiler)
    return [Extent(literal(1),value(:($(arr.ex).m), arr.Ti)), Extent(literal(1), value(:($(arr.ex).n), arr.Ti))]
end

function lower(arr::VirtualSparseMatrixCSC, ctx::AbstractCompiler,  ::DefaultStyle)
    return arr.ex
end

function Finch.virtualize(ex, ::Type{<:SparseMatrixCSC{Tv, Ti}}, ctx, tag=:tns) where {Tv, Ti}
    sym = freshen(ctx, tag)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    VirtualSparseMatrixCSC(sym, Tv, Ti)
end

function Finch.declare!(arr::VirtualSparseMatrixCSC, ctx::AbstractCompiler, init)
    throw(FinchProtocolError("Finch does not support writes to SparseMatrixCSC"))
end

function Finch.instantiate(arr::VirtualSparseMatrixCSC, ctx::AbstractCompiler, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(walk), typeof(follow)}, ::Union{typeof(defaultread), typeof(walk)})
    tag = arr.ex
    Ti = arr.Ti
    my_i = freshen(ctx.code, tag, :_i)
    my_q = freshen(ctx.code, tag, :_q)
    my_q_stop = freshen(ctx.code, tag, :_q_stop)
    my_i1 = freshen(ctx.code, tag, :_i1)
    my_val = freshen(ctx.code, tag, :_val)

    Unfurled(
        arr = arr,
        body = Furlable(
            body = (ctx, ext) -> Lookup(
                body = (ctx, j) -> Furlable(
                    body = (ctx, ext) -> Thunk(
                        preamble = quote
                            $my_q = $(arr.ex).colptr[$(ctx(j))]
                            $my_q_stop = $(arr.ex).colptr[$(ctx(j)) + $(Ti(1))]
                            if $my_q < $my_q_stop
                                $my_i = $(arr.ex).rowval[$my_q]
                                $my_i1 = $(arr.ex).rowval[$my_q_stop - $(Ti(1))]
                            else
                                $my_i = $(Ti(1))
                                $my_i1 = $(Ti(0))
                            end
                        end,
                        body = (ctx) -> Sequence([
                            Phase(
                                stop = (ctx, ext) -> value(my_i1),
                                body = (ctx, ext) -> Stepper(
                                    seek = (ctx, ext) -> quote
                                        if $(arr.ex).rowval[$my_q] < $(ctx(getstart(ext)))
                                            $my_q = Finch.scansearch($(arr.ex).rowval, $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                                        end
                                    end,
                                    preamble = :($my_i = $(arr.ex).rowval[$my_q]),
                                    stop = (ctx, ext) -> value(my_i),
                                    chunk = Spike(
                                        body = Fill(zero(arr.Tv)),
                                        tail = Thunk(
                                            preamble = quote
                                                $my_val = $(arr.ex).nzval[$my_q]
                                            end,
                                            body = (ctx) -> Fill(value(my_val, arr.Tv))
                                        )
                                    ),
                                    next = (ctx, ext) -> quote
                                        $my_q += $(Ti(1))
                                    end
                                )
                            ),
                            Phase(
                                body = (ctx, ext) -> Run(Fill(zero(arr.Tv)))
                            )
                        ])
                    )
                )
            )
        )
    )
end

function Finch.instantiate(arr::VirtualSparseMatrixCSC, ctx::AbstractCompiler, mode::Updater, subprotos, protos...)
    throw(FinchProtocolError("Finch does not support writes to SparseMatrixCSC"))
end

Finch.FinchNotation.finch_leaf(x::VirtualSparseMatrixCSC) = virtual(x)

Finch.virtual_default(arr::VirtualSparseMatrixCSC, ctx) = zero(arr.Tv)
Finch.virtual_eltype(tns::VirtualSparseMatrixCSC, ctx) = tns.Tv

"""
    SparseVector(arr::Union{Fiber, SwizzleArray})

Construct a sparse matrix from a fiber or swizzle. May reuse the underlying storage if possible.
"""
function SparseArrays.SparseVector(arr::Union{Fiber, SwizzleArray})
    default(arr) === zero(eltype(arr)) || throw(ArgumentError("SparseArrays, a Julia stdlib, only supports zero default values, was given $(default(arr)) as default"))
    return SparseVector(Fiber(SparseList(Element(0.0)), arr))
end

function SparseArrays.SparseVector(arr::Fiber{<:SparseList{Ti, Ptr, Idx, <:Element{D, Tv}}}) where {Ti, Ptr, Idx, Tv, D}
    D === zero(Tv) || throw(ArgumentError("SparseArrays, a Julia stdlib, only supports zero default values, was given $D as default"))
    return SparseVector{Tv, Ti}(size(arr)..., arr.lvl.idx, arr.lvl.lvl.val)
end
@kwdef mutable struct VirtualSparseVector
    ex
    Tv
    Ti
end

function Finch.virtual_size(arr::VirtualSparseVector, ctx::AbstractCompiler)
    return Any[Extent(literal(1),value(:($(arr.ex).n), arr.Ti))]
end

function lower(arr::VirtualSparseVector, ctx::AbstractCompiler,  ::DefaultStyle)
    return arr.ex
end

function Finch.virtualize(ex, ::Type{<:SparseVector{Tv, Ti}}, ctx, tag=:tns) where {Tv, Ti}
    sym = freshen(ctx, tag)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    VirtualSparseVector(sym, Tv, Ti)
end

function Finch.declare!(arr::VirtualSparseVector, ctx::AbstractCompiler, init)
    throw(FinchProtocolError("Finch does not support writes to SparseVector"))
end

function Finch.instantiate(arr::VirtualSparseVector, ctx::AbstractCompiler, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    tag = arr.ex
    Ti = arr.Ti
    my_i = freshen(ctx.code, tag, :_i)
    my_q = freshen(ctx.code, tag, :_q)
    my_q_stop = freshen(ctx.code, tag, :_q_stop)
    my_i1 = freshen(ctx.code, tag, :_i1)
    my_val = freshen(ctx.code, tag, :_val)

    Unfurled(
        arr = arr,
        body = Furlable(
            body = (ctx, ext) -> Thunk(
                preamble = quote
                    $my_q = 1
                    $my_q_stop = length($(arr.ex).nzind) + 1
                    if $my_q < $my_q_stop
                        $my_i = $(arr.ex).nzind[$my_q]
                        $my_i1 = $(arr.ex).nzind[$my_q_stop - $(Ti(1))]
                    else
                        $my_i = $(Ti(1))
                        $my_i1 = $(Ti(0))
                    end
                end,
                body = (ctx) -> Sequence([
                    Phase(
                        stop = (ctx, ext) -> value(my_i1),
                        body = (ctx, ext) -> Stepper(
                            seek = (ctx, ext) -> quote
                                if $(arr.ex).nzind[$my_q] < $(ctx(getstart(ext)))
                                    $my_q = Finch.scansearch($(arr.ex).nzind, $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                                end
                            end,
                            preamble = :($my_i = $(arr.ex).nzind[$my_q]),
                            stop = (ctx, ext) -> value(my_i),
                            chunk = Spike(
                                body = Fill(zero(arr.Tv)),
                                tail = Thunk(
                                    preamble = quote
                                        $my_val = $(arr.ex).nzval[$my_q]
                                    end,
                                    body = (ctx) -> Fill(value(my_val, arr.Tv))
                                )
                            ),
                            next = (ctx, ext) -> quote
                                $my_q += $(Ti(1))
                            end
                        )
                    ),
                    Phase(
                        body = (ctx, ext) -> Run(Fill(zero(arr.Tv)))
                    )
                ])
            )
        )
    )
end

function Finch.instantiate(arr::VirtualSparseVector, ctx::AbstractCompiler, mode::Updater, subprotos)
    throw(FinchProtocolError("Finch does not support writes to SparseVector"))
end

Finch.FinchNotation.finch_leaf(x::VirtualSparseVector) = virtual(x)

Finch.virtual_default(arr::VirtualSparseVector, ctx) = zero(arr.Tv)
Finch.virtual_eltype(tns::VirtualSparseVector, ctx) = tns.Tv

SparseArrays.nnz(fbr::Fiber) = countstored(fbr)

end
