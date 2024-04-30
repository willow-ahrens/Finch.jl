
virtual_size(tns::FinchNode, ctx) = virtual_size(resolve(tns, ctx), ctx)
virtual_resize!(tns::FinchNode, ctx, dims...) = virtual_resize!(resolve(tns, ctx), ctx, dims...)
virtual_default(tns::FinchNode, ctx) = virtual_default(resolve(tns, ctx), ctx)

function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::FinchNode)
    stylize_access(node, ctx, resolve(tns, ctx.ctx))
end

function instantiate(tns::FinchNode, ctx::AbstractCompiler, mode, protos)
    if tns.kind === virtual
        return instantiate(tns.val, ctx, mode, protos)
    elseif tns.kind === variable
        return Unfurled(tns, instantiate(resolve(tns, ctx), ctx, mode, protos))
    else
        return tns
    end
end

declare!(tns::FinchNode, ctx::AbstractCompiler, init) = declare!(resolve(tns, ctx), ctx, init)
thaw!(tns::FinchNode, ctx::AbstractCompiler) = thaw!(resolve(tns, ctx), ctx)
freeze!(tns::FinchNode, ctx::AbstractCompiler) = freeze!(resolve(tns, ctx), ctx)

function unfurl(tns::FinchNode, ctx, ext, mode, protos...)
    unfurl(resolve(tns, ctx), ctx, ext, mode, protos...)
end

lower_access(ctx::AbstractCompiler, node, tns::FinchNode) = 
    lower_access(ctx, node, resolve(tns, ctx))

is_injective(ctx, lvl::FinchNode) = is_injective(ctx, resolve(lvl), ctx)
is_atomic(ctx, lvl::FinchNode) = is_atomic(ctx, resolve(lvl), ctx)
is_concurrent(ctx, lvl::FinchNode) = is_concurrent(ctx, resolve(lvl), ctx)

function getroot(node::FinchNode)
    if node.kind === virtual
        return getroot(node.val)
    elseif node.kind === variable
        return node
    else
        error("could not get root of $(node)")
    end
end
