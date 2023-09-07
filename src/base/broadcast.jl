using Base: Broadcast
using Base.Broadcast: Broadcasted, BroadcastStyle, AbstractArrayStyle
using Base: broadcasted
const AbstractArrayOrBroadcasted = Union{AbstractArray,Broadcasted}

struct Callable{F} end
@inline (::Callable{F})(args...) where {F} = F(args...)
"""
    lift_broadcast(bc)

Attempt to lift broadcast fields to the type domain for Finch analysis
"""
lift_broadcast(bc::Broadcasted{Style, Axes, F}) where {Style, Axes, F<:Function} = Broadcasted{Style}(Callable{bc.f}(), map(lift_broadcast, bc.args), bc.axes)
lift_broadcast(bc::Broadcasted{Style}) where {Style} = Broadcasted{Style}(bc.f, map(lift_broadcast, bc.args), bc.axes)
lift_broadcast(x) = x
lift_broadcast(x::Number) = Scalar(x)

struct FinchStyle{N} <: BroadcastStyle
end
Base.Broadcast.BroadcastStyle(F::Type{<:Fiber}) = FinchStyle{ndims(F)}()
Base.Broadcast.broadcastable(fbr::Fiber) = fbr
Base.Broadcast.BroadcastStyle(a::FinchStyle{N}, b::FinchStyle{M}) where {M, N} = FinchStyle{max(M, N)}()
Base.Broadcast.BroadcastStyle(a::FinchStyle{N}, b::Broadcast.AbstractArrayStyle{M}) where {M, N} = FinchStyle{max(M, N)}()

function pointwise_finch_traits(ex, ::Type{<:Broadcast.Broadcasted{Style, Axes, Callable{F}, Args}}, idxs) where {Style, F, Axes, Args}
    f = literal(F)
    args = map(enumerate(Args.parameters)) do (n, Arg)
        pointwise_finch_traits(:($ex.args[$n]), Arg, idxs)
    end
    call(f, args...)
end
function pointwise_finch_traits(ex, ::Type{<:Broadcast.Broadcasted{Style, Axes, F, Args}}, idxs) where {Style, F, Axes, Args}
    f = value(:($ex.f), F)
    args = map(enumerate(Args.parameters)) do (n, Arg)
        pointwise_finch_traits(:($ex.args[$n]), Arg, idxs)
    end
    call(f, args...)
end
function pointwise_finch_traits(ex, T, idxs)
    access(data_rep(T), reader(), idxs[1:ndims(T)]...)
end

function Base.similar(bc::Broadcast.Broadcasted{FinchStyle{N}}, ::Type{T}, dims) where {N, T}
    similar_broadcast_helper(lift_broadcast(bc))
end

@staged function similar_broadcast_helper(bc)
    ctx = JuliaContext()
    rep = data_rep(bc)
    fiber_ctr(collapse_rep(rep))
end

function data_rep(bc::Type{<:Broadcast.Broadcasted{Style, Axes, Callable{f}, Args}}) where {Style, f, Axes, Args}
    args = map(data_rep, Args.parameters)
    broadcast_rep(f, map(arg -> pad_data_rep(arg, maximum(ndims, args)), args))
end

pad_data_rep(rep, n) = ndims(rep) < n ? pad_data_rep(ExtrudeData(rep), n) : rep

struct BroadcastRepExtrudeStyle end
struct BroadcastRepSparseStyle end
struct BroadcastRepDenseStyle end
struct BroadcastRepRepeatStyle end
struct BroadcastRepElementStyle end

combine_style(a::BroadcastRepSparseStyle, b::BroadcastRepExtrudeStyle) = a
combine_style(a::BroadcastRepSparseStyle, b::BroadcastRepSparseStyle) = a
combine_style(a::BroadcastRepSparseStyle, b::BroadcastRepDenseStyle) = a
combine_style(a::BroadcastRepSparseStyle, b::BroadcastRepRepeatStyle) = a
combine_style(a::BroadcastRepSparseStyle, b::BroadcastRepElementStyle) = a

