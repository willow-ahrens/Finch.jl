"""
    ElementLevel{D, [Tv=typeof(D), Tp=Int, Vv]}()

A subfiber of an element level is a scalar of type `Tv`, initialized to `D`. `D`
may optionally be given as the first argument.

The data is stored in a vector
of type `Vv` with `eltype(Vv) = Tv`. The type `Ti` is the index type used to
access Vv.

In the [`Fiber!`](@ref) constructor, `e` is an alias for `ElementLevel`.

```jldoctest
julia> Fiber!(Dense(Element(0.0)), [1, 2, 3])
Dense [1:3]
├─[1]: 1.0
├─[2]: 2.0
├─[3]: 3.0
```
"""
struct ElementLevel{D, Tv, Tp, Vv<:AbstractVector}
    val::Vv
end
const Element = ElementLevel

function ElementLevel(d, args...)
    isbits(d) || throw(ArgumentError("Finch currently only supports isbits defaults"))
    ElementLevel{d}(args...)
end
ElementLevel{D}() where {D} = ElementLevel{D, typeof(D)}()
ElementLevel{D}(val::Vv) where {D, Vv} = ElementLevel{D, eltype(Vv)}(val)
ElementLevel{D, Tv}(args...) where {D, Tv} = ElementLevel{D, Tv, Int}(args...)
ElementLevel{D, Tv, Tp}(args...) where {D, Tv, Tp, Vv} = ElementLevel{D, Tv, Tp, Vector{Tv}}(args...)
ElementLevel{D, Tv, Tp, Vv}() where {D, Tv, Tp, Vv} = ElementLevel{D, Tv, Int, Vv}(Tv[])

ElementLevel{D, Tv, Tp}(val::Vv) where {D, Tv, Tp, Vv} = ElementLevel{D, Tv, Int, Vv}(val)

Base.summary(::Element{D}) where {D} = "Element($(D))"

similar_level(::ElementLevel{D, Tv, Tp}) where {D, Tv, Tp} = ElementLevel{D, Tv, Tp}()

memtype(::Type{ElementLevel{D, Tv, Tp, Vv}}) where {D, Tv, Tp, Vv} =
    containertype(Vv)

postype(::Type{<:ElementLevel{D, Tv, Tp}}) where {D, Tv, Tp} = Tp

function moveto(lvl::ElementLevel{D, Tv, Tp, Vv}, ::Type{MemType}) where {D, Tv, Tp, Vv, MemType <: AbstractArray}
    valp = MemType(lvl.val)
    return ElementLevel{D, Tv, Tp, typeof(valp)}(valp)
end

pattern!(lvl::ElementLevel{D, Tv, Tp, Vv}) where  {D, Tv, Tp, Vv} =
    Pattern{Tp, Vv}()
redefault!(lvl::ElementLevel{D, Tv, Tp, Vv}, init) where {D, Tv, Tp, Vv} = 
    ElementLevel{init, Tv, Tp, Vv}(lvl.val)


function Base.show(io::IO, lvl::ElementLevel{D, Tv, Tp, Vv}) where {D, Tv, Tp, Vv}
    print(io, "Element{")
    show(io, D)
    print(io, ", $Tv, $Tp, $Vv}(")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>Vv), lvl.val)
    end
    print(io, ")")
end 

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:ElementLevel}, depth)
    p = fbr.pos
    show(io, mime, fbr.lvl.val[p])
end

@inline level_ndims(::Type{<:ElementLevel}) = 0
@inline level_size(::ElementLevel) = ()
@inline level_axes(::ElementLevel) = ()
@inline level_eltype(::Type{ElementLevel{D, Tv, Tp, Vv}}) where {D, Tv, Tp, Vv} = Tv
@inline level_default(::Type{<:ElementLevel{D}}) where {D} = D
data_rep_level(::Type{<:ElementLevel{D, Tv, Tp, Vv}}) where {D, Tv, Tp, Vv} = ElementData(D, Tv)

