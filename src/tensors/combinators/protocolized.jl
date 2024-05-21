struct ProtocolizedArray{Protos<:Tuple, Body} <: AbstractCombinator
    body::Body
    protos::Protos
end

Base.show(io::IO, ex::ProtocolizedArray) =
	print(io, "ProtocolizedArray($(ex.body), $(ex.protos))")

labelled_show(io::IO, ex::ProtocolizedArray) =
    print(io, "ProtocolizedArray [$(join(map(p -> isnothing(p) ? ":" : "$p(:)", ex.protos), ", "))]")

function labelled_children(ex::ProtocolizedArray)
    [LabelledTree(ex.body)]
end

struct VirtualProtocolizedArray <: AbstractVirtualCombinator
    body
    protos
end

is_injective(ctx, lvl::VirtualProtocolizedArray) = is_injective(ctx, lvl.body)
is_atomic(ctx, lvl::VirtualProtocolizedArray) = is_atomic(ctx, lvl.body)
is_concurrent(ctx, lvl::VirtualProtocolizedArray) = is_concurrent(ctx, lvl.body)


Base.:(==)(a::VirtualProtocolizedArray, b::VirtualProtocolizedArray) = a.body == b.body && a.protos == b.protos

Base.show(io::IO, ex::VirtualProtocolizedArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualProtocolizedArray)
	print(io, "VirtualProtocolizedArray($(ex.body), $(ex.protos))")
end

Base.summary(io::IO, ex::VirtualProtocolizedArray) = print(io, "VProtocolized($(summary(ex.body)), $(summary(ex.protos)))")

FinchNotation.finch_leaf(x::VirtualProtocolizedArray) = virtual(x)

function virtualize(ctx, ex, ::Type{ProtocolizedArray{Protos, Body}}) where {Protos, Body}
    protos = map(enumerate(Protos.parameters)) do (n, param)
        virtualize(ctx, :($ex.protos[$n]), param)
    end
    VirtualProtocolizedArray(virtualize(ctx, :($ex.body), Body), protos)
end

"""
    protocolize(tns, protos...)

Create a `ProtocolizedArray` that accesses dimension `n` with protocol
`protos[n]`, if `protos[n]` is not nothing. See the documention for [Iteration
Protocols](@ref) for more information. For example, to gallop along the inner
dimension of a matrix `A`, we write `A[gallop(i), j]`, which becomes
`protocolize(A, gallop, nothing)[i, j]`.
"""
protocolize(body, protos...) = ProtocolizedArray(body, protos)
function virtual_call(ctx, ::typeof(protocolize), body, protos...)
    @assert All(isliteral)(protos)
    VirtualProtocolizedArray(body, map(proto -> proto.val, protos))
end
unwrap(ctx, arr::VirtualProtocolizedArray, var) = call(protocolize, unwrap(ctx, arr.body, var), arr.protos...)

function lower(ctx::AbstractCompiler, tns::VirtualProtocolizedArray, ::DefaultStyle)
    error()
    :(ProtocolizedArray($(ctx(tns.body)), $(ctx(tns.protos))))
end

function virtual_size(ctx::AbstractCompiler, arr::VirtualProtocolizedArray)
    virtual_size(ctx, arr.body)
end
function virtual_resize!(ctx::AbstractCompiler, arr::VirtualProtocolizedArray, dim)
    virtual_resize!(ctx, arr.body, dim)
end

function instantiate(ctx, arr::VirtualProtocolizedArray, mode, protos)
    VirtualProtocolizedArray(instantiate(ctx, arr.body, mode, map(something, arr.protos, protos)), arr.protos)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualProtocolizedArray) = ctx(node.body)
function stylize_access(ctx::Stylize{<:AbstractCompiler}, node, tns::VirtualProtocolizedArray)
    stylize_access(ctx, node, tns.body)
end

function popdim(node::VirtualProtocolizedArray)
    if length(node.protos) == 1
        return node.body
    else
        return VirtualProtocolizedArray(node.body, node.protos[1:end-1])
    end
end

truncate(ctx, node::VirtualProtocolizedArray, ext, ext_2) = VirtualProtocolizedArray(truncate(ctx, node.body, ext, ext_2), node.protos)

function get_point_body(ctx, node::VirtualProtocolizedArray, ext, idx)
    body_2 = get_point_body(ctx, node.body, ext, idx)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualProtocolizedArray(body_2, node.protos))
    end
end

(ctx::ThunkVisitor)(node::VirtualProtocolizedArray) = VirtualProtocolizedArray(ctx(node.body), node.protos)

function get_run_body(ctx, node::VirtualProtocolizedArray, ext)
    body_2 = get_run_body(ctx, node.body, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualProtocolizedArray(body_2, node.protos))
    end
end

function get_acceptrun_body(ctx, node::VirtualProtocolizedArray, ext)
    body_2 = get_acceptrun_body(ctx, node.body, ext)
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

phase_body(ctx, node::VirtualProtocolizedArray, ext, ext_2) = VirtualProtocolizedArray(phase_body(ctx, node.body, ext, ext_2), node.protos)
phase_range(ctx, node::VirtualProtocolizedArray, ext) = phase_range(ctx, node.body, ext)

get_spike_body(ctx, node::VirtualProtocolizedArray, ext, ext_2) = VirtualProtocolizedArray(get_spike_body(ctx, node.body, ext, ext_2), node.protos)
get_spike_tail(ctx, node::VirtualProtocolizedArray, ext, ext_2) = VirtualProtocolizedArray(get_spike_tail(ctx, node.body, ext, ext_2), node.protos)

visit_fill_leaf_leaf(node, tns::VirtualProtocolizedArray) = visit_fill_leaf_leaf(node, tns.body)
visit_simplify(node::VirtualProtocolizedArray) = VirtualProtocolizedArray(visit_simplify(node.body), node.protos)

(ctx::SwitchVisitor)(node::VirtualProtocolizedArray) = map(ctx(node.body)) do (guard, body)
    guard => VirtualProtocolizedArray(body, node.protos)
end

function unfurl(ctx, tns::VirtualProtocolizedArray, ext, mode, protos...)
    VirtualProtocolizedArray(unfurl(ctx, tns.body, ext, mode, map(something, tns.protos, protos)...), tns.protos)
end


stepper_range(ctx, node::VirtualProtocolizedArray, ext) = stepper_range(ctx, node.body, ext)
stepper_body(ctx, node::VirtualProtocolizedArray, ext, ext_2) = VirtualProtocolizedArray(stepper_body(ctx, node.body, ext, ext_2), node.protos)
stepper_seek(ctx, node::VirtualProtocolizedArray, ext) = stepper_seek(ctx, node.body, ext)

jumper_range(ctx, node::VirtualProtocolizedArray, ext) = jumper_range(ctx, node.body, ext)
jumper_body(ctx, node::VirtualProtocolizedArray, ext, ext_2) = VirtualProtocolizedArray(jumper_body(ctx, node.body, ext, ext_2), node.protos)
jumper_seek(ctx, node::VirtualProtocolizedArray, ext) = jumper_seek(ctx, node.body, ext)

function short_circuit_cases(ctx, node::VirtualProtocolizedArray, op)
    map(short_circuit_cases(ctx, node.body, op)) do (guard, body)
        guard => VirtualProtocolizedArray(body, node.protos)
    end
end


getroot(tns::VirtualProtocolizedArray) = getroot(tns.body)
