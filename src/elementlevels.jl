struct ElementLevel{D, Tv}
    val::Vector{Tv}
end
ElementLevel{D}(args...) where {D} = ElementLevel{D, typeof(D)}(args...)
ElementLevel{D, Tv}() where {D, Tv} = ElementLevel{D, Tv}(Vector{Tv}(undef, 4))
const Element = ElementLevel

@inline valtype(lvl::ElementLevel{D, Tv}) where {D, Tv} = Tv

function unfurl(lvl::ElementLevel, fbr::Fiber{Tv, N, R}) where {Tv, N, R}
    q = fbr.poss[R]
    return lvl.val[q]
end



struct VirtualElementLevel
    ex
    Tv
    D
    val_q
end

(ctx::Finch.LowerJulia)(lvl::VirtualElementLevel) = lvl.ex

function virtualize(ex, ::Type{ElementLevel{D, Tv}}, ctx, tag) where {D, Tv}
    sym = ctx.freshen(tag)
    val_q = ctx.freshen(tag, :_val_q)
    push!(ctx.preamble, quote
        $sym = $ex
        $val_q = length($ex.val)
    end)
    VirtualElementLevel(sym, Tv, D, val_q)
end

function initialize_level!(lvl::VirtualElementLevel, tns, R, ctx, mode)
    my_q = ctx.freshen(:lvl, tns.R, :_q)
    push!(ctx.preamble, quote
        if $(lvl.val_q) < 4
            resize!($(lvl.ex).val, 4)
        end
        $(lvl.val_q) = 4
        for $my_q = 1:4
            $(lvl.ex).val[$my_q] = $(lvl.D)
        end
    end)
    nothing
end

function virtual_assemble(lvl::VirtualElementLevel, tns, ctx, qoss, q)
    if q == nothing
        return quote end
    else
        my_q = ctx.freshen(:lvl, tns.R, :_q)
        return quote
            if $(lvl.val_q) < $q
                resize!($(lvl.ex).val, $(lvl.val_q) * 4)
                @simd for $my_q = $(lvl.val_q) + 1: $(lvl.val_q) * 4
                    $(lvl.ex).val[$my_q] = $(lvl.D)
                end
                $(lvl.val_q) *= 4
            end
        end
    end
end


function virtual_unfurl(lvl::VirtualElementLevel, fbr, ctx, ::Read)
    R = fbr.R
    val = ctx.freshen(getname(fbr), :_val)

    Thunk(
        preamble = quote
            $val = $(lvl.ex).val[$(ctx(fbr.poss[end]))]
        end,
        body = Virtual{lvl.Tv}(val)
    )
end

function virtual_unfurl(lvl::VirtualElementLevel, fbr, ctx, ::Write)
    R = fbr.R
    val = ctx.freshen(getname(fbr), :_val)

    Thunk(
        preamble = quote
            $val = nothing
        end,
        body = Virtual{lvl.Tv}(val),
        epilogue = quote
            $(lvl.ex).val[$(ctx(fbr.poss[end]))] = $val
        end,
    )
end

function virtual_unfurl(lvl::VirtualElementLevel, fbr, ctx, ::Update)
    R = fbr.R
    val = ctx.freshen(getname(fbr), :_val)

    Thunk(
        preamble = quote
            $val = $(lvl.ex).val[$(ctx(fbr.poss[end]))]
        end,
        body = Virtual{lvl.Tv}(val),
        epilogue = quote
            $(lvl.ex).val[$(ctx(fbr.poss[end]))] = $val
        end,
    )
end