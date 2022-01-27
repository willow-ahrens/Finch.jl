struct ChunkStyle end

combine_style(a::DefaultStyle, b::ChunkStyle) = ChunkStyle()
combine_style(a::ThunkStyle, b::ChunkStyle) = ThunkStyle()
combine_style(a::ChunkStyle, b::ChunkStyle) = ChunkStyle()

struct ChunkifyVisitor <: AbstractTransformVisitor
    ctx
    idx
end

function visit!(root::Loop, ctx::LowerJulia, ::ChunkStyle)
    root = visit!(root, ChunkifyVisitor(ctx, root.idxs[1]))
    #TODO add a simplify step here perhaps
    visit!(root, ctx)
end

struct AccessStyle end

combine_style(a::DefaultStyle, b::AccessStyle) = AccessStyle()
combine_style(a::ThunkStyle, b::AccessStyle) = ThunkStyle()
combine_style(a::ChunkStyle, b::AccessStyle) = AccessStyle()
combine_style(a::AccessStyle, b::AccessStyle) = AccessStyle()

struct AccessVisitor <: AbstractTransformVisitor
    ctx
end

function visit!(root::Loop, ctx::LowerJulia, ::AccessStyle)
    root = visit!(root, AccessVisitor(ctx))
    #TODO add a simplify step here perhaps
    visit!(root, ctx)
end

function visit!(root::Pass, ctx::LowerJulia, ::AccessStyle)
    quote end
end