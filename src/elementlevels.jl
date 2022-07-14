struct ElementLevel{D, Tv}
    val::Vector{Tv}
end
ElementLevel{D}(args...) where {D} = ElementLevel{D, typeof(D)}(args...)
ElementLevel{D, Tv}() where {D, Tv} = ElementLevel{D, Tv}(Vector{Tv}(undef, 4))
const Element = ElementLevel

parse_level((D,),) = Element{D}()
summary_f_str(::ElementLevel) = ""
summary_f_str_args(::ElementLevel{D}) where {D} = (D,)

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

summary_f_str(::VirtualElementLevel) = ""
summary_f_str_args(::VirtualElementLevel) = (lvl.D,)

function getsites(fbr::VirtualFiber{VirtualElementLevel})
    return []
end

setdims!(fbr::VirtualFiber{VirtualElementLevel}, ctx, mode) = fbr
getdims(::VirtualFiber{VirtualElementLevel}, ctx, mode) = ()

@inline default(fbr::VirtualFiber{VirtualElementLevel}) = fbr.lvl.D

function initialize_level!(fbr::VirtualFiber{VirtualElementLevel}, ctx, mode::Union{Write, Update})
    lvl = fbr.lvl
    my_q = ctx.freshen(lvl.ex, :_q)
    if !envreinitialized(fbr.env)
        push!(ctx.preamble, quote
            $(lvl.val_alloc) = $Finch.refill!($(lvl.ex).val, $(lvl.D), 0, 4)
        end)
    end
    lvl
end

finalize_level!(fbr::VirtualFiber{VirtualElementLevel}, ctx, mode::Union{Write, Update}) = fbr.lvl

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

#=
#TODO This assumes that all of the elements will eventually be written to, which isn't always true sadly.
function assemble!(fbr::VirtualFiber{VirtualElementLevel}, ctx, mode::Write)
    lvl = fbr.lvl
    q = envposition(fbr.env)
    push!(ctx.preamble, quote
        $(lvl.val_alloc) < $q && ($(lvl.val_alloc) = $Finch.regrow!($(lvl.ex).val, $(lvl.val_alloc), $q))
    end)
    return nothing
end
=#

function refurl(fbr::VirtualFiber{VirtualElementLevel}, ctx, ::Read)
    lvl = fbr.lvl

    Thunk(
        preamble = quote
            $(lvl.val) = $(lvl.ex).val[$(ctx(envposition(fbr.env)))]
        end,
        body = Access(fbr, Read(), []),
    )
end

function refurl(fbr::VirtualFiber{VirtualElementLevel}, ctx, ::Write)
    lvl = fbr.lvl

    Thunk(
        preamble = quote
            $(lvl.val) = $(lvl.D)
        end,
        body = Access(fbr, Write(), []),
        epilogue = quote
            $(lvl.ex).val[$(ctx(envposition(fbr.env)))] = $(lvl.val)
        end,
    )
end

function refurl(fbr::VirtualFiber{VirtualElementLevel}, ctx, ::Update)
    lvl = fbr.lvl

    Thunk(
        preamble = quote
            $(lvl.val) = $(lvl.ex).val[$(ctx(envposition(fbr.env)))]
        end,
        body = Access(fbr, Update(), []),
        epilogue = quote
            $(lvl.ex).val[$(ctx(envposition(fbr.env)))] = $(lvl.val)
        end,
    )
end

function (ctx::Finch.LowerJulia)(node::Access{<:VirtualFiber{VirtualElementLevel}}, ::DefaultStyle) where {Tv, Ti}
    @assert isempty(node.idxs)
    tns = node.tns

    node.tns.lvl.val
end

hasdefaultcheck(::VirtualElementLevel) = true

function (ctx::Finch.LowerJulia)(node::Access{<:VirtualFiber{VirtualElementLevel}, <:Union{Write, Update}}, ::DefaultStyle) where {Tv, Ti}
    @assert isempty(node.idxs)
    tns = node.tns

    if envdefaultcheck(tns.env) !== nothing
        push!(ctx.preamble, quote
            $(envdefaultcheck(tns.env)) = false
        end)
    end

    node.tns.lvl.val
end