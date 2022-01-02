Base.@kwdef struct ChunkVector
    body
    ext
    name = gensym()
end

Pigeon.lower_axes(arr::ChunkVector, ctx::Finch.LowerJuliaContext) = (arr.ext,)
Pigeon.getsites(arr::ChunkVector) = (1,)
Pigeon.getname(arr::ChunkVector) = arr.name
Pigeon.make_style(root, ctx::Finch.LowerJuliaContext, node::Access{ChunkVector}) = Finch.ChunkStyle()
function Pigeon.visit!(node::Access{ChunkVector}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle)
    return Access(node.tns.body, node.mode, node.idxs)
end