function lower_cycle(root, ctx, ext::UnitExtent, style)
    i = getname(root.idx)
    i0 = ctx.freshen(i, :_start)
    push!(ctx.preamble, quote
        $i0 = $(ctx(getstart(root.ext)))
        $i = $i0
    end)

    body = Postwalk(node->unwrap_cycle(node, ctx, ext, style))(root.body)

    contain(ctx) do ctx_4
        push!(ctx_4.preamble, :($i0 = $i))
        ctx_4(Chunk(root.idx, Extent(i0, getstop(ext)), body))
    end
end

function lower_cycle(root, ctx, ext, style)
    i = getname(root.idx)
    i0 = ctx.freshen(i, :_start)
    push!(ctx.preamble, quote
        $i0 = $(ctx(getstart(root.ext)))
        $i = $i0
    end)

    guard = :($i <= $(ctx(getstop(root.ext))))
    body = Postwalk(node->unwrap_cycle(node, ctx, ext, style))(root.body)

    body_2 = fixpoint(ctx) do ctx_2
        scope(ctx_2) do ctx_3
            contain(ctx_3) do ctx_4
                push!(ctx_4.preamble, :($i0 = $i))
                ctx_4(Chunk(root.idx, Extent(i0, getstop(root.ext)), body))
            end
        end
    end
    return quote
        while $guard
            $body_2
        end
    end
end

unwrap_cycle(node, ctx, ext, style) = nothing