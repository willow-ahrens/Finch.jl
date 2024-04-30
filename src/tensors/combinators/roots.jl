
virtual_size(ctx, tns::FinchNode) = virtual_size(ctx, resolve(ctx, tns))
virtual_resize!(ctx, tns::FinchNode, dims...) = virtual_resize!(ctx, resolve(ctx, tns), dims...)
virtual_default(ctx, tns::FinchNode) = virtual_default(ctx, resolve(ctx, tns))

function stylize_access(ctx::Stylize{<:AbstractCompiler}, node, tns::FinchNode)
    stylize_access(ctx, node, resolve(ctx.ctx, tns))
end

function instantiate(ctx::AbstractCompiler, tns::FinchNode, mode, protos)
    if tns.kind === virtual
        return instantiate(ctx, tns.val, mode, protos)
    elseif tns.kind === variable
        return Unfurled(tns, instantiate(ctx, resolve(ctx, tns), mode, protos))
    else
        return tns
    end
end

declare!(ctx::AbstractCompiler, tns::FinchNode, init) = declare!(ctx, resolve(ctx, tns), init)
thaw!(ctx::AbstractCompiler, tns::FinchNode) = thaw!(ctx, resolve(ctx, tns))
freeze!(ctx::AbstractCompiler, tns::FinchNode) = freeze!(ctx, resolve(ctx, tns))

function unfurl(ctx, tns::FinchNode, ext, mode, protos...)
    unfurl(ctx, resolve(ctx, tns), ext, mode, protos...)
end

lower_access(ctx::AbstractCompiler, node, tns::FinchNode) = 
    lower_access(ctx, node, resolve(ctx, tns))

is_injective(ctx, lvl::FinchNode) = is_injective(ctx, resolve(ctx, lvl), ctx)
is_atomic(ctx, lvl::FinchNode) = is_atomic(ctx, resolve(ctx, lvl), ctx)
is_concurrent(ctx, lvl::FinchNode) = is_concurrent(ctx, resolve(ctx, lvl), ctx)

function getroot(node::FinchNode)
    if node.kind === virtual
        return getroot(node.val)
    elseif node.kind === variable
        return node
    else
        error("could not get root of $(node)")
    end
end
