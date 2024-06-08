struct ThunkStyle end

@kwdef struct Thunk
    preamble = quote end
    body
    epilogue = quote end
end
FinchNotation.finch_leaf(x::Thunk) = virtual(x)

Base.show(io::IO, ex::Thunk) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Thunk)
    print(io, "Thunk()")
end

get_style(ctx, ::Thunk, root) = ThunkStyle()
instantiate(ctx, tns::Thunk, mode, protos) = tns
combine_style(a::DefaultStyle, b::ThunkStyle) = ThunkStyle()
combine_style(a::ThunkStyle, b::ThunkStyle) = ThunkStyle()
combine_style(a::ThunkStyle, b::SimplifyStyle) = ThunkStyle()

struct ThunkVisitor
    ctx
end

function (ctx::ThunkVisitor)(node)
    if istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
end

function lower(ctx::AbstractCompiler, node, ::ThunkStyle)
    contain(ctx) do ctx2
        node = (ThunkVisitor(ctx2))(node)
        contain(ctx2) do ctx3
            (ctx3)(node)
        end
    end
end

function (ctx::ThunkVisitor)(node::FinchNode)
    if node.kind === virtual
        ctx(node.val)
    elseif node.kind === access && node.tns.kind === virtual
        #TODO this case morally shouldn't exist
        thunk_access(ctx, node, node.tns.val)
    elseif istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
end

thunk_access(ctx, node, tns) = similarterm(node, operation(node), map(ctx, arguments(node)))

function (ctx::ThunkVisitor)(node::Thunk)
    push_preamble!(ctx.ctx, node.preamble)
    push_epilogue!(ctx.ctx, node.epilogue)
    node.body(ctx.ctx)
end
