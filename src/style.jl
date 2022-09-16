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