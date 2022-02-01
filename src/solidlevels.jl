struct SolidLevel{Ti}
    I::Ti
end
SolidLevel{Ti}() where {Ti} = SolidLevel(zero(Ti))
SolidLevel() = SolidLevel(0)
SolidLevel(I::Ti) where {Ti} = SolidLevel{Ti}(I)
const Solid = SolidLevel

dimension(lvl::SolidLevel) = lvl.I

function unfurl(lvl::SolidLevel{Ti}, fbr::Fiber{Tv, N, R}, i, tail...) where {Tv, Ti, N, R}
    q = fbr.poss[R]
    p = (q - 1) * lvl.I + i
    readindex(refurl(fbr, p, i), tail...)
end



struct VirtualSolidLevel
    ex
    Ti
    I
end

(ctx::Finch.LowerJulia)(lvl::VirtualSolidLevel) = lvl.ex

function virtualize(ex, ::Type{<:SolidLevel{Ti}}, ctx, tag=:lvl) where {Ti}
    sym = ctx.freshen(tag)
    I = ctx.freshen(tag, :_stop)
    push!(ctx.preamble, quote
        $sym = $ex
        $I = $sym.I
    end)
    VirtualSolidLevel(sym, Ti, I)
end

virtual_unfurl(lvl::VirtualSolidLevel, tns, ctx, mode::Read, idx::Name, tail...) =
    virtual_unfurl(lvl, tns, ctx, mode, follow(idx), tail...)
virtual_unfurl(lvl::VirtualSolidLevel, tns, ctx, mode::Union{Write, Update}, idx::Name, tail...) =
    virtual_unfurl(lvl, tns, ctx, mode, laminate(idx), tail...)


function getdims_level!(lvl::VirtualSolidLevel, arr, R, ctx, mode)
    ext = Extent(1, Virtual{Int}(lvl.I))
    return mode isa Read ? ext : SuggestedExtent(ext)
end

function initialize_level!(lvl::VirtualSolidLevel, tns, R, ctx, mode)
    if mode isa Union{Write, Update}
        push!(ctx.preamble, quote
            $(lvl.I) = $(ctx(ctx.dims[(getname(tns), R)].stop))
            $(lvl.ex) = SolidLevel{$(lvl.Ti)}(
                $(lvl.Ti)($(lvl.I)),
            )
        end)
        lvl
    else
        return nothing
    end
end

function virtual_assemble(lvl::VirtualSolidLevel, tns, ctx, qoss, q)
    if q == nothing
        return quote end
    else
        q2 = ctx.freshen(getname(fbr), :_lvl, R, :_q)
        return quote
            $q2 = ($(ctx(qoss)) - 1) * $(lvl.ex).I + $(ctx(i))
            $(virtual_assemble(tns, ctx, qoss, q2))
        end
    end
end

function virtual_unfurl(lvl::VirtualSolidLevel, fbr, ctx, mode::Union{Read, Write, Update}, idx::Union{Follow, Laminate, Extrude}, tail...)
    R = fbr.R
    q = fbr.poss[R]
    p = ctx.freshen(getname(fbr), :_, R, :_p)

    if R == 1
        Leaf(
            body = (i) -> virtual_refurl(fbr, i, i, mode, tail...),
        )
    else
        Leaf(
            body = (i) -> Thunk(
                preamble = quote
                    $p = ($(ctx(q)) - 1) * $(lvl.ex).I + $(ctx(i))
                end,
                body = virtual_refurl(fbr, Virtual{lvl.Ti}(p), i, mode, tail...),
            )
        )
    end
end