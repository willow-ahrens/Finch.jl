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

@inline default(fbr::VirtualFiber{VirtualElementLevel}) = fbr.lvl.D

function initialize_level!(fbr::VirtualFiber{VirtualElementLevel}, ctx, mode)
    lvl = fbr.lvl
    my_q = ctx.freshen(lvl.ex, :_q)
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

function assemble!(fbr::VirtualFiber{VirtualElementLevel}, ctx, mode)
    lvl = fbr.lvl
    q = envmaxposition(fbr.env)
    my_q = ctx.freshen(lvl.ex, :_q)
    push!(ctx.preamble, quote
        if $(lvl.val_q) < $q
            resize!($(lvl.ex).val, $(lvl.val_q) * 4)
            @simd for $my_q = $(lvl.val_q) + 1: $(lvl.val_q) * 4
                $(lvl.ex).val[$my_q] = $(lvl.D)
            end
            $(lvl.val_q) *= 4
        end
    end)
    return nothing
end

function unfurl(fbr::VirtualFiber{VirtualElementLevel}, ctx, ::Read)
    lvl = fbr.lvl
    tag = lvl.ex
    val = ctx.freshen(tag, :_val)

    Thunk(
        preamble = quote
            $val = $(lvl.ex).val[$(ctx(envposition(fbr.env)))]
        end,
        body = Virtual{lvl.Tv}(val)
    )
end

function unfurl(fbr::VirtualFiber{VirtualElementLevel}, ctx, ::Write)
    lvl = fbr.lvl
    tag = lvl.ex
    val = ctx.freshen(tag, :_val)

    Thunk(
        preamble = quote
            $val = nothing
        end,
        body = Virtual{lvl.Tv}(val),
        epilogue = quote
            $(lvl.ex).val[$(ctx(envposition(fbr.env)))] = $val
        end,
    )
end

function unfurl(fbr::VirtualFiber{VirtualElementLevel}, ctx, ::Update)
    lvl = fbr.lvl
    tag = lvl.ex
    val = ctx.freshen(tag, :_val)

    Thunk(
        preamble = quote
            $val = $(lvl.ex).val[$(ctx(envposition(fbr.env)))]
        end,
        body = Virtual{lvl.Tv}(val),
        epilogue = quote
            $(lvl.ex).val[$(ctx(envposition(fbr.env)))] = $val
        end,
    )
end