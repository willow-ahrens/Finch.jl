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
    access(data_rep(T), reader(), idxs[1:ndims(T)]...)
end

function Base.similar(bc::Broadcast.Broadcasted{FinchStyle{N}}, ::Type{T}, dims) where {N, T}
    similar_broadcast_helper(lift_broadcast(bc))
end

@generated function similar_broadcast_helper(bc::Broadcast.Broadcasted{FinchStyle{N}}) where {N}
    idxs = [index(Symbol(:i, n)) for n = 1:N]
    ctx = LowerJulia()
    rep = pointwise_finch_traits(:bc, bc, idxs)
    rep = PointwiseRep(ctx)(rep, reverse(idxs))
    fiber_ctr(collapse_rep(rep))
end

struct PointwiseHollowStyle end
struct PointwiseDenseStyle end
struct PointwiseRepeatStyle end
struct PointwiseElementStyle end

combine_style(a::PointwiseHollowStyle, ::PointwiseHollowStyle) = a
combine_style(a::PointwiseHollowStyle, ::PointwiseDenseStyle) = a
combine_style(a::PointwiseHollowStyle, ::PointwiseRepeatStyle) = a
combine_style(a::PointwiseHollowStyle, ::PointwiseElementStyle) = a
combine_style(a::PointwiseDenseStyle, ::PointwiseDenseStyle) = a
combine_style(a::PointwiseDenseStyle, ::PointwiseRepeatStyle) = a
combine_style(a::PointwiseDenseStyle, ::PointwiseElementStyle) = a
combine_style(a::PointwiseRepeatStyle, ::PointwiseRepeatStyle) = a
combine_style(a::PointwiseRepeatStyle, ::PointwiseElementStyle) = a
combine_style(a::PointwiseElementStyle, ::PointwiseElementStyle) = a

struct PointwiseRep
    ctx
end

stylize_access(node, ctx::Stylize{PointwiseRep}, ::HollowData) = PointwiseHollowStyle()
stylize_access(node, ctx::Stylize{PointwiseRep}, ::SparseData) = PointwiseDenseStyle()
stylize_access(node, ctx::Stylize{PointwiseRep}, ::DenseData) = PointwiseDenseStyle()
stylize_access(node, ctx::Stylize{PointwiseRep}, ::RepeatData) =
    !isempty(ctx.root) && first(ctx.root) == last(node.idxs) ? PointwiseRepeatStyle() : PointwiseDenseStyle()
stylize_access(node, ctx::Stylize{PointwiseRep}, ::ElementData) =
    isempty(ctx.root) ? PointwiseElementStyle() : PointwiseDenseStyle()

pointwise_rep_body(tns::SparseData) = HollowData(tns.lvl)
pointwise_rep_body(tns::DenseData) = tns.lvl
pointwise_rep_body(tns::RepeatData) = tns.lvl
pointwise_rep_body(tns::ElementData) = tns.lvl

(ctx::PointwiseRep)(rep, idxs) = ctx(rep, idxs, Stylize(idxs, ctx)(rep))
function (ctx::PointwiseRep)(rep, idxs, ::PointwiseHollowStyle)
    background = simplify(Postwalk(Chain([
        (@rule access(~ex::isvirtual, ~m, ~i...) => access(pointwise_rep_hollow(ex.val), m, i...)),
    ]))(rep), LowerJulia())
    body = simplify(Postwalk(Chain([
        (@rule access(~ex::isvirtual, ~m, ~i...) => access(pointwise_rep_solid(ex.val), m, i...)),
    ]))(rep), LowerJulia())
    if isliteral(background)
        return HollowData(ctx(body, idxs))
    else
        return ctx(body, idxs)
    end
end

function (ctx::PointwiseRep)(rep, idxs, ::PointwiseDenseStyle)
    body = simplify(Rewrite(Postwalk(Chain([
        (@rule access(~ex::isvirtual, ~m, ~i..., $(idxs[1])) => access(pointwise_rep_body(ex.val), m, i...)),
    ])))(rep), LowerJulia())
    return DenseData(ctx(body, idxs[2:end]))
end

function (ctx::PointwiseRep)(rep, idxs, ::PointwiseRepeatStyle)
    background = simplify(PostWalk(Chain([
        (@rule access(~ex::isvirtual, ~m, ~i...) => default(ex.val)),
    ]))(rep), LowerJulia())
    @assert isliteral(background)
    return RepeatData(finch_leaf(background).val, typeof(finch_leaf(background).val))
end

function (ctx::PointwiseRep)(rep, idxs, ::PointwiseElementStyle)
    background = simplify(Postwalk(Chain([
        (@rule access(~ex::isvirtual, ~m) => default(ex.val)),
    ]))(rep), LowerJulia())
    @assert isliteral(background)
    return ElementData(finch_leaf(background).val, typeof(finch_leaf(background).val))
end

pointwise_rep_hollow(ex::HollowData) = Fill(default(ex))
pointwise_rep_hollow(ex) = ex
pointwise_rep_solid(tns::HollowData) = pointwise_rep_solid(tns.lvl)
pointwise_rep_solid(ex) = ex

function pointwise_finch_expr(ex, ::Type{<:Broadcast.Broadcasted{Style, Axes, F, Args}}, ctx, idxs) where {Style, F, Axes, Args}
    f = ctx.freshen(:f)
    push!(ctx.preamble, :($f = $ex.f))
    args = map(enumerate(Args.parameters)) do (n, Arg)
        pointwise_finch_expr(:($ex.args[$n]), Arg, ctx, idxs)
    end
    :($f($(args...)))
end

function pointwise_finch_expr(ex, T, ctx, idxs)
    src = ctx.freshen(:src)
    push!(ctx.preamble, :($src = $ex))
    :($src[$(idxs[1:ndims(T)]...)])
end

@generated function Base.copyto!(out, bc::Broadcasted{FinchStyle{N}}) where {N}
    copyto_helper!(:out, out, :bc, bc)
end

function copyto_helper!(out_ex, out, bc_ex, bc::Type{<:Broadcasted{FinchStyle{N}}}) where {N}
    contain(LowerJulia()) do ctx
        idxs = [ctx.freshen(:idx, n) for n = 1:N]
        pw_ex = pointwise_finch_expr(bc_ex, bc, ctx, idxs)
        quote
            @finch begin
                $out_ex .= $(default(out))
                @loop($(reverse(idxs)...), $out_ex[$(idxs...)] = $pw_ex)
            end
            $out_ex
        end
    end |> lower_caches |> lower_cleanup |> unblock
end
