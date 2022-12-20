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
    if ctx.root isa IndexNode && ctx.root.kind === loop && ctx.root.idx == get_furl_root(node.idxs[2])
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
                body = (start, step) -> Run(body=Simplify(Fill(false)))
            ),
            Phase(
                stride = (ctx, idx, ext) -> value(sym),
                body = (start, step) -> Run(body=Simplify(Fill(true))),
            ),
            Phase(body = (start, step) -> Run(body=Simplify(Fill(false))))
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

function (ctx::SelectVisitor)(node::IndexNode)
    if node.kind === access && node.tns isa IndexNode && node.tns.kind === virtual
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

#=
@kwdef struct Furlable
    name = gensym()
    size
    body
end

getsize(tns::Furlable, ::LowerJulia, mode) = tns.size
getname(tns::Furlable) = tns.name

IndexNotation.isliteral(::Furlable) = false

Base.show(io::IO, ex::Furlable) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Furlable)
    print(io, "Furlable()")
end

function stylize_access(node, ctx::Stylize{LowerJulia}, tns::Furlable)
    if !isempty(node.idxs)
        if getunbound(node.idxs[1]) ⊆ keys(ctx.ctx.bindings)
            return SelectStyle()
        elseif ctx.root isa IndexNode && ctx.root.kind === loop && ctx.root.idx == get_furl_root(node.idxs[1])
            return ChunkStyle()
        end
    end
    return DefaultStyle()
end

function select_access(node, ctx::Finch.SelectVisitor, tns::Furlable)
    if !isempty(node.idxs)
        if getunbound(node.idxs[1]) ⊆ keys(ctx.ctx.bindings)
            var = index(ctx.ctx.freshen(:s))
            ctx.idxs[var] = node.idxs[1]
            return access(node.tns, node.mode, var, node.idxs[2:end]...)
        end
    end
    return similarterm(node, operation(node), map(ctx, arguments(node)))
end

function chunkify_access(node, ctx, tns::Furlable)
    if !isempty(node.idxs)
        idxs = map(ctx, node.idxs)
        if ctx.idx == get_furl_root(node.idxs[1])
            lpt = tns.body(ctx.ctx, ctx.idx, ctx.ext)
            lpt = exfurl(lpt, ctx.ctx, node.mode, node.idxs[1])
            return access(lpt, node.mode, get_furl_root(node.idxs[1]))
        else
            return access(node.tns, node.mode, idxs...)
        end
    end
    return node
end

struct DiagMask end

const diagmask = DiagMask()

Base.show(io::IO, ex::DiagMask) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::DiagMask)
    print(io, "diagmask")
end

virtualize(ex, ::Type{DiagMask}, ctx) = diagmask

initialize(::DiagMask, ctx, mode, idxs...) = begin
    Furlable(
        body = (ctx, idx, ext) -> Lookup(
            (i) -> Furlable(
                body = Pipeline([
                    Phase(
                        stride = (ctx, idx, ext) -> value(:($i - 1)),
                        body = (start, step) -> Run(body=Simplify(Fill(false)))
                    ),
                    Phase(
                        stride = (ctx, idx, ext) -> value(i),
                        body = (start, step) -> Run(body=Simplify(Fill(true))),
                    ),
                    Phase(body = (start, step) -> Run(body=Simplify(Fill(false))))
                ])
            )
        )
    )
end
=#