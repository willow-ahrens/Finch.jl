struct OffsetArray{Delta<:Tuple, Body}
    body::Body
    delta::Delta
end

Base.show(io::IO, ex::OffsetArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::OffsetArray)
	print(io, "OffsetArray($(ex.body), $(ex.delta))")
end

Base.getindex(arr::OffsetArray, i...) = arr.body[(i .- arr.delta)...]

struct VirtualOffsetArray
    body
    delta
end

Base.show(io::IO, ex::VirtualOffsetArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualOffsetArray)
	print(io, "VirtualOffsetArray($(ex.body), $(ex.delta))")
end

Base.summary(io::IO, ex::VirtualOffsetArray) = print(io, "VOffset($(summary(ex.body)), $(summary(ex.dims)))")

FinchNotation.finch_leaf(x::VirtualOffsetArray) = virtual(x)

function virtualize(ex, ::Type{OffsetArray{Delta, Body}}, ctx) where {Delta, Body}
    delta = map(enumerate(Delta.parameters)) do (n, param)
        virtualize(:($ex.delta[$n]), param, ctx)
    end
    VirtualOffsetArray(virtualize(:($ex.body), Body, ctx), delta)
end

lower(tns::VirtualOffsetArray, ctx::AbstractCompiler, ::DefaultStyle) = :(OffsetArray($(ctx(tns.body)), $(ctx(tns.delta))))

function virtual_size(arr::VirtualOffsetArray, ctx::AbstractCompiler)
    map(zip(virtual_size(arr.body, ctx), arr.delta)) do (dim, delta)
        shiftdim(dim, delta)
    end
end
function virtual_resize!(arr::VirtualOffsetArray, ctx::AbstractCompiler, dims...)
    dims_2 = map(zip(dims, arr.delta)) do (dim, delta)
        shiftdim(dim, call(-, delta))
    end
    virtual_resize!(arr.body, ctx, dims_2...)
end

function instantiate_reader(arr::VirtualOffsetArray, ctx, protos...)
    VirtualOffsetArray(instantiate_reader(arr.body, ctx, protos...), arr.delta)
end
function instantiate_updater(arr::VirtualOffsetArray, ctx, protos...)
    VirtualOffsetArray(instantiate_updater(arr.body, ctx, protos...), arr.delta)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualOffsetArray) = ctx(node.body)
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::VirtualOffsetArray)
    stylize_access(node, ctx, tns.body)
end

function popdim(node::VirtualOffsetArray)
    if length(node.delta) == 1
        return node.body
    else
        return VirtualOffsetArray(node.body, node.delta[1:end-1])
    end
end

truncate(node::VirtualOffsetArray, ctx, ext, ext_2) = VirtualOffsetArray(truncate(node.body, ctx, shiftdim(ext, call(-, node.delta[end])), shiftdim(ext_2, call(-, node.delta[end]))), node.delta)

function get_point_body(node::VirtualOffsetArray, ctx, ext, idx)
    body_2 = get_point_body(node.body, ctx, shiftdim(ext, call(-, node.delta[end])), idx)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualOffsetArray(body_2, node.delta))
    end
end

(ctx::ThunkVisitor)(node::VirtualOffsetArray) = VirtualOffsetArray(ctx(node.body), node.delta)

function get_run_body(node::VirtualOffsetArray, ctx, ext)
    body_2 = get_run_body(node.body, ctx, shiftdim(ext, call(-, node.delta[end])))
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualOffsetArray(body_2, node.delta))
    end
end

function get_acceptrun_body(node::VirtualOffsetArray, ctx, ext)
    body_2 = get_acceptrun_body(node.body, ctx, shiftdim(ext, call(-, node.delta[end])))
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualOffsetArray(body_2, node.delta))
    end
end

function (ctx::PipelineVisitor)(node::VirtualOffsetArray)
    map(PipelineVisitor(; kwfields(ctx)..., ext = shiftdim(ctx.ext, call(-, node.delta[end])))(node.body)) do (keys, body)
        return keys => VirtualOffsetArray(body, node.delta)
    end
end

phase_body(node::VirtualOffsetArray, ctx, ext, ext_2) = VirtualOffsetArray(phase_body(node.body, ctx, shiftdim(ext, call(-, node.delta[end])), shiftdim(ext_2, call(-, node.delta[end]))), node.delta)
phase_range(node::VirtualOffsetArray, ctx, ext) = shiftdim(phase_range(node.body, ctx, shiftdim(ext, call(-, node.delta[end]))), node.delta[end])

get_spike_body(node::VirtualOffsetArray, ctx, ext, ext_2) = VirtualOffsetArray(get_spike_body(node.body, ctx, shiftdim(ext, call(-, node.delta[end])), shiftdim(ext_2, call(-, node.delta[end]))), node.delta)
get_spike_tail(node::VirtualOffsetArray, ctx, ext, ext_2) = popdim(VirtualOffsetArray(get_spike_tail(node.body, ctx, shiftdim(ext, call(-, node.delta[end])), shiftdim(ext_2, call(-, node.delta[end]))), node.delta))

visit_fill(node, tns::VirtualOffsetArray) = visit_fill(node, tns.body)
visit_simplify(node::VirtualOffsetArray) = VirtualOffsetArray(visit_simplify(node.body), node.delta)

(ctx::SwitchVisitor)(node::VirtualOffsetArray) = map(ctx(node.body)) do (guard, body)
    guard => VirtualOffsetArray(body, node.delta)
end

(ctx::CycleVisitor)(node::VirtualOffsetArray) = VirtualOffsetArray(CycleVisitor(; kwfields(ctx)..., ext=shiftdim(ctx.ext, call(-, node.delta[end])))(node.body), node.delta)

getroot(tns::VirtualOffsetArray) = getroot(tns.data)

function unfurl_access(node, ctx, ext, tns::VirtualOffsetArray)
    VirtualOffsetArray(unfurl_access(node, ctx, ext, tns.body), tns.delta)
end