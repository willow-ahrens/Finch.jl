struct ChunkStyle end

combine_style(a::DefaultStyle, b::ChunkStyle) = ChunkStyle()
combine_style(a::ThunkStyle, b::ChunkStyle) = ThunkStyle()
combine_style(a::ChunkStyle, b::ChunkStyle) = ChunkStyle()

struct ChunkifyVisitor <: AbstractTransformVisitor
    ctx
    idx
end

function (ctx::LowerJulia)(root::Loop, ::ChunkStyle)
    root = (ChunkifyVisitor(ctx, root.idxs[1]))(root)
    #TODO add a simplify step here perhaps
    (ctx)(root)
end

struct AccessStyle end

combine_style(a::DefaultStyle, b::AccessStyle) = AccessStyle()
combine_style(a::ThunkStyle, b::AccessStyle) = ThunkStyle()
combine_style(a::ChunkStyle, b::AccessStyle) = AccessStyle()
combine_style(a::AccessStyle, b::AccessStyle) = AccessStyle()

struct AccessVisitor <: AbstractTransformVisitor
    ctx
end

function (ctx::LowerJulia)(root::Loop, ::AccessStyle)
    root = (AccessVisitor(ctx))(root)
    #TODO add a simplify step here perhaps
    (ctx)(root)
end

function (ctx::LowerJulia)(root::Pass, ::AccessStyle)
    quote end
end