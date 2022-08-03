struct SolidLevel{Ti, Lvl}
    I::Ti
    lvl::Lvl
end
SolidLevel{Ti}(I, lvl::Lvl) where {Ti, Lvl} = SolidLevel{Ti, Lvl}(I, lvl)
SolidLevel{Ti}(lvl::Lvl) where {Ti, Lvl} = SolidLevel{Ti, Lvl}(zero(Ti), lvl)
SolidLevel(lvl) = SolidLevel(0, lvl)
const Solid = SolidLevel

"""
`f_code(s)` = [SolidLevel](@ref).
"""
f_code(::Val{:s}) = Solid
summary_f_code(lvl::Solid) = "s($(summary_f_code(lvl.lvl)))"
similar_level(lvl::SolidLevel) = Solid(similar_level(lvl.lvl))
similar_level(lvl::SolidLevel, dim, tail...) = Solid(dim, similar_level(lvl.lvl, tail...))

dimension(lvl::SolidLevel) = lvl.I

@inline arity(fbr::Fiber{<:SolidLevel}) = 1 + arity(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline shape(fbr::Fiber{<:SolidLevel}) = (fbr.lvl.I, shape(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline domain(fbr::Fiber{<:SolidLevel}) = (1:fbr.lvl.I, domain(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline image(fbr::Fiber{<:SolidLevel}) = image(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline default(fbr::Fiber{<:SolidLevel}) = default(Fiber(fbr.lvl.lvl, Environment(fbr.env)))

(fbr::Fiber{<:SolidLevel})() = fbr
function (fbr::Fiber{<:SolidLevel{Ti}})(i, tail...) where {D, Tv, Ti, N, R}
    lvl = fbr.lvl
    p = envposition(fbr.env)
    q = (p - 1) * lvl.I + i
    fbr_2 = Fiber(lvl.lvl, Environment(position=q, index=i, parent=fbr.env))
    fbr_2(tail...)
end

function Base.show(io::IO, lvl::SolidLevel)
    print(io, "Solid(")
    print(io, lvl.I)
    print(io, ", ")
    show(io, lvl.lvl)
    print(io, ")")
end 

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:SolidLevel})
    crds = 1:fbr.lvl.I
    depth = envdepth(fbr.env)

    print_coord(io, crd) = (print(io, "["); show(io, crd); print(io, "]"))
    get_coord(crd) = crd
    print(io, "│ " ^ depth); print(io, "Solid ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]")
    display_fiber_data(io, mime, fbr, 1, crds, print_coord, get_coord)
end


mutable struct VirtualSolidLevel
    ex
    Ti
    I
    lvl
end
function virtualize(ex, ::Type{SolidLevel{Ti, Lvl}}, ctx, tag=:lvl) where {Ti, Lvl}
    sym = ctx.freshen(tag)
    I = Virtual{Int}(:($sym.I))
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSolidLevel(sym, Ti, I, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualSolidLevel)
    quote
        $SolidLevel{$(lvl.Ti)}(
            $(ctx(lvl.I)),
            $(ctx(lvl.lvl)),
        )
    end
end

summary_f_str(lvl::VirtualSolidLevel) = "s$(summary_f_str(lvl.lvl))"
summary_f_str_args(lvl::VirtualSolidLevel) = summary_f_str_args(lvl.lvl)

getsites(fbr::VirtualFiber{VirtualSolidLevel}) =
    [envdepth(fbr.env) + 1, getsites(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))...]

function getdims(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode)
    ext = Extent(1, fbr.lvl.I)
    if mode != Read()
        ext = suggest(ext)
    end
    (ext, getdims(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)...)
end

function setdims!(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode, dim, dims...)
    fbr.lvl.I = getstop(dim)
    fbr.lvl.lvl = setdims!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode, dims...).lvl
    fbr
end

@inline default(fbr::VirtualFiber{<:VirtualSolidLevel}) = default(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))

reinitializeable(lvl::VirtualSolidLevel) = reinitializeable(lvl.lvl)
function initialize_level!(fbr::VirtualFiber{VirtualSolidLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    fbr.lvl.lvl = initialize_level!(VirtualFiber(fbr.lvl.lvl, Environment(fbr.env, reinitialized=envreinitialized(fbr.env))), ctx, mode)
    return fbr.lvl
end

function reinitialize!(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode)
    lvl = fbr.lvl
    p_start = getstart(envposition(fbr.env))
    p_stop = getstop(envposition(fbr.env))
    q_start = call(*, p_start, lvl.I)
    q_stop = call(*, p_stop, lvl.I)
    if interval_assembly_depth(lvl.lvl) >= 1
        reinitialize!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Extent(q_start, q_stop), index = Extent(1, lvl.I), parent=fbr.env)), ctx, mode)
    else
        p = ctx.freshen(lvl.ex, :_p)
        p = ctx.freshen(lvl.ex, :_q)
        i_2 = ctx.freshen(lvl.ex, :_i)
        push!(ctx.preamble, quote
            for $p = $(ctx(p_start)):$(ctx(p_stop))
                for $i = 1:$(lvl.I)
                    $q = ($p - 1) * $(ctx(lvl.I)) + $i
                    reinitialize!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual(q), index=Virtual(i), parent=fbr.env)), ctx, mode)
                end
            end
        end)
    end
end

interval_assembly_depth(lvl::VirtualSolidLevel) = min(Inf, interval_assembly_depth(lvl.lvl) - 1)

function assemble!(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode)
    lvl = fbr.lvl
    p_start = getstart(envposition(fbr.env))
    p_stop = getstop(envposition(fbr.env))
    q_start = call(*, p_start, lvl.I)
    q_stop = call(*, p_stop, lvl.I)
    if interval_assembly_depth(lvl.lvl) >= 1
        assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Extent(q_start, q_stop), index = Extent(1, lvl.I), parent=fbr.env)), ctx, mode)
    else
        p = ctx.freshen(lvl.ex, :_p)
        p = ctx.freshen(lvl.ex, :_q)
        i_2 = ctx.freshen(lvl.ex, :_i)
        push!(ctx.preamble, quote
            for $p = $(ctx(p_start)):$(ctx(p_stop))
                for $i = 1:$(ctx(lvl.I))
                    $q = ($p - 1) * $(ctx(lvl.I)) + $i
                    assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual(q), index=Virtual(i), parent=fbr.env)), ctx, mode)
                end
            end
        end)
    end
end

function finalize_level!(fbr::VirtualFiber{VirtualSolidLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    fbr.lvl.lvl = finalize_level!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)
    return fbr.lvl
end

hasdefaultcheck(lvl::VirtualSolidLevel) = hasdefaultcheck(lvl.lvl)

unfurl(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode::Union{Write, Update, Read}, idx, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, follow), idxs...)

function unfurl(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode::Union{Read, Write, Update}, idx::Protocol{<:Any, <:Union{Follow, Laminate, Extrude}}, idxs...) #TODO should protocol be strict?
    lvl = fbr.lvl
    tag = lvl.ex

    p = envposition(fbr.env)
    q = ctx.freshen(tag, :_q)
    body = Leaf(
        val = default(fbr),
        body = (i) -> Thunk(
            preamble = quote
                $q = ($(ctx(p)) - 1) * $(ctx(lvl.I)) + $(ctx(i))
            end,
            body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(q), index=i, guard=envdefaultcheck(fbr.env), parent=fbr.env)), ctx, mode, idxs...),
        )
    )

    exfurl(body, ctx, mode, idx.idx)
end