combine_style(a::BroadcastRepDenseStyle, b::BroadcastRepExtrudeStyle) = a
combine_style(a::BroadcastRepDenseStyle, b::BroadcastRepDenseStyle) = a
combine_style(a::BroadcastRepDenseStyle, b::BroadcastRepRepeatStyle) = a
combine_style(a::BroadcastRepDenseStyle, b::BroadcastRepElementStyle) = a

combine_style(a::BroadcastRepRepeatStyle, b::BroadcastRepExtrudeStyle) = a
combine_style(a::BroadcastRepRepeatStyle, b::BroadcastRepRepeatStyle) = a
combine_style(a::BroadcastRepRepeatStyle, b::BroadcastRepElementStyle) = a

combine_style(a::BroadcastRepElementStyle, b::BroadcastRepElementStyle) = a

broadcast_rep_style(r::ExtrudeData) = BroadcastRepExtrudeStyle()
broadcast_rep_style(r::SparseData) = BroadcastRepSparseStyle()
broadcast_rep_style(r::DenseData) = BroadcastRepDenseStyle()
broadcast_rep_style(r::RepeatData) = BroadcastRepRepeatStyle()
broadcast_rep_style(r::ElementData) = BroadcastRepElementStyle()

broadcast_rep(f, args) = broadcast_rep(mapreduce(broadcast_rep_style, result_style, args), f, args)

broadcast_rep_child(r::ExtrudeData) = r.lvl
broadcast_rep_child(r::SparseData) = r.lvl
broadcast_rep_child(r::DenseData) = r.lvl
broadcast_rep_child(r::RepeatData) = r.lvl

broadcast_rep(::BroadcastRepDenseStyle, f, args) = DenseData(broadcast_rep(f, map(broadcast_rep_child, args)))

function broadcast_rep(::BroadcastRepSparseStyle, f, args)
    if length(args) == 1
        return SparseData(broadcast_rep(f, map(broadcast_rep_child, args)))
    end
    for arg in args
        if isannihilator(DefaultAlgebra(), f, default(arg))
            return SparseData(broadcast_rep(f, map(broadcast_rep_child, args)))
        end
    end
    return DenseData(broadcast_rep(f, map(broadcast_rep_child, args)))
end

function broadcast_rep(::BroadcastRepRepeatStyle, f, args)
    return RepeatData(broadcast_rep(f, map(broadcast_rep_child, args)))
end

function broadcast_rep(::BroadcastRepElementStyle, f, args)
    return ElementData(f(map(default, args)...), Base.Broadcast.combine_eltypes(f, (args...,)))
end

function pointwise_finch_expr(ex, ::Type{<:Broadcast.Broadcasted{Style, Axes, F, Args}}, ctx, idxs) where {Style, F, Axes, Args}
    f = freshen(ctx, :f)
    push!(ctx.code.preamble, :($f = $ex.f))
    args = map(enumerate(Args.parameters)) do (n, Arg)
        pointwise_finch_expr(:($ex.args[$n]), Arg, ctx, idxs)
    end
    :($f($(args...)))
end

function pointwise_finch_expr(ex, ::Type{<:Broadcast.Broadcasted{Style, Axes, Callable{f}, Args}}, ctx, idxs) where {Style, f, Axes, Args}
    args = map(enumerate(Args.parameters)) do (n, Arg)
        pointwise_finch_expr(:($ex.args[$n]), Arg, ctx, idxs)
    end
    :($f($(args...)))
end

function pointwise_finch_expr(ex, T, ctx, idxs)
    src = freshen(ctx.code, :src)
    push!(ctx.code.preamble, :($src = $ex))
    :($src[$(idxs[1:ndims(T)]...)])
end

function Base.copyto!(out, bc::Broadcasted{<:FinchStyle})
    copyto_broadcast_helper!(out, lift_broadcast(bc))
end

@staged function copyto_broadcast_helper!(out, bc)
    contain(LowerJulia()) do ctx
        idxs = [freshen(ctx.code, :idx, n) for n = 1:ndims(bc)]
        pw_ex = pointwise_finch_expr(:bc, bc, ctx, idxs)
        exts = Expr(:block, (:($idx = _) for idx in reverse(idxs))...)
        quote
            @finch begin
                out .= $(default(out))
                $(Expr(:for, exts, quote
                    out[$(idxs...)] = $pw_ex
                end))
            end
            out
        end
    end
end
