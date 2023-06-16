@kwdef struct Unfurled
    arr
    ndims
    body
    Unfurled(arr, ndims, body) = begin
        @assert !(body isa Unfurled)
        new(arr, ndims, body) 
    end
    Unfurled(arr, ndims, body::Nothing) = error()
end

Base.show(io::IO, ex::Unfurled) = Base.show(io, MIME"text/plain"(), ex)

function Base.show(io::IO, mime::MIME"text/plain", ex::Unfurled)
    print(io, "Unfurled(")
    print(io, ex.arr)
    print(io, ", ")
    print(io, ex.ndims)
    print(io, ", ")
    print(io, ex.body)
    print(io, ")")
end

Base.summary(io::IO, ex::Unfurled) = print(io, "Unfurled($(summary(ex.arr)), $(summary(ex.body)))")

FinchNotation.finch_leaf(x::Unfurled) = virtual(x)

virtual_size(tns::Unfurled, ctx) = virtual_size(tns.arr, ctx)
virtual_resize!(tns::Unfurled, ctx, dims...) = virtual_resize!(tns.arr, ctx, dims...)
virtual_default(tns::Unfurled, ctx) = virtual_default(tns.arr, ctx)

expand_reader(tns::Unfurled, ctx::LowerJulia, protos...) = tns
expand_updater(tns::Unfurled, ctx::LowerJulia, protos...) = tns

(ctx::Stylize{<:AbstractCompiler})(node::Unfurled) = ctx(node.body)
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::Unfurled)
    stylize_access(node, ctx, tns.body)
end

function popdim(node::Unfurled)
    if node.ndims == 1
        return node.body
    else
        return Unfurled(node.arr, node.ndims - 1, node.body)
    end
end

truncate(node::Unfurled, ctx, ext, ext_2) = Unfurled(node.arr, node.ndims, truncate(node.body, ctx, ext, ext_2))

function get_point_body(node::Unfurled, ctx, ext, idx)
    body_2 = get_point_body(node.body, ctx, ext, idx)
    if body_2 === nothing
        return nothing
    else
        return popdim(Unfurled(node.arr, node.ndims, body_2))
    end
end

(ctx::ThunkVisitor)(node::Unfurled) = Unfurled(node.arr, node.ndims, ctx(node.body))

function get_run_body(node::Unfurled, ctx, ext)
    body_2 = get_run_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(Unfurled(node.arr, node.ndims, body_2))
    end
end

function get_acceptrun_body(node::Unfurled, ctx, ext)
    body_2 = get_acceptrun_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(Unfurled(node.arr, node.ndims, body_2))
    end
end

function (ctx::PipelineVisitor)(node::Unfurled)
    map(ctx(node.body)) do (keys, body)
        return keys => Unfurled(node.arr, node.ndims, body)
    end
end

phase_body(node::Unfurled, ctx, ext, ext_2) = Unfurled(node.arr, node.ndims, phase_body(node.body, ctx, ext, ext_2))

phase_range(node::Unfurled, ctx, ext) = phase_range(node.body, ctx, ext)

get_spike_body(node::Unfurled, ctx, ext, ext_2) = Unfurled(node.arr, node.ndims, get_spike_body(node.body, ctx, ext, ext_2))

get_spike_tail(node::Unfurled, ctx, ext, ext_2) = Unfurled(node.arr, node.ndims, get_spike_tail(node.body, ctx, ext, ext_2))

visit_fill(node, tns::Unfurled) = visit_fill(node, tns.body)

visit_simplify(node::Unfurled) = Unfurled(node.arr, node.ndims, visit_simplify(node.body))

(ctx::SwitchVisitor)(node::Unfurled) = map(ctx(node.body)) do (guard, body)
    guard => Unfurled(node.arr, node.ndims, body)
end

function unfurl_access(tns::Unfurled, ctx, ext, protos...)
    unfurl_access(tns.body, ctx, ext, protos...)
end

(ctx::CycleVisitor)(node::Unfurled) = Unfurled(node.arr, node.ndims, ctx(node.body))

function lower(node::Unfurled, ctx::AbstractCompiler, ::DefaultStyle)
    error(node)
    ctx(node.body)
end

getroot(tns::Unfurled) = getroot(tns.arr)