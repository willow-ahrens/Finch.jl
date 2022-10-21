struct Select end

const select = Select()

IndexNotation.isliteral(::Select) =  false

Base.show(io::IO, ex::Select) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Select)
    print(io, "select")
end

getsize(::Select, ::LowerJulia, mode) = (NoDimension(), NoDimension())
getsites(::Select) = 1:2
getname(x::Select) = gensym()
setname(::Select, name) = select

virtualize(ex, ::Type{Select}, ctx) = select

(ctx::LowerJulia)(tns::Select) = error("Select not lowered")

function stylize_access(node, ctx::Stylize{LowerJulia}, tns::Select)
    if ctx.root isa CINNode && ctx.root.kind === loop && ctx.root.idx == get_furl_root(node.idxs[2])
        Finch.ChunkStyle()
    else
        Finch.DefaultStyle()
    end
end

function chunkify_access(node, ctx, ::Select)
    if getname(ctx.idx) == getname(node.idxs[2])
        sym = ctx.ctx.freshen(:select_, getname(node.idxs[2]))
        push!(ctx.ctx.preamble, quote
            $sym = $(ctx.ctx(node.idxs[1]))
        end)
        tns = Pipeline([
            Phase(
                stride = (ctx, idx, ext) -> value(:($sym - 1)),
                body = (start, step) -> Run(body=Simplify(literal(false)))
            ),
            Phase(
                stride = (ctx, idx, ext) -> value(sym),
                body = (start, step) -> Run(body=Simplify(literal(true))),
            ),
            Phase(body = (start, step) -> Run(body=Simplify(literal(false))))
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

function (ctx::SelectVisitor)(node::CINNode)
    if node.kind === access && node.tns isa CINNode && node.tns.kind === virtual
        select_access(node, ctx, node.tns.val)
    elseif istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
end
select_access(node, ctx, tns) = similarterm(node, operation(node), map(ctx, arguments(node)))

struct SelectStyle end

combine_style(a::SelectStyle, b::ThunkStyle) = b
combine_style(a::SelectStyle, b::ChunkStyle) = a
combine_style(a::SelectStyle, b::SelectStyle) = a

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
    contain(ctx) do ctx_2
        dimensionalize!(root, ctx_2)
        ctx_2(root)
    end
end