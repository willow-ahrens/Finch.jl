struct DefaultStyle end
struct UnknownStyle end

@kwdef struct Stylize{Ctx}
    root
    ctx::Ctx
end

function (ctx::Stylize)(node)
    if istree(node)
        return mapreduce(ctx, result_style, arguments(node); init=DefaultStyle())
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

abstract type AbstractVisitor end

(ctx::AbstractVisitor)(root) = ctx(root, Stylize(root, ctx)(root))

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