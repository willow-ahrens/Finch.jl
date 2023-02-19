"""
    ElementLevel{D, [Tv]}()

A subfiber of an element level is a scalar of type `Tv`, initialized to `D`. `D`
may optionally be given as the first argument.

In the [@fiber](@ref) constructor, `e` is an alias for `ElementLevel`.

```jldoctest
julia> @fiber(d(e(0.0)), [1, 2, 3])
Dense [1:3]
├─[1]: 1.0
├─[2]: 2.0
├─[3]: 3.0

@fiber(d(e{1, Number}()), Number[1, 1.1, 0xff])
Dense [1:3]
├─[1]: 1
├─[2]: 1.1
├─[3]: 0xff
```
"""
struct ElementLevel{D, Tv}
    val::Vector{Tv}
end
const Element = ElementLevel

ElementLevel(d, args...) = ElementLevel{d}(args...)
ElementLevel{D}() where {D} = ElementLevel{D, typeof(D)}()
ElementLevel{D}(val::Vector{Tv}) where {D, Tv} = ElementLevel{D, Tv}(val)

ElementLevel{D, Tv}() where {D, Tv} = ElementLevel{D, Tv}(Tv[])

"""
`f_code(e)` = [ElementLevel](@ref).
"""
f_code(::Val{:e}) = Element
summary_f_code(::Element{D}) where {D} = "e($(D))"
similar_level(::ElementLevel{D}) where {D} = ElementLevel{D}()

pattern!(lvl::ElementLevel) = Pattern()

function Base.show(io::IO, lvl::ElementLevel{D, Tv}) where {D, Tv}
    print(io, "Element{")
    show(io, D)
    print(io, ", $Tv}(")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>Vector{Tv}), lvl.val)
    end
    print(io, ")")
end 

@inline level_ndims(::Type{<:ElementLevel}) = 0
@inline level_size(::ElementLevel) = ()
@inline level_axes(::ElementLevel) = ()
@inline level_eltype(::Type{ElementLevel{D, Tv}}) where {D, Tv} = Tv
@inline level_default(::Type{<:ElementLevel{D}}) where {D} = D
data_rep_level(::Type{<:ElementLevel{D, Tv}}) where {D, Tv} = ElementData(D, Tv)

(fbr::Fiber{<:ElementLevel})() = SubFiber(fbr.lvl, 1)()
function (fbr::SubFiber{<:ElementLevel})()
    q = fbr.pos
    return fbr.lvl.val[q]
end



struct VirtualElementLevel
    ex
    Tv
    D
end

(ctx::Finch.LowerJulia)(lvl::VirtualElementLevel) = lvl.ex
function virtualize(ex, ::Type{ElementLevel{D, Tv}}, ctx, tag=:lvl) where {D, Tv}
    sym = ctx.freshen(tag)
    val_alloc = ctx.freshen(sym, :_val_alloc)
    val = ctx.freshen(sym, :_val)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    VirtualElementLevel(sym, Tv, D)
end

summary_f_code(lvl::VirtualElementLevel) = "e($(lvl.D))"

virtual_level_resize!(lvl::VirtualElementLevel, ctx) = lvl
virtual_level_size(::VirtualElementLevel, ctx) = ()
virtual_level_eltype(lvl::VirtualElementLevel) = lvl.Tv
virtual_level_default(lvl::VirtualElementLevel) = lvl.D

initialize_level!(lvl::VirtualElementLevel, ctx, pos) = lvl

freeze_level!(lvl::VirtualElementLevel, ctx, pos) = lvl

function trim_level!(lvl::VirtualElementLevel, ctx::LowerJulia, pos)
    push!(ctx.preamble, quote
        resize!($(lvl.ex).val, $(ctx(pos)))
    end)
    return lvl
end

function assemble_level!(lvl::VirtualElementLevel, ctx, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(pos_start, ctx))
    pos_stop = cache!(ctx, :pos_stop, simplify(pos_stop, ctx))
    quote
        resize_if_smaller!($(lvl.ex).val, $(ctx(pos_stop)))
        fill_range!($(lvl.ex).val, $(lvl.D), $(ctx(pos_start)), $(ctx(pos_stop)))
    end
end

supports_reassembly(::VirtualElementLevel) = true
function reassemble_level!(lvl::VirtualElementLevel, ctx, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(pos_start, ctx))
    pos_stop = cache!(ctx, :pos_stop, simplify(pos_stop, ctx))
    push!(ctx.preamble, quote
        fill_range!($(lvl.ex).val, $(lvl.D), $(ctx(pos_start)), $(ctx(pos_stop)))
    end)
    lvl
end

function get_reader(fbr::VirtualSubFiber{VirtualElementLevel}, ctx)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    val = ctx.freshen(lvl.ex, :_val)
    return Thunk(
        preamble = quote
            $val = $(lvl.ex).val[$(ctx(pos))]
        end,
        body = VirtualScalar(nothing, lvl.Tv, lvl.D, gensym(), val)
    )
end

function get_updater(fbr::VirtualSubFiber{VirtualElementLevel}, ctx)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    val = ctx.freshen(lvl.ex, :_val)
    return Thunk(
        preamble = quote
            $val = $(lvl.ex).val[$(ctx(pos))]
        end,
        body = VirtualScalar(nothing, lvl.Tv, lvl.D, gensym(), val),
        epilogue = quote
            $(lvl.ex).val[$(ctx(pos))] = $val
        end
    )
end

function get_updater(fbr::VirtualTrackedSubFiber{VirtualElementLevel}, ctx)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    val = ctx.freshen(lvl.ex, :_val)
    return Thunk(
        preamble = quote
            $val = $(lvl.ex).val[$(ctx(pos))]
        end,
        body = VirtualDirtyScalar(nothing, lvl.Tv, lvl.D, gensym(), val, fbr.dirty),
        epilogue = quote
            $(lvl.ex).val[$(ctx(pos))] = $val
        end
    )
end