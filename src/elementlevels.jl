struct ElementLevel{D, Tv}
    val::Vector{Tv}
end
ElementLevel(D, args...) = ElementLevel{D}(args...)
ElementLevel{D}(args...) where {D} = ElementLevel{D, typeof(D)}(args...)
ElementLevel{D, Tv}() where {D, Tv} = ElementLevel{D, Tv}(Vector{Tv}(undef, 4))
const Element = ElementLevel

pattern!(lvl::ElementLevel) = Pattern()

"""
`f_code(e)` = [ElementLevel](@ref).
"""
f_code(::Val{:e}) = Element
summary_f_code(::Element{D}) where {D} = "e($(D))"
similar_level(::ElementLevel{D}) where {D} = ElementLevel{D}()

function Base.show(io::IO, lvl::ElementLevel{D}) where {D}
    print(io, "Element{")
    show(io, D)
    print(io, "}(")
    if get(io, :compact, true)
        print(io, "…")
    else
        show_region(io, lvl.val)
    end
    print(io, ")")
end 

@inline Base.ndims(fbr::Fiber{<:ElementLevel}) = 0
@inline Base.size(fbr::Fiber{<:ElementLevel}) = ()
@inline Base.axes(fbr::Fiber{<:ElementLevel}) = ()
@inline Base.eltype(fbr::Fiber{ElementLevel{D, Tv}}) where {D, Tv} = Tv
@inline default(lvl::Fiber{<:ElementLevel{D}}) where {D} = D

function (fbr::Fiber{<:ElementLevel})()
    q = envposition(fbr.env)
    return fbr.lvl.val[q]
end



struct VirtualElementLevel
    ex
    Tv
    D
    val_alloc
    val
end

(ctx::Finch.LowerJulia)(lvl::VirtualElementLevel) = lvl.ex
function virtualize(ex, ::Type{ElementLevel{D, Tv}}, ctx, tag) where {D, Tv}
    sym = ctx.freshen(tag)
    val_alloc = ctx.freshen(sym, :_val_alloc)
    val = ctx.freshen(sym, :_val)
    push!(ctx.preamble, quote
        $sym = $ex
        $val_alloc = length($ex.val)
        $val = $D
    end)
    VirtualElementLevel(sym, Tv, D, val_alloc, val)
end

summary_f_code(lvl::VirtualElementLevel) = "e($(lvl.D))"

function getsites(fbr::VirtualFiber{VirtualElementLevel})
    return []
end

setsize!(fbr::VirtualFiber{VirtualElementLevel}, ctx, mode) = fbr
getsize(::VirtualFiber{VirtualElementLevel}, ctx, mode) = ()

@inline default(fbr::VirtualFiber{VirtualElementLevel}) = fbr.lvl.D
Base.eltype(fbr::VirtualFiber{VirtualElementLevel}) = fbr.lvl.Tv

function initialize_level!(fbr::VirtualFiber{VirtualElementLevel}, ctx, mode)
    lvl = fbr.lvl
    my_q = ctx.freshen(lvl.ex, :_q)
    if !envreinitialized(fbr.env)
        if mode.kind === updater && !mode.mode.val
            push!(ctx.preamble, quote
                $(lvl.val_alloc) = $Finch.refill!($(lvl.ex).val, $(lvl.D), 0, 4)
            end)
        end
    end
    lvl
end

finalize_level!(fbr::VirtualFiber{VirtualElementLevel}, ctx, mode) = fbr.lvl

interval_assembly_depth(lvl::VirtualElementLevel) = Inf

function assemble!(fbr::VirtualFiber{VirtualElementLevel}, ctx, mode)
    lvl = fbr.lvl
    q = ctx(getstop(envposition(fbr.env)))
    push!(ctx.preamble, quote
        $(lvl.val_alloc) < $q && ($(lvl.val_alloc) = $Finch.refill!($(lvl.ex).val, $(lvl.D), $(lvl.val_alloc), $q))
    end)
end

function reinitialize!(fbr::VirtualFiber{VirtualElementLevel}, ctx, mode)
    lvl = fbr.lvl
    p_start = getstart(envposition(fbr.env))
    p_stop = getstop(envposition(fbr.env))
    push!(ctx.preamble, quote
        for $p = $(ctx(p_start)):$(ctx(p_stop))
            $(lvl.ex).val[$p] = $(lvl.D)
        end
    end)
end

function refurl(fbr::VirtualFiber{VirtualElementLevel}, ctx, mode)
    lvl = fbr.lvl

    if mode.kind === reader
        return Thunk(
            preamble = quote
                $(lvl.val) = $(lvl.ex).val[$(ctx(envposition(fbr.env)))]
            end,
            body = access(fbr, mode),
        )
    elseif mode.kind === updater
        return Thunk(
            preamble = quote
                $(lvl.val) = $(lvl.ex).val[$(ctx(envposition(fbr.env)))]
            end,
            body = access(fbr, mode),
            epilogue = quote
                $(lvl.ex).val[$(ctx(envposition(fbr.env)))] = $(lvl.val)
            end,
        )
    else
        error("unimplemented")
    end
end

function lowerjulia_access(ctx::Finch.LowerJulia, node, tns::VirtualFiber{VirtualElementLevel})
    @assert isempty(node.idxs)

    if node.mode.kind === updater && envdefaultcheck(tns.env) !== nothing
        push!(ctx.preamble, quote
            $(envdefaultcheck(tns.env)) = false
        end)
    end
    tns.lvl.val
end

hasdefaultcheck(::VirtualElementLevel) = true