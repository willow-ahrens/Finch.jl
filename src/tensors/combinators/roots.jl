
virtual_size(tns::FinchNode, ctx) = virtual_size(resolve(tns, ctx), ctx)
virtual_resize!(tns::FinchNode, ctx, dims...) = virtual_resize!(resolve(tns, ctx), ctx, dims...)
virtual_default(tns::FinchNode, ctx) = virtual_default(resolve(tns, ctx), ctx)

function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::FinchNode)
    stylize_access(node, ctx, resolve(tns, ctx.ctx))
end

instantiate_reader(tns::FinchNode, ctx::AbstractCompiler, protos) = instantiate_reader(resolve(tns, ctx), ctx, protos)
instantiate_updater(tns::FinchNode, ctx::AbstractCompiler, protos) = instantiate_updater(resolve(tns, ctx), ctx, protos)

declare!(tns::FinchNode, ctx::AbstractCompiler, init) = declare!(resolve(tns, ctx), ctx, init)
thaw!(tns::FinchNode, ctx::AbstractCompiler) = thaw!(resolve(tns, ctx), ctx)
freeze!(tns::FinchNode, ctx::AbstractCompiler) = freeze!(resolve(tns, ctx), ctx)
trim!(tns::FinchNode, ctx::AbstractCompiler) = trim!(resolve(tns, ctx), ctx)

function unfurl(tns::FinchNode, ctx, ext, mode, protos...)
    unfurl(resolve(tns, ctx), ctx, ext, mode, protos...)
end

lower_access(ctx::AbstractCompiler, node, tns::FinchNode) = 
    lower_access(ctx, node, resolve(tns, ctx))

is_injective(lvl::FinchNode, ctx) = is_injective(resolve(lvl.body, ctx), ctx)
is_concurrent(lvl::FinchNode, ctx) = is_concurrent(resolve(lvl.body, ctx), ctx)
is_atomic(lvl::FinchNode, ctx) = is_atomic(resolve(lvl.body, ctx), ctx)

function getroot(node::FinchNode)
    if node.kind === virtual
        return getroot(node.val)
    elseif node.kind === variable
        return node
    else
        error("could not get root of $(node)")
    end
end