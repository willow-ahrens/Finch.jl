
virtual_size(ctx, tns::FinchNode) = virtual_size(ctx, resolve(tns, ctx))
virtual_resize!(ctx, tns::FinchNode, dims...) = virtual_resize!(ctx, resolve(tns, ctx), dims...)
virtual_default(ctx, tns::FinchNode) = virtual_default(ctx, resolve(tns, ctx))

function stylize_access(ctx::Stylize{<:AbstractCompiler}, node, tns::FinchNode)
    stylize_access(ctx, node, resolve(tns, ctx.ctx))
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

declare!(ctx::AbstractCompiler, tns::FinchNode, init) = declare!(ctx, resolve(tns, ctx), init)
thaw!(ctx::AbstractCompiler, tns::FinchNode) = thaw!(ctx, resolve(tns, ctx))
freeze!(ctx::AbstractCompiler, tns::FinchNode) = freeze!(ctx, resolve(tns, ctx))

function unfurl(ctx, tns::FinchNode, ext, mode, protos...)
    unfurl(ctx, resolve(tns, ctx), ext, mode, protos...)
end

lower_access(ctx::AbstractCompiler, node, tns::FinchNode) = 
    lower_access(ctx, node, resolve(tns, ctx))

is_injective(ctx, lvl::FinchNode) = is_injective(ctx, resolve(lvl, ctx))
is_atomic(ctx, lvl::FinchNode) = is_atomic(ctx, resolve(lvl, ctx))

function getroot(node::FinchNode)
    if node.kind === virtual
        return getroot(node.val)
    elseif node.kind === variable
        return node
    else
        error("could not get root of $(node)")
    end
end
