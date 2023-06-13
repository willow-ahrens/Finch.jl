struct PermissiveArray{dims, Body}
    body::Body
end

PermissiveArray(body, dims) = PermissiveArray{dims}(body)
PermissiveArray{dims}(body::Body) where {dims, Body} = PermissiveArray{dims, Body}(body)

Base.show(io::IO, ex::PermissiveArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::PermissiveArray)
	print(io, "PermissiveArray($(ex.body), $(ex.dims))")
end

#Base.getindex(arr::PermissiveArray, i...) = ...

struct VirtualPermissiveArray
    body
    dims
end

Base.show(io::IO, ex::VirtualPermissiveArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualPermissiveArray)
	print(io, "VirtualPermissiveArray($(ex.body), $(ex.dims))")
end

Base.summary(io::IO, ex::VirtualPermissiveArray) = print(io, "VPermissive($(summary(ex.body)), $(summary(ex.protos)))")

FinchNotation.finch_leaf(x::VirtualPermissiveArray) = virtual(x)

function virtualize(ex, ::Type{PermissiveArray{dims, Body}}, ctx) where {dims, Body}
    VirtualPermissiveArray(virtualize(:($ex.body), Body, ctx), dims)
end

lower(tns::VirtualPermissiveArray, ctx::AbstractCompiler, ::DefaultStyle) = :(PermissiveArray($(ctx(tns.body)), $(tns.dims)))

function virtual_size(arr::VirtualPermissiveArray, ctx::AbstractCompiler)
    ifelse.(arr.dims, (nodim,), virtual_size(arr.body, ctx))
end
function virtual_resize!(arr::VirtualPermissiveArray, ctx::AbstractCompiler)
    virtual_resize!(arr.body, ctx, ifelse.(arr.dims, virtual_size(arr.body, ctx), dim))
end

function unfurl_reader(arr::VirtualPermissiveArray, ctx, protos...)
    VirtualPermissiveArray(unfurl_reader(arr.body, ctx, protos...), arr.dims)
end
function unfurl_updater(arr::VirtualPermissiveArray, ctx, protos...)
    VirtualPermissiveArray(unfurl_updater(arr.body, ctx, protos...), arr.dims)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualPermissiveArray) = ctx(node.body)
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::VirtualPermissiveArray)
    stylize_access(node, ctx, tns.body)
end

function popdim(node::VirtualPermissiveArray)
    if length(node.dims) == 1
        return node.body
    else
        return VirtualPermissiveArray(node.body, node.dims[1:end-1])
    end
end

truncate(node::VirtualPermissiveArray, ctx, ext, ext_2) = VirtualPermissiveArray(truncate(node.body, ctx, ext, ext_2), node.dims)

function get_point_body(node::VirtualPermissiveArray, ctx, ext, idx)
    body_2 = get_point_body(node.body, ctx, ext, idx)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualPermissiveArray(body_2, node.dims))
    end
end

(ctx::ThunkVisitor)(node::VirtualPermissiveArray) = VirtualPermissiveArray(ctx(node.body), node.dims)

function get_run_body(node::VirtualPermissiveArray, ctx, ext)
    body_2 = get_run_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualPermissiveArray(body_2, node.dims))
    end
end

function get_acceptrun_body(node::VirtualPermissiveArray, ctx, ext)
    body_2 = get_acceptrun_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualPermissiveArray(body_2, node.dims))
    end
end

function (ctx::PipelineVisitor)(node::VirtualPermissiveArray)
    map(ctx(node.body)) do (keys, body)
        return keys => VirtualPermissiveArray(body, node.dims)
    end
end

phase_body(node::VirtualPermissiveArray, ctx, ext, ext_2) = VirtualPermissiveArray(phase_body(node.body, ctx, ext, ext_2), node.dims)
phase_range(node::VirtualPermissiveArray, ctx, ext) = phase_range(node.body, ctx, ext)

get_spike_body(node::VirtualPermissiveArray, ctx, ext, ext_2) = VirtualPermissiveArray(get_spike_body(node.body, ctx, ext, ext_2), node.dims)
get_spike_tail(node::VirtualPermissiveArray, ctx, ext, ext_2) = VirtualPermissiveArray(get_spike_tail(node.body, ctx, ext, ext_2), node.dims)

visit_fill(node, tns::VirtualPermissiveArray) = visit_fill(node, tns.body)
visit_simplify(node::VirtualPermissiveArray) = VirtualPermissiveArray(visit_simplify(node.body), node.dims)

(ctx::SwitchVisitor)(node::VirtualPermissiveArray) = map(ctx(node.body)) do (guard, body)
    guard => VirtualPermissiveArray(body, node.dims)
end

function unfurl_access(tns::VirtualPermissiveArray, ctx, dims...)
    VirtualPermissiveArray(unfurl_access(tns.body, ctx, map(something, tns.dims, dims)...), tns.dims)
end

(ctx::CycleVisitor)(node::VirtualPermissiveArray) = VirtualPermissiveArray(ctx(node.body), node.dims)

getroot(tns::VirtualPermissiveArray) = getroot(tns.body)

function unfurl_access(tns::VirtualPermissiveArray, ctx, protos...)
    tns_2 = unfurl_access(node, ctx, eldim, tns.body)
    dims = virtual_size(tns.body, ctx.ctx)
    if tns.dims[end]
        Unfurled(
            Pipeline([
                Phase(
                    stop = (ctx, ext_2) -> call(-, getstart(dims[end]), 1),
                    body = (ctx, ext) -> Run(Fill(literal(missing))),
                ),
                Phase(
                    stop = (ctx, ext_2) -> getstop(dims[end]),
                    body = (ctx, ext_2) -> truncate(tns_2, ctx, dims[end], ext_2)
                ),
                Phase(
                    body = (ctx, ext_2) -> Run(Fill(literal(missing))),
                )
            ]),
            length(dims),
            tns.body
        )
    else
        tns
    end
end