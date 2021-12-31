Base.@kwdef struct Cases
    cases
end

Pigeon.isliteral(::Cases) = false

struct CaseStyle end

Pigeon.make_style(root, ctx::LowerJuliaContext, node::Cases) = CaseStyle()
Pigeon.combine_style(a::DefaultStyle, b::CaseStyle) = CaseStyle()
Pigeon.combine_style(a::ThunkStyle, b::CaseStyle) = ThunkStyle()
Pigeon.combine_style(a::RunStyle, b::CaseStyle) = CaseStyle()
Pigeon.combine_style(a::AcceptRunStyle, b::CaseStyle) = CaseStyle()
Pigeon.combine_style(a::AcceptSpikeStyle, b::CaseStyle) = CaseStyle()
Pigeon.combine_style(a::SpikeStyle, b::CaseStyle) = CaseStyle()
Pigeon.combine_style(a::CaseStyle, b::CaseStyle) = CaseStyle()

struct CasesContext <: Pigeon.AbstractCollectContext end

function Pigeon.visit!(stmt, ctx::LowerJuliaContext, ::CaseStyle)
    cases = visit!(stmt, CasesContext())
    function nest(cases, inner=false)
        guard, body = cases[1]
        body = visit!(body, ctx)
        length(cases) == 1 && return body
        inner && return Expr(:elseif, guard, body, nest(cases[2:end], true))
        return Expr(:if, guard, body, nest(cases[2:end], true))
    end
    return nest(cases)
end

virtual_and(x, y) = x === true ? y :
                    y === true ? x :
                    :($x && $y)

function Pigeon.postvisit!(node, ctx::CasesContext, args)
    map(product(args...)) do case
        guards = map(first, case)
        bodies = map(last, case)
        return reduce(virtual_and, guards) => similarterm(node, operation(node), collect(bodies))
    end
end
Pigeon.postvisit!(node, ctx::CasesContext) = [(true => node)]
Pigeon.visit!(node::Cases, ctx::CasesContext, ::DefaultStyle) = node.cases