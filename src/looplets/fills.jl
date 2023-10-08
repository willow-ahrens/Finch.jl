struct Fill
    body::FinchNode
    Fill(x) = new(finch_leaf(x))
end

FinchNotation.finch_leaf(x::Fill) = virtual(x)
virtual_default(f::Fill, ctx) = f.body

struct FillStyle end

(ctx::Stylize{<:AbstractCompiler})(::Fill) = FillStyle()

instantiate(tns::Fill, ctx, mode, protos) = tns

combine_style(a::DefaultStyle, b::FillStyle) = FillStyle()
combine_style(a::LookupStyle, b::FillStyle) = FillStyle()
combine_style(a::ThunkStyle, b::FillStyle) = FillStyle()
combine_style(a::SimplifyStyle, b::FillStyle) = a
combine_style(a::RunStyle, b::FillStyle) = FillStyle()
combine_style(a::AcceptRunStyle, b::FillStyle) = FillStyle()
combine_style(a::SpikeStyle, b::FillStyle) = FillStyle()
combine_style(a::FillStyle, b::SimplifyStyle) = FillStyle()
combine_style(a::FillStyle, b::FillStyle) = FillStyle()
combine_style(a::FillStyle, b::StepperStyle) = FillStyle()
combine_style(a::FillStyle, b::JumperStyle) = FillStyle()

function lower(root::FinchNode, ctx::AbstractCompiler, ::FillStyle)
    ctx(Postwalk(@rule access(~a::isvirtual, ~m, ~i...) => visit_fill(access(a, m, i...), a.val))(root))
end

visit_fill(node, tns) = nothing
visit_fill(node, tns::Fill) = Simplify(tns.body)