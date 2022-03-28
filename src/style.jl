struct DefaultStyle end
struct UnknownStyle end

make_style(root, ctx) = make_style(root, ctx, root)
function make_style(root, ctx, node)
    if istree(node)
        #m = map(arg->make_style(root, ctx, arg), arguments(node))
        #r = reduce(result_style, m)
        #s = resolve_style(root, ctx, node, r)
        @info "hmm" node
        return resolve_style(root, ctx, node, mapreduce(arg->make_style(root, ctx, arg), result_style, arguments(node); init=DefaultStyle()))
        #return s
    end
    return DefaultStyle()
end

result_style(a, b) = _result_style(a, b, combine_style(a, b), combine_style(b, a))
_result_style(a, b, c::UnknownStyle, d::UnknownStyle) = throw(MethodError(combine_style, (a, b)))
_result_style(a, b, c, d::UnknownStyle) = c
_result_style(a, b, c::UnknownStyle, d) = d
_result_style(a, b, c::T, d::T) where {T} = (c == d) ? c : @assert false "TODO lower_style_ambiguity_error"
_result_style(a, b, c, d) = (c == d) ? c : @assert false "TODO lower_style_ambiguity_error"
combine_style(a, b) = UnknownStyle()

combine_style(a::DefaultStyle, b) = b
resolve_style(root, ctx, node, style) = style

abstract type AbstractVisitor end

(ctx::AbstractVisitor)(root) = ctx(root, make_style(root, ctx))

abstract type AbstractTransformVisitor <: AbstractVisitor end

(ctx::AbstractTransformVisitor)(node, style::DefaultStyle) = visit_default!(node, ctx)
function visit_default!(node, ctx)
    node = previsit!(node, ctx)
    if istree(node)
        postvisit!(node, ctx, map(ctx, arguments(node)))
    else
        postvisit!(node, ctx)
    end
end

previsit!(node, ctx::AbstractTransformVisitor) = node
postvisit!(node, ctx::AbstractTransformVisitor, args) = similarterm(node, operation(node), args)
postvisit!(node, ctx::AbstractTransformVisitor) = node

abstract type AbstractCollectVisitor <: AbstractTransformVisitor end
function collect_op end
function collect_zero end

previsit!(node, ctx::AbstractCollectVisitor) = node
postvisit!(node, ctx::AbstractCollectVisitor, args) = collect_op(ctx)(args)
postvisit!(node, ctx::AbstractCollectVisitor) = collect_zero(ctx)

abstract type AbstractWrapperVisitor <: AbstractTransformVisitor end

previsit!(node, ctx::AbstractWrapperVisitor) = previsit!(node, getparent(ctx))
postvisit!(node, ctx::AbstractWrapperVisitor, args) = transform(node, getparent(ctx), args)
postvisit!(node, ctx::AbstractWrapperVisitor) = postvisit!(node, getparent(ctx))

getdata(ctx) = ctx
getdata(ctx::AbstractWrapperVisitor) = getdata(getparent(ctx))

struct PostMapVisitor{F} <: AbstractTransformVisitor
    f::F
end

function (ctx::PostMapVisitor)(node, ::DefaultStyle)
    node′ = ctx.f(node)
    if node′ === nothing
        visit_default!(node, ctx)
    else
        something(node′)
    end
end

postmap(f, root) = (PostMapVisitor(f))(root)

struct PostMapReduceVisitor{F, G} <: AbstractCollectVisitor
    f::F
    g::G
    init
end

postvisit!(node, ctx::PostMapReduceVisitor) = ctx.init
postvisit!(node, ctx::PostMapReduceVisitor, args) = ctx.g(args...)
function (ctx::PostMapReduceVisitor)(node, ::DefaultStyle)
    node′ = ctx.f(node)
    if node′ === nothing
        visit_default!(node, ctx)
    else
        something(node′)
    end
end

postmapreduce(f, g, root, init) = (PostMapReduceVisitor(f, g, init))(root)

@kwdef struct QuantifiedVisitor{Ctx} <: AbstractTransformVisitor
    parent::Ctx
    qnt = []
    diff = []
end

getparent(ctx::QuantifiedVisitor) = ctx.ctx
getqnt(ctx::QuantifiedVisitor) = ctx.qnt
getqnt(ctx) = getqnt(getparent(ctx))

function previsit!(node, ctx::QuantifiedVisitor)
    push!(diff, 0)
end
function previsit!(node::Loop, ctx::QuantifiedVisitor)
    append!(ctx.qnt, node.idxs)
    push!(diff, length(node.idxs))
    previsit!(node, ctx.ctx)
end
function postvisit!(node, ctx::QuantifiedVisitor)
    for i in 1:pop!(node.diff)
        pop!(ctx.qnt)
    end
end