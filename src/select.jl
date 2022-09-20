struct Select end

const select = Select()

Base.show(io::IO, ex::Select) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Select)
    print(io, "select")
end

getsize(::Select, ::LowerJulia, mode) = (NoDimension(), NoDimension())
getsites(::Select) = 1:2
getname(x) = gensym() #TODO this is wrong
setname(::Select, name) = select

virtualize(ex, ::Type{Select}, ctx) = select

(ctx::LowerJulia)(tns::Select) = error("Select not lowered")

function stylize_access(node, ctx::Stylize{LowerJulia}, tns::Select)
    if ctx.root isa Loop && ctx.root.idx == get_furl_root(node.idxs[2])
        Finch.ChunkStyle()
    else
        Finch.DefaultStyle()
    end
end

function (ctx::Finch.ChunkifyVisitor)(node::Access{Select}) where {Tv, Ti}
    vec = node.tns
    if getname(ctx.idx) == getname(node.idxs[2])
        sym = ctx.ctx.freshen(:select_, getname(node.idxs[2]))
        push!(ctx.ctx.preamble, quote
            $sym = $(ctx.ctx(node.idxs[1]))
        end)
        tns = Pipeline([
            Phase(
                stride = (ctx, idx, ext) -> :($sym - 1),
                body = (start, step) -> Run(body=Simplify(false))
            ),
            Phase(
                stride = (ctx, idx, ext) -> sym,
                body = (start, step) -> Run(body=Simplify(true)),
            ),
            Phase(body = (start, step) -> Run(body=Simplify(false)))
        ])
        access(tns, node.mode, node.idxs[2])
    else
        node
    end
end

struct SelectVisitor
    ctx
    idxs
end

function (ctx::SelectVisitor)(node)
    if istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
end

struct SelectStyle end

combine_style(a::SelectStyle, b::ThunkStyle) = b
combine_style(a::SelectStyle, b::ChunkStyle) = a

function (ctx::LowerJulia)(root, ::SelectStyle)
    idxs = Dict()
    root = SelectVisitor(ctx, idxs)(root)
    for (idx, val) in pairs(idxs)
        root = @f(
            @loop $idx (
                @sieve select[$val, $idx] (
                    $root
                )
            )
        )
    end
    ctx(root)
end