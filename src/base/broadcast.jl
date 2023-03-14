using Base: Broadcast
using Base.Broadcast: Broadcasted, BroadcastStyle, AbstractArrayStyle
const AbstractArrayOrBroadcasted = Union{AbstractArray,Broadcasted}

#=
function Base.mapreduce(f, op, A::Fiber, As::AbstractArrayOrBroadcasted...; dims=:, init=nothing)=
    _mapreduce(f, op, A, As..., dims, init)
function _mapreduce(f, op, As..., dims, init)
    init === nothing && throw(ArgumentError("Finch requires an initial value for reductions."))
    init = something(init)
    allequal(ndims.(As)) || throw(ArgumentError("Finch cannot currently mapreduce arguments with differing numbers of dimensions"))
    allequal(axes.(As)) || throw(DimensionMismatchError("Finch cannot currently mapreduce arguments with differing size"))
    reduce(op, Broadcast.broadcasted(f, As...), dims, init)
end
=#

struct Callable{F} end
@inline (::Callable{F})(args...) where {F} = F(args...)
"""
    lift_broadcast(bc)

Attempt to lift broadcast fields to the type domain for Finch analysis
"""
lift_broadcast(bc::Broadcasted{Style, Axes, F}) where {Style, Axes, F<:Function} = Broadcasted{Style}(Callable{bc.f}(), map(lift_broadcast, bc.args), bc.axes)
lift_broadcast(bc::Broadcasted{Style}) where {Style} = Broadcasted{Style}(bc.f, map(lift_broadcast, bc.args), bc.axes)
lift_broadcast(x) = x

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
    access(data_rep(T), reader(), idxs[end-ndims(T)+1:end]...)
end

function Base.similar(bc::Broadcast.Broadcasted{FinchStyle{N}}, ::Type{T}, dims) where {N, T}
    similar_broadcast_helper(lift_broadcast(bc))
end

@generated function similar_broadcast_helper(bc::Broadcast.Broadcasted{FinchStyle{N}}) where {N}
    idxs = [index(Symbol(:i, n)) for n = 1:N]
    ctx = LowerJulia()
    rep = pointwise_finch_traits(:bc, bc, idxs)
    fiber_ctr(SolidData(PointwiseRep(ctx)(rep, reverse(idxs))))
end

struct PointwiseSparseStyle end
struct PointwiseDenseStyle end
struct PointwiseRepeatStyle end
struct PointwiseElementStyle end

result_style(a::PointwiseSparseStyle, ::PointwiseSparseStyle) = a
result_style(a::PointwiseSparseStyle, ::PointwiseDenseStyle) = a
result_style(a::PointwiseSparseStyle, ::PointwiseRepeatStyle) = a
result_style(a::PointwiseSparseStyle, ::PointwiseElementStyle) = a
result_style(a::PointwiseDenseStyle, ::PointwiseDenseStyle) = a
result_style(a::PointwiseDenseStyle, ::PointwiseRepeatStyle) = a
result_style(a::PointwiseDenseStyle, ::PointwiseElementStyle) = a
result_style(a::PointwiseRepeatStyle, ::PointwiseRepeatStyle) = a
result_style(a::PointwiseRepeatStyle, ::PointwiseElementStyle) = a
result_style(a::PointwiseElementStyle, ::PointwiseElementStyle) = a

struct PointwiseRep
    ctx
end

stylize_access(node, ctx::Stylize{PointwiseRep}, tns::SolidData) = stylize_access(node, ctx, tns.lvl)
stylize_access(node, ctx::Stylize{PointwiseRep}, tns::HollowData) = stylize_access(node, ctx, tns.lvl)
function stylize_access(node, ctx::Stylize{PointwiseRep}, ::SparseData)
    if !isempty(ctx.root) && first(ctx.root) == last(node.idxs) PointwiseSparseStyle() end
end
stylize_access(node, ctx::Stylize{PointwiseRep}, ::DenseData) = if !isempty(ctx.root) && first(ctx.root) == last(node.idxs) PointwiseDenseStyle() end
stylize_access(node, ctx::Stylize{PointwiseRep}, ::RepeatData) = if !isempty(ctx.root) && first(ctx.root) == last(node.idxs) PointwiseRepeatStyle() end
stylize_access(node, ctx::Stylize{PointwiseRep}, ::ElementData) = isempty(ctx.root) ? PointwiseElementStyle() : PointwiseDenseStyle()

