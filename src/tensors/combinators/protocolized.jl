struct ProtocolizedArray{Protos<:Tuple, Body} <: AbstractCombinator
    body::Body
    protos::Protos
end

Base.show(io::IO, ex::ProtocolizedArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::ProtocolizedArray)
	print(io, "ProtocolizedArray($(ex.body), $(ex.protos))")
end

Base.getindex(arr::ProtocolizedArray, i...) = arr.body[i...]

struct VirtualProtocolizedArray <: AbstractVirtualCombinator
    body
    protos
end


is_injective(lvl::VirtualProtocolizedArray, ctx, accs) = is_injective(lvl.body, ctx, accs)

Base.:(==)(a::VirtualProtocolizedArray, b::VirtualProtocolizedArray) = a.body == b.body && a.protos == b.protos

Base.show(io::IO, ex::VirtualProtocolizedArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualProtocolizedArray)
	print(io, "VirtualProtocolizedArray($(ex.body), $(ex.protos))")
end

Base.summary(io::IO, ex::VirtualProtocolizedArray) = print(io, "VProtocolized($(summary(ex.body)), $(summary(ex.protos)))")

FinchNotation.finch_leaf(x::VirtualProtocolizedArray) = virtual(x)

function virtualize(ex, ::Type{ProtocolizedArray{Protos, Body}}, ctx) where {Protos, Body}
    protos = map(enumerate(Protos.parameters)) do (n, param)
        virtualize(:($ex.protos[$n]), param, ctx)
    end
    VirtualProtocolizedArray(virtualize(:($ex.body), Body, ctx), protos)
end

protocolize(body, protos...) = ProtocolizedArray(body, protos)
function virtual_call(::typeof(protocolize), ctx, body, protos...)
    @assert All(isliteral)(protos)
    VirtualProtocolizedArray(body, map(proto -> proto.val, protos))
end

function lower(tns::VirtualProtocolizedArray, ctx::AbstractCompiler, ::DefaultStyle)
    error()
    :(ProtocolizedArray($(ctx(tns.body)), $(ctx(tns.protos))))
end

function virtual_size(arr::VirtualProtocolizedArray, ctx::AbstractCompiler)
    virtual_size(arr.body, ctx)
end
function virtual_resize!(arr::VirtualProtocolizedArray, ctx::AbstractCompiler, dim)
    virtual_resize!(arr.body, ctx, dim)
end

function instantiate_reader(arr::VirtualProtocolizedArray, ctx, protos)
    VirtualProtocolizedArray(instantiate_reader(arr.body, ctx,  map(something, arr.protos, protos)), arr.protos)
end
function instantiate_updater(arr::VirtualProtocolizedArray, ctx, protos)
    VirtualProtocolizedArray(instantiate_updater(arr.body, ctx,  map(something, arr.protos, protos)), arr.protos)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualProtocolizedArray) = ctx(node.body)
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::VirtualProtocolizedArray)
    stylize_access(node, ctx, tns.body)
end

function popdim(node::VirtualProtocolizedArray)
    if length(node.protos) == 1
        return node.body
    else
        return VirtualProtocolizedArray(node.body, node.protos[1:end-1])
    end
end

truncate(node::VirtualProtocolizedArray, ctx, ext, ext_2) = VirtualProtocolizedArray(truncate(node.body, ctx, ext, ext_2), node.protos)

function get_point_body(node::VirtualProtocolizedArray, ctx, ext, idx)
    body_2 = get_point_body(node.body, ctx, ext, idx)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualProtocolizedArray(body_2, node.protos))
    end
end

(ctx::ThunkVisitor)(node::VirtualProtocolizedArray) = VirtualProtocolizedArray(ctx(node.body), node.protos)

function get_run_body(node::VirtualProtocolizedArray, ctx, ext)
    body_2 = get_run_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualProtocolizedArray(body_2, node.protos))
    end
end

function get_acceptrun_body(node::VirtualProtocolizedArray, ctx, ext)
    body_2 = get_acceptrun_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualProtocolizedArray(body_2, node.protos))
    end
end

function (ctx::SequenceVisitor)(node::VirtualProtocolizedArray)
    map(ctx(node.body)) do (keys, body)
        return keys => VirtualProtocolizedArray(body, node.protos)
    end
end

phase_body(node::VirtualProtocolizedArray, ctx, ext, ext_2) = VirtualProtocolizedArray(phase_body(node.body, ctx, ext, ext_2), node.protos)
phase_range(node::VirtualProtocolizedArray, ctx, ext) = phase_range(node.body, ctx, ext)

get_spike_body(node::VirtualProtocolizedArray, ctx, ext, ext_2) = VirtualProtocolizedArray(get_spike_body(node.body, ctx, ext, ext_2), node.protos)
get_spike_tail(node::VirtualProtocolizedArray, ctx, ext, ext_2) = VirtualProtocolizedArray(get_spike_tail(node.body, ctx, ext, ext_2), node.protos)

visit_fill(node, tns::VirtualProtocolizedArray) = visit_fill(node, tns.body)
visit_simplify(node::VirtualProtocolizedArray) = VirtualProtocolizedArray(visit_simplify(node.body), node.protos)

(ctx::SwitchVisitor)(node::VirtualProtocolizedArray) = map(ctx(node.body)) do (guard, body)
    guard => VirtualProtocolizedArray(body, node.protos)
end

function unfurl(tns::VirtualProtocolizedArray, ctx, ext, protos...)
    VirtualProtocolizedArray(unfurl(tns.body, ctx, ext, map(something, tns.protos, protos)...), tns.protos)
end

jumper_body(node::VirtualProtocolizedArray, ctx, ext) = VirtualProtocolizedArray(jumper_body(node.body, ctx, ext), node.protos)
stepper_body(node::VirtualProtocolizedArray, ctx, ext) = VirtualProtocolizedArray(stepper_body(node.body, ctx, ext), node.protos)
stepper_seek(node::VirtualProtocolizedArray, ctx, ext) = stepper_seek(node.body, ctx, ext)

getroot(tns::VirtualProtocolizedArray) = getroot(tns.body)
