module SparseArraysExt 

using Finch
using Finch: LowerJulia, DefaultStyle, Extent
using Finch: Walk, Follow
using Finch: Furlable, Stepper, Jumper, Run, Fill, Lookup, Simplify, Pipeline, Phase, Thunk, Spike, Step
using Finch: virtual_size, virtual_default, getstart, getstop
using Finch.FinchNotation

using Base: @kwdef

isdefined(Base, :get_extension) ? (using SparseArrays) : (using ..SparseArrays)

function Finch.fiber(arr::SparseMatrixCSC{Tv, Ti}, default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (m, n) = size(arr)
    return Fiber(Dense(SparseList{Ti}(Element{zero(Tv)}(arr.nzval), m, arr.colptr, arr.rowval), n))
end

function Finch.fiber(arr::SparseVector{Tv, Ti}, default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (n,) = size(arr)
    return Fiber(SparseList{Ti}(Element{zero(Tv)}(arr.nzval), n, [1, length(arr.nzind) + 1], copy(arr.nzind)))
end

function Finch.fiber!(arr::SparseVector{Tv, Ti}, default=zero(Tv)) where {Tv, Ti}
    @assert iszero(default)
    (n,) = size(arr)
    return Fiber(SparseList{Ti}(Element{zero(Tv)}(arr.nzval), n, [1, length(arr.nzind) + 1], arr.nzind))
end

@kwdef mutable struct VirtualSparseMatrixCSC
    ex
    Tv
    Ti
end

function Finch.virtual_size(arr::VirtualSparseMatrixCSC, ctx::LowerJulia)
    return [Extent(literal(1),value(:($(arr.ex).m), arr.Ti)), Extent(literal(1),value(:($(arr.ex).n), arr.Ti))]
end

function (ctx::LowerJulia)(arr::VirtualSparseMatrixCSC, ::DefaultStyle)
    return arr.ex
end

function Finch.virtualize(ex, ::Type{<:SparseMatrixCSC{Tv, Ti}}, ctx, tag=:tns) where {Tv, Ti}
    sym = ctx.freshen(tag)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    VirtualSparseMatrixCSC(sym, Tv, Ti)
end

function Finch.declare!(arr::VirtualSparseMatrixCSC, ctx::LowerJulia, init)
    throw(FormatLimitation("Finch does not support writes to SparseMatrixCSC"))
end

function Finch.get_reader(arr::VirtualSparseMatrixCSC, ctx::LowerJulia, ::Union{Nothing, Walk, Follow}, ::Union{Nothing, Walk})
    tag = arr.ex
    Ti = arr.Ti
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)
    my_val = ctx.freshen(tag, :_val)

    Furlable(
        size = virtual_size(arr, ctx),
        body = (ctx, ext) -> Lookup(
            body = (j) -> Furlable(
                size = virtual_size(arr, ctx)[2:2],
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
                    body = Pipeline([
                        Phase(
                            stride = (ctx, ext) -> value(my_i1),
                            body = (ctx, ext) -> Stepper(
                                seek = (ctx, ext) -> quote
                                    if $(arr.ex).rowval[$my_q] < $(ctx(getstart(ext)))
                                        $my_q = Finch.scansearch($(arr.ex).rowval, $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                                    end
                                end,
                                body = Thunk(
                                    preamble = quote
                                        $my_i = $(arr.ex).rowval[$my_q]
                                    end,
                                    body = Step(
                                        stride = (ctx, ext) -> value(my_i),
                                        chunk = Spike(
                                            body = Simplify(Fill(zero(arr.Tv))),
                                            tail = Thunk(
                                                preamble = quote
                                                    $my_val = $(arr.ex).nzval[$my_q]
                                                end,
                                                body = Fill(value(my_val, arr.Tv))
                                            )
                                        ),
                                        next = (ctx, ext) -> quote
                                            $my_q += $(Ti(1))
                                        end
                                    )
                                )
                            )
                        ),
                        Phase(
                            body = (ctx, ext) -> Run(Simplify(Fill(zero(arr.Tv))))
                        )
                    ])
                )
            )
        )
    )
end

function Finch.get_updater(arr::VirtualSparseMatrixCSC, ctx::LowerJulia, protos...)
    throw(FormatLimitation("Finch does not support writes to SparseMatrixCSC"))
end

Finch.FinchNotation.isliteral(::VirtualSparseMatrixCSC) =  false

Finch.virtual_default(arr::VirtualSparseMatrixCSC) = zero(arr.Tv)
Finch.virtual_eltype(tns::VirtualSparseMatrixCSC) = tns.Tv

@kwdef mutable struct VirtualSparseVector
    ex
    Tv
    Ti
end

function Finch.virtual_size(arr::VirtualSparseVector, ctx::LowerJulia)
    return Any[Extent(literal(1),value(:($(arr.ex).n), arr.Ti))]
end

function (ctx::LowerJulia)(arr::VirtualSparseVector, ::DefaultStyle)
    return arr.ex
end

function Finch.virtualize(ex, ::Type{<:SparseVector{Tv, Ti}}, ctx, tag=:tns) where {Tv, Ti}
    sym = ctx.freshen(tag)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    VirtualSparseVector(sym, Tv, Ti)
end

function Finch.declare!(arr::VirtualSparseVector, ctx::LowerJulia, init)
    throw(FormatLimitation("Finch does not support writes to SparseVector"))
end

function Finch.get_reader(arr::VirtualSparseVector, ctx::LowerJulia, ::Union{Nothing, Walk})
    tag = arr.ex
    Ti = arr.Ti
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)
    my_val = ctx.freshen(tag, :_val)

    body = Furlable(
        size = virtual_size(arr, ctx),
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
            body = Pipeline([
                Phase(
                    stride = (ctx, ext) -> value(my_i1),
                    body = (ctx, ext) -> Stepper(
                        seek = (ctx, ext) -> quote
                            if $(arr.ex).nzind[$my_q] < $(ctx(getstart(ext)))
                                $my_q = scansearch($(arr.ex).nzind, $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                            end
                        end,
                        body = Thunk(
                            preamble = quote
                                $my_i = $(arr.ex).nzind[$my_q]
                            end,
                            body = Step(
                                stride = (ctx, ext) -> value(my_i),
                                chunk = Spike(
                                    body = Simplify(Fill(zero(arr.Tv))),
                                    tail = Thunk(
                                        preamble = quote
                                            $my_val = $(arr.ex).nzval[$my_q]
                                        end,
                                        body = Fill(value(my_val, arr.Tv))
                                    )
                                ),
                                next = (ctx, ext) -> quote
                                    $my_q += $(Ti(1))
                                end
                            )
                        )
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Run(Simplify(Fill(zero(arr.Tv))))
                )
            ])
        )
    )
end

function Finch.get_updater(arr::VirtualSparseVector, ctx::LowerJulia, protos...)
    throw(FormatLimitation("Finch does not support writes to SparseVector"))
end

Finch.FinchNotation.isliteral(::VirtualSparseVector) =  false

Finch.virtual_default(arr::VirtualSparseVector) = zero(arr.Tv)
Finch.virtual_eltype(tns::VirtualSparseVector) = tns.Tv

SparseArrays.nnz(fbr::Fiber) = countstored(fbr)

function __init__()
    Finch.register(Finch.DefaultAlgebra)
end

end