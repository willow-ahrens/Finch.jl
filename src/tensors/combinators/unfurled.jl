@kwdef struct Unfurled
    body
    ndims
    arr
    Unfurled(body, ndims, arr) = new(body, ndims, arr) 
    Unfurled(body::Nothing, ndims, arr) = error()
end

Base.show(io::IO, ex::Unfurled) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Unfurled)
    print(io, "Unfurled(")
    print(io, ex.body)
    print(io, ", ")
    print(io, ex.ndims)
    print(io, ", ")
    print(io, ex.arr)
    print(io, ")")
end

Base.summary(io::IO, ex::Unfurled) = print(io, "Unfurled($(summary(ex.body)), $(summary(ex.arr)))")

FinchNotation.finch_leaf(x::Unfurled) = virtual(x)





unfurl_reader(tns::Unfurled, ctx::LowerJulia, protos...) = tns
unfurl_updater(tns::Unfurled, ctx::LowerJulia, protos...) = tns

(ctx::Stylize{<:AbstractCompiler})(node::Unfurled) = ctx(node.body)
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::Unfurled)
    stylize_access(node, ctx, tns.body)
end

function popdim(node::Unfurled)
    if node.ndims == 1
        return node.body
    else
        return Unfurled(node.body, node.ndims - 1, node.arr)
    end
end

truncate(node::Unfurled, ctx, ext, ext_2) = Unfurled(truncate(node.body, ctx, ext, ext_2), node.ndims, node.arr)

function get_point_body(node::Unfurled, ctx, ext, idx)
    body_2 = get_point_body(node.body, ctx, ext, idx)
    if body_2 === nothing
        return nothing
    else
        return popdim(Unfurled(body_2, node.ndims, node.arr))
    end
end


(ctx::ThunkVisitor)(node::Unfurled) = Unfurled(ctx(node.body), node.ndims, node.arr)

function get_run_body(node::Unfurled, ctx, ext)
    body_2 = get_run_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(Unfurled(body_2, node.ndims, node.arr))
    end
end

function get_acceptrun_body(node::Unfurled, ctx, ext)
    body_2 = get_acceptrun_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(Unfurled(body_2, node.ndims, node.arr))
    end
end

function (ctx::PipelineVisitor)(node::Unfurled)
    map(ctx(node.body)) do (keys, body)
        return keys => Unfurled(body, node.ndims, node.arr)
    end
end

phase_body(node::Unfurled, ctx, ext, ext_2) = Unfurled(phase_body(node.body, ctx, ext, ext_2), node.ndims, node.arr)
phase_range(node::Unfurled, ctx, ext) = phase_range(node.body, ctx, ext)

get_spike_body(node::Unfurled, ctx, ext, ext_2) = Unfurled(get_spike_body(node.body, ctx, ext, ext_2), node.ndims, node.arr)
get_spike_tail(node::Unfurled, ctx, ext, ext_2) = Unfurled(get_spike_tail(node.body, ctx, ext, ext_2), node.ndims, node.arr)

visit_fill(node, tns::Unfurled) = visit_fill(node, tns.body)
visit_simplify(node::Unfurled) = Unfurled(visit_simplify(node.body), node.ndims, node.arr)

(ctx::SwitchVisitor)(node::Unfurled) = map(ctx(node.body)) do (guard, body)
    guard => Unfurled(body, node.ndims, node.arr)
end

function unfurl_access(tns::Unfurled, ctx, protos...)
    unfurl_access(tns.body, ctx, protos...)
end

(ctx::CycleVisitor)(node::Unfurled) = Unfurled(ctx(node.body), node.ndims, node.arr)

function lower(node::Unfurled, ctx::AbstractCompiler, ::DefaultStyle)
    error(node)
    ctx(node.body)
end

getroot(tns::Unfurled) = getroot(tns.arr)