#Note that lookups are lowered by the DefaultStyle loop lowerer in lower.jl

@kwdef struct Lookup
    body
end

Base.show(io::IO, ex::Lookup) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Lookup)
    print(io, "Lookup()")
end

FinchNotation.finch_leaf(x::Lookup) = virtual(x)
get_point_body(node::Lookup, ctx, ext, idx) = node.body(ctx, idx)