pointwise_rep_body(tns::SolidData) = pointwise_rep_body(tns.lvl)
pointwise_rep_body(tns::HollowData) = pointwise_rep_body(tns.lvl)
pointwise_rep_body(tns::SparseData) = tns.lvl
pointwise_rep_body(tns::DenseData) = tns.lvl
pointwise_rep_body(tns::RepeatData) = tns.lvl
pointwise_rep_body(tns::ElementData) = tns.lvl

(ctx::PointwiseRep)(rep, idxs) = ctx(rep, idxs, Stylize(idxs, ctx)(rep))
function (ctx::PointwiseRep)(rep, idxs, ::PointwiseSparseStyle)
    background = simplify(Postwalk(Chain([
        (@rule access(~ex::isvirtual, ~m, ~i..., $(idxs[1])) => access(pointwise_rep_sparse(ex.val), m, i..., idxs[1])),
    ]))(rep), LowerJulia())
    if isliteral(background)
        body = simplify(Postwalk(Chain([
            (@rule access(~ex::isvirtual, ~m, ~i..., $(idxs[1])) => access(pointwise_rep_body(ex.val), m, i...)),
        ]))(rep), LowerJulia())
        return SparseData(ctx(body, idxs[2:end]))
    else
        ctx(rep, idxs, Stylize(idxs, ctx)(background))
    end
end

function (ctx::PointwiseRep)(rep, idxs, ::PointwiseDenseStyle)
    body = simplify(Postwalk(Chain([
        (@rule access(~ex::isvirtual, ~m, ~i..., $(idxs[1])) => access(pointwise_rep_body(ex.val), m, i...)),
    ]))(rep), LowerJulia())
    return DenseData(ctx(body, idxs[2:end]))
end

function (ctx::PointwiseRep)(rep, idxs, ::PointwiseRepeatStyle)
    background = simplify(PostWalk(Chain([
        (@rule access(~ex::isvirtual, ~m, ~i...) => default(ex.val)),
    ]))(rep), LowerJulia())
    @assert isliteral(background)
    return RepeatData(background.val, typeof(background.val))
end

function (ctx::PointwiseRep)(rep, idxs, ::PointwiseElementStyle)
    background = simplify(Postwalk(Chain([
        (@rule access(~ex::isvirtual, ~m) => default(ex.val)),
    ]))(rep), LowerJulia())
    @assert isliteral(background)
    return ElementData(background.val, typeof(background.val))
end

pointwise_rep_sparse(ex::SparseData) = Fill(default(ex))
pointwise_rep_sparse(ex) = ex

function pointwise_finch_expr(ex, ::Type{<:Broadcast.Broadcasted{Style, Axes, F, Args}}, idxs) where {Style, F, Axes, Args}
    args = map(enumerate(Args.parameters)) do (n, Arg)
        pointwise_finch_expr(:($ex.args[$n]), Arg, idxs)
    end
    :($ex.f($(args...)))
end

function pointwise_finch_expr(ex, T, idxs)
    :($ex[(idxs[end-ndims(T)+1:end]...)])
end

@generated function Base.copyto!(out, bc::Broadcasted{FinchStyle{N}}) where {N}
    copyto_helper!(ex, bc, idxs)
end

#=
function copyto_helper!(ex, out, bc)
    ctx = LowerJulia()
    res = contain(ctx) do ctx_2
        idxs = [ctx_2.freshen(:idx, n) for n = 1:N]
        ex = pointwise_finch_expr(ex, bc, idxs)
        quote
            @finch begin
                out .= $(default(out))
                @loop($(reverse(idxs)...), out[$(idxs...)] = $ex)
            end
        end
    end
    quote
        println($(QuoteNode(res)))
        $res
        out
    end
end

function reduce(op, bc::Broadcasted{FinchStyle{N}}, dims, init) where {N}
    T = Base.combine_eltypes(bc.f, bc.args::Tuple)
end
=#
