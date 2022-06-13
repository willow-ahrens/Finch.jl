struct ChunkStyle end

combine_style(a::DefaultStyle, b::ChunkStyle) = ChunkStyle()
combine_style(a::ThunkStyle, b::ChunkStyle) = ThunkStyle()
combine_style(a::ChunkStyle, b::ChunkStyle) = ChunkStyle()

struct ChunkifyVisitor <: AbstractTransformVisitor
    ctx
    idx
end

function (ctx::LowerJulia)(root::Loop, ::ChunkStyle)
    idx = root.idx
    ext = ctx.dims[getname(idx)]
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