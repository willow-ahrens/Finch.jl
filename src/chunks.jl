struct ChunkStyle end

combine_style(a::DefaultStyle, b::ChunkStyle) = ChunkStyle()
combine_style(a::ThunkStyle, b::ChunkStyle) = ThunkStyle()
combine_style(a::ChunkStyle, b::ChunkStyle) = ChunkStyle()
combine_style(a::ChunkStyle, b::DimensionalizeStyle) = DimensionalizeStyle()
combine_style(a::ChunkStyle, b::SimplifyStyle) = SimplifyStyle()

struct ChunkifyVisitor
    ctx
    idx
end

function (ctx::ChunkifyVisitor)(node)
    if istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
end

(ctx::ChunkifyVisitor)(node::Access) = chunkify_access(node, ctx, node.tns)

chunkify_access(node, ctx, tns::Virtual) = chunkify_access(node, ctx, tns.arg)
chunkify_access(node, ctx, tns) = similarterm(node, operation(node), map(ctx, arguments(node)))

function (ctx::LowerJulia)(root::Loop, ::ChunkStyle)
    idx = root.idx
    #TODO is every read of dims gonna be like this? When do we lock it in?
    ext = resolvedim(ctx.dims[getname(idx)])
    body = (ChunkifyVisitor(ctx, idx))(root.body)
    #TODO add a simplify step here perhaps
    ctx(Chunk(
        idx = idx,
        ext = ext,
        body = body
    ))
end

#TODO one day this might be nothing?
truncate(node, ctx, ext, ext_2) = node
truncate_weak(node, ctx, ext, ext_2) = truncate(node, ctx, ext, ext_2)
truncate_strong(node, ctx, ext, ext_2) = truncate(node, ctx, ext, ext_2)