(fbr::Fiber{<:ElementLevel})() = SubFiber(fbr.lvl, 1)()
function (fbr::SubFiber{<:ElementLevel})()
    q = fbr.pos
    return fbr.lvl.val[q]
end

countstored_level(lvl::ElementLevel, pos) = pos

struct VirtualElementLevel <: AbstractVirtualLevel
    ex
    Tv
    D
end

is_level_injective(::VirtualElementLevel, ctx) = []
is_level_concurrent(::VirtualElementLevel, ctx) = []
is_level_atomic(lvl::VirtualElementLevel, ctx) = false

lower(lvl::VirtualElementLevel, ctx::AbstractCompiler, ::DefaultStyle) = lvl.ex

function virtualize(ex, ::Type{ElementLevel{D, Tv, Tp, Vv}}, ctx, tag=:lvl) where {D, Tv, Tp, Vv}
    sym = freshen(ctx, tag)
    val_alloc = freshen(ctx, sym, :_val_alloc)
    val = freshen(ctx, sym, :_val)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    VirtualElementLevel(sym, Tv, D)
end

Base.summary(lvl::VirtualElementLevel) = "Element($(lvl.D))"

virtual_level_resize!(lvl::VirtualElementLevel, ctx) = lvl
virtual_level_size(::VirtualElementLevel, ctx) = ()
virtual_level_eltype(lvl::VirtualElementLevel) = lvl.Tv
virtual_level_default(lvl::VirtualElementLevel) = lvl.D

function declare_level!(lvl::VirtualElementLevel, ctx, pos, init)
    init == literal(lvl.D) || throw(FinchProtocolError("Cannot initialize Element Levels to non-default values(have $init expected $(lvl.D))"))
    lvl
end

freeze_level!(lvl::VirtualElementLevel, ctx, pos) = lvl

thaw_level!(lvl::VirtualElementLevel, ctx::AbstractCompiler, pos) = lvl

function trim_level!(lvl::VirtualElementLevel, ctx::AbstractCompiler, pos)
    push!(ctx.code.preamble, quote
        resize!($(lvl.ex).val, $(ctx(pos)))
    end)
    return lvl
end

function assemble_level!(lvl::VirtualElementLevel, ctx, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(pos_start, ctx))
    pos_stop = cache!(ctx, :pos_stop, simplify(pos_stop, ctx))
    quote
        Finch.resize_if_smaller!($(lvl.ex).val, $(ctx(pos_stop)))
        Finch.fill_range!($(lvl.ex).val, $(lvl.D), $(ctx(pos_start)), $(ctx(pos_stop)))
    end
end

supports_reassembly(::VirtualElementLevel) = true
function reassemble_level!(lvl::VirtualElementLevel, ctx, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(pos_start, ctx))
    pos_stop = cache!(ctx, :pos_stop, simplify(pos_stop, ctx))
    push!(ctx.code.preamble, quote
        Finch.fill_range!($(lvl.ex).val, $(lvl.D), $(ctx(pos_start)), $(ctx(pos_stop)))
    end)
    lvl
end

function instantiate_reader(fbr::VirtualSubFiber{VirtualElementLevel}, ctx, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    val = freshen(ctx.code, lvl.ex, :_val)
    return Thunk(
        preamble = quote
            $val = $(lvl.ex).val[$(ctx(pos))]
        end,
        body = (ctx) -> VirtualScalar(nothing, lvl.Tv, lvl.D, gensym(), val)
    )
end

function instantiate_updater(fbr::VirtualSubFiber{VirtualElementLevel}, ctx, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    VirtualScalar(nothing, lvl.Tv, lvl.D, gensym(), :($(lvl.ex).val[$(ctx(pos))]))
end

function instantiate_updater(fbr::VirtualTrackedSubFiber{VirtualElementLevel}, ctx, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    VirtualDirtyScalar(nothing, lvl.Tv, lvl.D, gensym(), :($(lvl.ex).val[$(ctx(pos))]), fbr.dirty)
end