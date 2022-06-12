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
                ctx_4(Chunk(root.idx, Extent(start = i0, stop = getstop(root.ext), lower = 1), body))
            end
        end
    end

    if simplify((@i $(getlower(ext)) >= 1)) == true  && simplify((@i $(getupper(ext)) <= 1)) == true
        body_2
    else
        return quote
            while $guard
                $body_2
            end
        end
    end
end

unwrap_cycle(node, ctx, ext, style) = nothing