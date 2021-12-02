Base.@kwdef struct Cases
    cases
end

struct CaseStyle end

#TODO handle children of access?
Pigeon.make_style(root, ctx::LowerJuliaContext, node::Cases) = CaseStyle()
Pigeon.combine_style(a::DefaultStyle, b::CaseStyle) = CaseStyle()
Pigeon.combine_style(a::RunAccessStyle, b::CaseStyle) = CaseStyle()
Pigeon.combine_style(a::RunAssignStyle, b::CaseStyle) = CaseStyle()
Pigeon.combine_style(a::SpikeStyle, b::CaseStyle) = CaseStyle()
Pigeon.combine_style(a::CaseStyle, b::CaseStyle) = CaseStyle()

function Pigeon.visit!(stmt, ctx::LowerJuliaContext, ::CaseStyle)
    cases = collect_cases(stmt, ctx)
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

collect_cases_reduce(x, y) = x === true ? y : (y === true : x : :($x && $y))
function collect_cases(node, ctx)
    if istree(node)
        map(product(map(arg->collect_cases(arg, ctx), arguments(node))...)) do case
            (guards, bodies) = zip(case...)
            (reduce(collect_cases_reduce, guards), operation(node)(bodies...))
        end
    else
        [(true, node),]
    end
end

function collect_cases(node::Cases, ctx::LowerJuliaContext)
    node.cases
end

