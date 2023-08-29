module SparseArraysExt 

using Finch
using Finch: AbstractCompiler, DefaultStyle, Extent
using Finch: Unfurled, Furlable, Replay, Run, Fill, Lookup, Simplify, Sequence, Phase, Thunk, Spike, Step
using Finch: virtual_size, virtual_default, getstart, getstop
using Finch.FinchNotation

using Base: @kwdef

isdefined(Base, :get_extension) ? (using SparseArrays) : (using ..SparseArrays)

function Finch.fiber(arr::SparseMatrixCSC{Tv, Ti}; default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (m, n) = size(arr)
    return Fiber(Dense(SparseList{Ti}(Element{zero(Tv)}(copy(arr.nzval)), m, copy(arr.colptr), copy(arr.rowval)), n))
end

function Finch.fiber!(arr::SparseMatrixCSC{Tv, Ti}; default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (m, n) = size(arr)
    return Fiber(Dense(SparseList{Ti}(Element{zero(Tv)}(arr.nzval), m, arr.colptr, arr.rowval), n))
end

function Finch.fiber(arr::SparseVector{Tv, Ti}; default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (n,) = size(arr)
    return Fiber(SparseList{Ti}(Element{zero(Tv)}(arr.nzval), n, [1, length(arr.nzind) + 1], copy(arr.nzind)))
end

function Finch.fiber!(arr::SparseVector{Tv, Ti}; default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (n,) = size(arr)
    return Fiber(SparseList{Ti}(Element{zero(Tv)}(arr.nzval), n, [1, length(arr.nzind) + 1], arr.nzind))
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
    sym = ctx.freshen(tag)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    VirtualSparseMatrixCSC(sym, Tv, Ti)
end

function Finch.declare!(arr::VirtualSparseMatrixCSC, ctx::AbstractCompiler, init)
    throw(FormatLimitation("Finch does not support writes to SparseMatrixCSC"))
end

function Finch.instantiate_reader(arr::VirtualSparseMatrixCSC, ctx::AbstractCompiler, subprotos, ::Union{typeof(defaultread), typeof(walk), typeof(follow)}, ::Union{typeof(defaultread), typeof(walk)})
    tag = arr.ex
    Ti = arr.Ti
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)
    my_val = ctx.freshen(tag, :_val)

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
                                body = (ctx, ext) -> Replay(
                                    seek = (ctx, ext) -> quote
                                        if $(arr.ex).rowval[$my_q] < $(ctx(getstart(ext)))
                                            $my_q = Finch.scansearch($(arr.ex).rowval, $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                                        end
                                    end,
                                    body = Step(
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

function Finch.instantiate_updater(arr::VirtualSparseMatrixCSC, ctx::AbstractCompiler, subprotos, protos...)
    throw(FormatLimitation("Finch does not support writes to SparseMatrixCSC"))
end

Finch.FinchNotation.finch_leaf(x::VirtualSparseMatrixCSC) = virtual(x)

Finch.virtual_default(arr::VirtualSparseMatrixCSC, ctx) = zero(arr.Tv)
Finch.virtual_eltype(tns::VirtualSparseMatrixCSC, ctx) = tns.Tv

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
    sym = ctx.freshen(tag)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    VirtualSparseVector(sym, Tv, Ti)
end

function Finch.declare!(arr::VirtualSparseVector, ctx::AbstractCompiler, init)
    throw(FormatLimitation("Finch does not support writes to SparseVector"))
end

function Finch.instantiate_reader(arr::VirtualSparseVector, ctx::AbstractCompiler, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    tag = arr.ex
    Ti = arr.Ti
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)
    my_val = ctx.freshen(tag, :_val)

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
                        body = (ctx, ext) -> Replay(
                            seek = (ctx, ext) -> quote
                                if $(arr.ex).nzind[$my_q] < $(ctx(getstart(ext)))
                                    $my_q = Finch.scansearch($(arr.ex).nzind, $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                                end
                            end,
                            body = Step(
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

function Finch.instantiate_updater(arr::VirtualSparseVector, ctx::AbstractCompiler, subprotos)
    throw(FormatLimitation("Finch does not support writes to SparseVector"))
end

Finch.FinchNotation.finch_leaf(x::VirtualSparseVector) = virtual(x)

Finch.virtual_default(arr::VirtualSparseVector, ctx) = zero(arr.Tv)
Finch.virtual_eltype(tns::VirtualSparseVector, ctx) = tns.Tv

SparseArrays.nnz(fbr::Fiber) = countstored(fbr)

end
