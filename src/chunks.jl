struct ChunkStyle end

Pigeon.combine_style(a::DefaultStyle, b::ChunkStyle) = ChunkStyle()
Pigeon.combine_style(a::ThunkStyle, b::ChunkStyle) = ThunkStyle()
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

struct AccessStyle end

Pigeon.combine_style(a::DefaultStyle, b::AccessStyle) = AccessStyle()
Pigeon.combine_style(a::ThunkStyle, b::AccessStyle) = ThunkStyle()
Pigeon.combine_style(a::ChunkStyle, b::AccessStyle) = AccessStyle()
Pigeon.combine_style(a::AccessStyle, b::AccessStyle) = AccessStyle()

struct AccessContext <: Pigeon.AbstractTransformContext
    ctx
end

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::AccessStyle)
    root = visit!(root, AccessContext(ctx))
    #TODO add a simplify step here perhaps
    visit!(root, ctx)
end

function Pigeon.visit!(root::Pass, ctx::LowerJuliaContext, ::AccessStyle)
    quote end
end