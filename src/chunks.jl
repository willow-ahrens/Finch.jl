struct ChunkStyle end

combine_style(a::DefaultStyle, b::ChunkStyle) = ChunkStyle()
combine_style(a::ThunkStyle, b::ChunkStyle) = ThunkStyle()
combine_style(a::ChunkStyle, b::ChunkStyle) = ChunkStyle()

struct ChunkifyVisitor <: AbstractTransformVisitor
    ctx
    idx
end

function (ctx::LowerJulia)(root::Loop, ::ChunkStyle)
    body = Loop(root.idxs[2:end], root.body)
    idx = root.idxs[1]
    ext = ctx.dims[getname(root.idxs[1])]
    body = (ChunkifyVisitor(ctx, idx))(body)
    #TODO add a simplify step here perhaps
    ctx(Chunk(
        idx = idx,
        ext = ext,
        body = body
    ))
end