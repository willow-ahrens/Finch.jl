struct Select end

const select = Select()

getdims(::Select, ::LowerJulia, mode) = (NoDimension(), NoDimension())
getsites(::Select) = 1:2
getname(x) = gensym() #TODO this is wrong
setname(::Select, name) = select

virtualize(ex, ::Type{Select}, ctx) = select

(ctx::LowerJulia)(tns::Select) = error("Select not lowered")

Finch.make_style(root::Loop, ctx::Finch.LowerJulia, node::Access{Select}) =
    getname(root.idx) == getname(node.idxs[2]) ? Finch.ChunkStyle() : Finch.DefaultStyle()

function (ctx::Finch.ChunkifyVisitor)(node::Access{Select}, ::Finch.DefaultStyle) where {Tv, Ti}
    vec = node.tns
    if getname(ctx.idx) == getname(node.idxs[2])
        sym = ctx.ctx.freshen(getname(node.idxs[2]))
        push!(ctx.ctx.preamble, quote
            $sym = $(ctx.ctx(node.idxs[1]))
        end)
        tns = Pipeline([
            Phase(
                stride = (start) -> :($sym - 1),
                body = (start, step) -> Run(body=false)
            ),
            Phase(
                stride = (start) -> sym,
                body = (start, step) -> Run(body=true),
            ),
            Phase(body = (start, step) -> Run(body=false))
        ])
        access(tns, node.mode, node.idxs[2])
    else
        node
    end
end

struct SelectVisitor <: AbstractTransformVisitor
    ctx
    idxs
end

struct SelectStyle end

combine_style(a::SelectStyle, b::ThunkStyle) = b
combine_style(a::SelectStyle, b::ChunkStyle) = a

function (ctx::LowerJulia)(root, ::SelectStyle)
    idxs = Dict()
    root = SelectVisitor(ctx, idxs)(root)
    for (idx, val) in pairs(idxs)
        root = @i(
            @loop $idx (
                if select[$val, $idx]
                    $root
                end
            )
        )
    end
    ctx(root)
end