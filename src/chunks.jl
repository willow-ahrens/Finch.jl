struct ChunkStyle end

combine_style(a::DefaultStyle, b::ChunkStyle) = ChunkStyle()
combine_style(a::ThunkStyle, b::ChunkStyle) = ThunkStyle()
combine_style(a::ChunkStyle, b::ChunkStyle) = ChunkStyle()

struct ChunkifyContext <: AbstractTransformContext
    ctx
    idx
end

function visit!(root::Loop, ctx::LowerJuliaContext, ::ChunkStyle)
    root = visit!(root, ChunkifyContext(ctx, root.idxs[1]))
    #TODO add a simplify step here perhaps
    visit!(root, ctx)
end

struct AccessStyle end

combine_style(a::DefaultStyle, b::AccessStyle) = AccessStyle()
combine_style(a::ThunkStyle, b::AccessStyle) = ThunkStyle()
combine_style(a::ChunkStyle, b::AccessStyle) = AccessStyle()
combine_style(a::AccessStyle, b::AccessStyle) = AccessStyle()

struct AccessContext <: AbstractTransformContext
    ctx
end

function visit!(root::Loop, ctx::LowerJuliaContext, ::AccessStyle)
    root = visit!(root, AccessContext(ctx))
    #TODO add a simplify step here perhaps
    visit!(root, ctx)
end

function visit!(root::Pass, ctx::LowerJuliaContext, ::AccessStyle)
    quote end
end