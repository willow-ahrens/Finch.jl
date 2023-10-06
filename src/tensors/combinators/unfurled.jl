@kwdef struct Unfurled <: AbstractVirtualCombinator
    arr
    ndims = 0
    body
    Unfurled(arr, ndims, body) = begin
        new(arr, ndims, body) 
    end
    Unfurled(arr, body) = Unfurled(arr, 0, body)
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

instantiate(tns::Unfurled, ctx, mode, protos) = tns

(ctx::Stylize{<:AbstractCompiler})(node::Unfurled) = ctx(node.body)
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::Unfurled)
    stylize_access(node, ctx, tns.body)
end

function popdim(node::Unfurled, ctx)
    if node.ndims + 1 == length(virtual_size(node.arr, ctx)) || node.body isa Unfurled
        return node.body
    else
        return Unfurled(node.arr, node.ndims + 1, node.body)
    end
end

truncate(node::Unfurled, ctx, ext, ext_2) = Unfurled(node.arr, node.ndims, truncate(node.body, ctx, ext, ext_2))

function get_point_body(node::Unfurled, ctx, ext, idx)
    body_2 = get_point_body(node.body, ctx, ext, idx)
    if body_2 === nothing
        return nothing
    else
        return popdim(Unfurled(node.arr, node.ndims, body_2), ctx)
    end
end

(ctx::ThunkVisitor)(node::Unfurled) = Unfurled(node.arr, node.ndims, ctx(node.body))

function get_run_body(node::Unfurled, ctx, ext)
    body_2 = get_run_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(Unfurled(node.arr, node.ndims, body_2), ctx)
    end
end

function get_acceptrun_body(node::Unfurled, ctx, ext)
    body_2 = get_acceptrun_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(Unfurled(node.arr, node.ndims, body_2), ctx)
    end
end

function (ctx::SequenceVisitor)(node::Unfurled)
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

function unfurl(tns::Unfurled, ctx, ext, mode, protos...)
    unfurl(tns.body, ctx, ext, mode, protos...)
end

stepper_range(node::Unfurled, ctx, ext) = stepper_range(node.body, ctx, ext)
stepper_body(node::Unfurled, ctx, ext, ext_2) = Unfurled(node.arr, node.ndims, stepper_body(node.body, ctx, ext, ext_2))
stepper_seek(node::Unfurled, ctx, ext) = stepper_seek(node.body, ctx, ext)

jumper_range(node::Unfurled, ctx, ext) = jumper_range(node.body, ctx, ext)
jumper_body(node::Unfurled, ctx, ext, ext_2) = Unfurled(node.arr, node.ndims, jumper_body(node.body, ctx, ext, ext_2))
jumper_seek(node::Unfurled, ctx, ext) = jumper_seek(node.body, ctx, ext)

function lower(node::Unfurled, ctx::AbstractCompiler, ::DefaultStyle)
    ctx(node.body)
end

getroot(tns::Unfurled) = getroot(tns.arr)

is_injective(lvl::Unfurled, ctx) = is_injective(lvl.arr, ctx)
is_atomic(lvl::Unfurled, ctx) = is_atomic(lvl.arr, ctx)

function lower_access(ctx::AbstractCompiler, node, tns::Unfurled)
    if !isempty(node.idxs)
        error("I'm not sure how this has happened")
    end
    lower_access(ctx, node, tns.body)
end
