Base.@kwdef struct Cases
    cases
end

Pigeon.isliteral(::Cases) = false

struct CaseStyle end

#TODO handle children of access?
Pigeon.make_style(root, ctx::LowerJuliaContext, node::Cases) = CaseStyle()
Pigeon.combine_style(a::DefaultStyle, b::CaseStyle) = CaseStyle()
Pigeon.combine_style(a::RunAccessStyle, b::CaseStyle) = CaseStyle()
Pigeon.combine_style(a::RunAssignStyle, b::CaseStyle) = CaseStyle()
Pigeon.combine_style(a::SpikeStyle, b::CaseStyle) = CaseStyle()
Pigeon.combine_style(a::CaseStyle, b::CaseStyle) = CaseStyle()

struct CasesContext <: Pigeon.AbstractCollectContext end

function Pigeon.visit!(stmt, ctx::LowerJuliaContext, ::CaseStyle)
    cases = visit!(stmt, CasesContext())
    thunk = Expr(:block)
    for (guard, body) in cases
        push!(thunk.args, :(
            if $(guard)
                $(visit!(body, ctx))
            end
        ))
    end
    return thunk
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