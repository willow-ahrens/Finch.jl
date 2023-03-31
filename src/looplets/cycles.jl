function lower_cycle(root, ctx, idx, ext, style)
    i = getname(root.idx)
    i0 = ctx.freshen(i, :_start)
    push!(ctx.preamble, quote
        $i = $(ctx(getstart(root.ext)))
    end)

    guard = :($i <= $(ctx(getstop(root.ext))))
    body = CycleVisitor(style, ctx, idx, ext)(root.body)

    body_2 = contain(ctx) do ctx_2
        push!(ctx_2.preamble, :($i0 = $i))
        ctx_2(chunk(root.idx, Extent(start = value(i0), stop = getstop(root.ext)), body))
    end

    @assert isvirtual(ext)
    if query(call(==, measure(ext.val), 1), ctx)
        body_2
    else
        return quote
            while $guard
                $body_2
            end
        end
    end
end

@kwdef struct CycleVisitor{Style}
    style::Style
    ctx
    idx
    ext
end

function (ctx::CycleVisitor)(node)
    if istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end

function (ctx::CycleVisitor)(node::FinchNode)
    if node.kind === virtual
        ctx(node.val)
    elseif istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end

(ctx::CycleVisitor)(node::Shift) = Shift(CycleVisitor(; kwfields(ctx)..., ext=shiftdim(ctx.ext, call(-, node.delta)))(node.body), node.delta)