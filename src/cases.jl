@kwdef struct Cases
    cases
end

isliteral(::Cases) = false

struct CaseStyle end

(ctx::Stylize{LowerJulia})(node::Cases) = CaseStyle()
combine_style(a::DefaultStyle, b::CaseStyle) = CaseStyle()
combine_style(a::ThunkStyle, b::CaseStyle) = ThunkStyle()
combine_style(a::SimplifyStyle, b::CaseStyle) = SimplifyStyle()
combine_style(a::RunStyle, b::CaseStyle) = CaseStyle()
combine_style(a::AcceptRunStyle, b::CaseStyle) = CaseStyle()
combine_style(a::SpikeStyle, b::CaseStyle) = CaseStyle()
combine_style(a::CaseStyle, b::CaseStyle) = CaseStyle()
supports_shift(::CaseStyle) = true

struct CasesVisitor end

function (ctx::CasesVisitor)(node)
    if istree(node)
        map(product(map(ctx, arguments(node))...)) do case
            guards = map(first, case)
            bodies = map(last, case)
            return simplify(@i(and($(guards...)))) => similarterm(node, operation(node), collect(bodies))
        end
    else
        [(true => node)]
    end
end
(ctx::CasesVisitor)(node::Cases) = node.cases

function (ctx::LowerJulia)(stmt, ::CaseStyle)
    cases = (CasesVisitor())(stmt)
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

Base.show(io::IO, ex::Cases) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Cases)
	print(io, "Cases([...])")
end