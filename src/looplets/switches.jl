@kwdef struct Switch
    cases
end

@kwdef struct Case
    cond 
    body
end

Base.first(arg::Case) = arg.cond
Base.last(arg::Case) = arg.body

FinchNotation.finch_leaf(x::Switch) = virtual(x)

struct SwitchStyle end

(ctx::Stylize{LowerJulia})(node::Switch) = SwitchStyle()
combine_style(a::DefaultStyle, b::SwitchStyle) = SwitchStyle()
combine_style(a::ThunkStyle, b::SwitchStyle) = ThunkStyle()
combine_style(a::AbstractSimplifyStyle, b::SwitchStyle) = a
combine_style(a::RunStyle, b::SwitchStyle) = SwitchStyle()
combine_style(a::AcceptRunStyle, b::SwitchStyle) = SwitchStyle()
combine_style(a::SpikeStyle, b::SwitchStyle) = SwitchStyle()
combine_style(a::SwitchStyle, b::SwitchStyle) = SwitchStyle()
supports_shift(::SwitchStyle) = true

@kwdef struct SwitchVisitor
    ctx
end

function (ctx::SwitchVisitor)(node)
    if istree(node)
        map(product(map(ctx, arguments(node))...)) do case
            guards = map(first, case)
            bodies = map(last, case)
            return simplify(@f(and($(guards...))), ctx.ctx) => similarterm(node, operation(node), collect(bodies))
        end
    else
        [(literal(true) => node)]
    end
end

function (ctx::SwitchVisitor)(node::FinchNode)
    if node.kind === virtual
        ctx(node.val)
    elseif istree(node)
        map(product(map(ctx, arguments(node))...)) do case
            guards = map(first, case)
            bodies = map(last, case)
            return simplify(@f(and($(guards...))), ctx.ctx) => similarterm(node, operation(node), collect(bodies))
        end
    else
        [(literal(true) => node)]
    end
end
(ctx::SwitchVisitor)(node::Switch) = node.cases

function (ctx::LowerJulia)(stmt, ::SwitchStyle)
    cases = (SwitchVisitor(ctx=ctx))(stmt)
    function nest(cases, inner=false)
        guard, body = cases[1]
        body = contain(ctx) do ctx_2
            (ctx_2)(body)
        end
        length(cases) == 1 && return body
        inner && return Expr(:elseif, ctx(guard), body, nest(cases[2:end], true))
        return Expr(:if, ctx(guard), body, nest(cases[2:end], true))
    end
    return nest(cases)
end

Base.show(io::IO, ex::Switch) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Switch)
	print(io, "Switch([...])")
end