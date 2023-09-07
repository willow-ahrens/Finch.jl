"""
    ElementLevel{D, [Tv]}()

A subfiber of an element level is a scalar of type `Tv`, initialized to `D`. `D`
may optionally be given as the first argument.

In the [`Fiber!`](@ref) constructor, `e` is an alias for `ElementLevel`.

```jldoctest
julia> Fiber!(Dense(Element(0.0)), [1, 2, 3])
Dense [1:3]
├─[1]: 1.0
├─[2]: 2.0
├─[3]: 3.0
```
"""
struct ElementLevel{D, Ti, Tv, V<:AbstractVector}
    val::V
end
const Element = ElementLevel

function ElementLevel(d, args...)
    isbits(d) || throw(ArgumentError("Finch currently only supports isbits defaults"))
    ElementLevel{d}(args...)
end
ElementLevel{D}() where {D} = ElementLevel{D, Int, typeof(D), Vector{typeof(D)}}()
ElementLevel{D}(val::V) where {D, V} = ElementLevel{D, Int, eltype(V), V}(val)
ElementLevel{D, Ti}() where {D, Ti} = ElementLevel{D, Ti, typeof(D), Vector{typeof(D)}}()
ElementLevel{D, Ti}(val::V) where {D, Ti, V} = ElementLevel{D, Ti, eltype(V), V}(val)

ElementLevel{D, Ti, Tv}() where {D, Ti, Tv} = ElementLevel{D, Ti, Tv, Vector{Tv}}(empty(Vector{Tv}))
ElementLevel{D, Ti, Tv}(val::V) where {D, Ti, Tv, V} = ElementLevel{D, Ti, eltype(V), V}(val)
ElementLevel{D, Ti, Tv, V}() where {D, Ti, Tv, V} = ElementLevel{D, Ti, Tv, V}(empty(V))

Base.summary(::Element{D, Ti}) where {D, Ti} = "Element($(D), $(Ti))"
# similar_level(::ElementLevel{D}) where {D} = ElementLevel{D}()
similar_level(::ElementLevel{D, Ti}) where {D, Ti} = ElementLevel{D, Ti}()

function memory_type(::Type{ElementLevel{D, Ti, Tv, V}}) where {D, Ti, Tv, V}
    return containertype(V)
end

function postype(::Type{ElementLevel{D, Ti, Tv, V}}) where {D, Ti, Tv, V}
    return postype(V)
end


function indextype(::Type{ElementLevel{D, Ti, Tv, V}}) where {D, Ti, Tv, V}
    return indextype(Ti)
end


function moveto(lvl::ElementLevel{D, Ti, Tv, V},  ::Type{MemType}) where {D, Ti, Tv, V, MemType <: AbstractArray}
    valp = MemType(lvl.val)
    return ElementLevel{D, Ti, Tv, typeof(valp)}(valp)
end

pattern!(lvl::ElementLevel{D, Ti, Tv, V}) where  {D, Ti, Tv, V} = Pattern{Ti, postype(ElementLevel{D, Ti, Tv, V}), containertype(V){Bool, 1}}()
redefault!(lvl::ElementLevel{D, Ti, Tv, V}, init) where {D, Ti, Tv, V} = 
    ElementLevel{init, Ti, Tv, V}(lvl.val)

function Base.show(io::IO, lvl::ElementLevel{D, Ti, Tv, V}) where {D, Ti, Tv, V}
    print(io, "Element{")
    show(io, D)
    print(io, ", $Ti, $Tv, $V}(")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>V), lvl.val)
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
@inline level_eltype(::Type{ElementLevel{D, Ti, Tv, V}}) where {D, Ti, Tv, V} = Tv
@inline level_default(::Type{<:ElementLevel{D}}) where {D} = D
data_rep_level(::Type{<:ElementLevel{D, Ti, Tv, V}}) where {D, Ti, Tv, V} = ElementData(D, Ti, Tv)

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

function virtualize(ex, ::Type{ElementLevel{D, Ti, Tv, V}}, ctx, tag=:lvl) where {D, Ti, Tv, V}
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
