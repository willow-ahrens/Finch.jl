
virtual_size(ctx, tns::FinchNode) = virtual_size(ctx, resolve(tns, ctx))
virtual_resize!(ctx, tns::FinchNode, dims...) = virtual_resize!(ctx, resolve(tns, ctx), dims...)
virtual_default(ctx, tns::FinchNode) = virtual_default(ctx, resolve(tns, ctx))

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

is_injective(lvl::FinchNode, ctx) = is_injective(resolve(lvl, ctx), ctx)
is_atomic(lvl::FinchNode, ctx) = is_atomic(resolve(lvl, ctx), ctx)

function getroot(node::FinchNode)
    if node.kind === virtual
        return getroot(node.val)
    elseif node.kind === variable
        return node
    else
        error("could not get root of $(node)")
    end
end
