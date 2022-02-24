@kwdef struct Cases
    cases
end

isliteral(::Cases) = false

struct CaseStyle end

make_style(root, ctx::LowerJulia, node::Cases) = CaseStyle()
combine_style(a::DefaultStyle, b::CaseStyle) = CaseStyle()
combine_style(a::ThunkStyle, b::CaseStyle) = ThunkStyle()
combine_style(a::RunStyle, b::CaseStyle) = CaseStyle()
combine_style(a::AcceptRunStyle, b::CaseStyle) = CaseStyle()
combine_style(a::AcceptSpikeStyle, b::CaseStyle) = CaseStyle()
combine_style(a::SpikeStyle, b::CaseStyle) = CaseStyle()
combine_style(a::CaseStyle, b::CaseStyle) = CaseStyle()

struct CasesVisitor <: AbstractCollectVisitor end

function (ctx::LowerJulia)(stmt, ::CaseStyle)
    cases = (CasesVisitor())(stmt)
    ctx_2s = []
    function nest(cases, inner=false)
        guard, body = cases[1]
        ctx_2 = diverge(ctx)
        body = contain(ctx_2) do ctx_3
            (ctx_3)(body)
        end
        push!(ctx_2s, ctx_2)
        length(cases) == 1 && return body
        inner && return Expr(:elseif, guard, body, nest(cases[2:end], true))
        return Expr(:if, guard, body, nest(cases[2:end], true))
    end
    for ctx_2 in ctx_2s
        unify!(ctx, ctx_2)
    end
    return nest(cases)
end

virtual_and(x, y) = x === true ? y :
                    y === true ? x :
                    :($x && $y)

function postvisit!(node, ctx::CasesVisitor, args)
    map(product(args...)) do case
        guards = map(first, case)
        bodies = map(last, case)
        return reduce(virtual_and, guards) => similarterm(node, operation(node), collect(bodies))
    end
end
postvisit!(node, ctx::CasesVisitor) = [(true => node)]
(ctx::CasesVisitor)(node::Cases, ::DefaultStyle) = node.cases