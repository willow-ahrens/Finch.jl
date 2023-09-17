#Note that lookups are lowered by the DefaultStyle loop lowerer in lower.jl

@kwdef struct Lookup
    body
end

Base.show(io::IO, ex::Lookup) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Lookup)
    print(io, "Lookup()")
end

FinchNotation.finch_leaf(x::Lookup) = virtual(x)

struct LookupStyle end

(ctx::Stylize{<:AbstractCompiler})(node::Lookup) = ctx.root.kind === loop ? LookupStyle() : DefaultStyle()
combine_style(a::DefaultStyle, b::LookupStyle) = LookupStyle()
combine_style(a::ThunkStyle, b::LookupStyle) = ThunkStyle()
combine_style(a::SimplifyStyle, b::LookupStyle) = a
combine_style(a::LookupStyle, b::LookupStyle) = LookupStyle()

function lower(root::FinchNode, ctx::AbstractCompiler,  ::LookupStyle)
    if root.kind === loop
        idx_sym = freshen(ctx.code, root.idx.name)
        body = contain(ctx) do ctx_2
            ctx_2.bindings[root.idx] = value(idx_sym)
            body_3 = Rewrite(Postwalk(
                @rule access(~a::isvirtual, ~m, ~i..., ~j) => begin
                    a_2 = get_point_body(a.val, ctx_2, root.ext.val, value(idx_sym))
                    if a_2 != nothing
                        access(a_2, m, i...)
                    else
                        access(a, m, i..., j)
                    end
                end
            ))(root.body)
            body_3 = simplify(body_3, ctx)
            open_scope(body_3, ctx_2)
        end

        @assert isvirtual(root.ext)

        if query_z3(call(==, measure(root.ext.val), get_smallest_measure(root.ext.val)), ctx)
            return quote
                $idx_sym = $(ctx(getstart(root.ext)))
                $body
            end
        else
            return quote
                for $idx_sym = $(ctx(getstart(root.ext))):$(ctx(getstop(root.ext)))
                    $body
                end
            end
        end
    else
        error("unimplemented")
    end
end

get_point_body(node::Lookup, ctx, ext, idx) = node.body(ctx, idx)

get_point_body(node, ctx, ext, idx) = nothing
