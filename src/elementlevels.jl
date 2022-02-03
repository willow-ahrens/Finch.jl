struct ElementLevel{D, Tv}
    val::Vector{Tv}
end
ElementLevel{D}(args...) where {D} = ElementLevel{D, typeof(D)}(args...)
ElementLevel{D, Tv}() where {D, Tv} = ElementLevel{D, Tv}(Vector{Tv}(undef, 4))
const Element = ElementLevel

@inline arity(fbr::Fiber{<:ElementLevel}) = 0
@inline shape(fbr::Fiber{<:ElementLevel}) = ()
@inline domain(fbr::Fiber{<:ElementLevel}) = ()
@inline image(fbr::Fiber{ElementLevel{D, Tv}}) where {D, Tv} = Tv
@inline default(lvl::Fiber{<:ElementLevel{D}}) where {D} = D

function (fbr::Fiber{<:ElementLevel})()
    q = envposition(fbr.env)
    return fbr.lvl.val[q]
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
    val_q = ctx.freshen(sym, :_val_q)
    push!(ctx.preamble, quote
        $sym = $ex
        $val_q = length($ex.val)
    end)
    VirtualElementLevel(sym, Tv, D, val_q)
end

function getsites(fbr::VirtualFiber{VirtualElementLevel})
    return ()
end

getdims(::VirtualFiber{VirtualElementLevel}, ctx, mode) = ()

function initialize_level!(fbr::VirtualFiber{VirtualElementLevel}, ctx, mode)
    my_q = ctx.freshen(fbr.lvl.ex)
    push!(ctx.preamble, quote
        if $(fbr.lvl.val_q) < 4
            resize!($(fbr.lvl.ex).val, 4)
        end
        $(fbr.lvl.val_q) = 4
        for $my_q = 1:4
            $(fbr.lvl.ex).val[$my_q] = $(fbr.lvl.D)
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


function unfurl(lvl::VirtualElementLevel, fbr, ctx, ::Read)
    R = fbr.R
    val = ctx.freshen(getname(fbr), :_val)

    Thunk(
        preamble = quote
            $val = $(lvl.ex).val[$(ctx(fbr.poss[end]))]
        end,
        body = Virtual{lvl.Tv}(val)
    )
end

function unfurl(lvl::VirtualElementLevel, fbr, ctx, ::Write)
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

function unfurl(lvl::VirtualElementLevel, fbr, ctx, ::Update)
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