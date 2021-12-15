struct ChunkStyle end

Pigeon.combine_style(a::DefaultStyle, b::ChunkStyle) = ChunkStyle()
Pigeon.combine_style(a::ChunkStyle, b::ChunkStyle) = ChunkStyle()

struct ChunkifyContext <: Pigeon.AbstractTransformContext
    ctx
    idx
end

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::ChunkStyle)
    root = visit!(root, ChunkifyContext(ctx, root.idxs[1]))
    #TODO add a simplify step here perhaps
    visit!(root, ctx)
end

trim_chunk_stop!(node, ctx, stop) = nothing