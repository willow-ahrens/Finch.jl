struct ElementLevel{D, Tv}
    val::Vector{Tv}
end
ElementLevel(D, args...) = ElementLevel{D}(args...)

ElementLevel{D}() where {D} = ElementLevel{D, typeof(D)}()
ElementLevel{D}(val::Vector{Tv}) where {D, Tv} = ElementLevel{D, Tv}(val)
ElementLevel{D, Tv}() where {D, Tv} = ElementLevel{D, Tv}(Tv[])
const Element = ElementLevel

pattern!(lvl::ElementLevel) = Pattern()

"""
`f_code(e)` = [ElementLevel](@ref).
"""
f_code(::Val{:e}) = Element
summary_f_code(::Element{D}) where {D} = "e($(D))"
similar_level(::ElementLevel{D}) where {D} = ElementLevel{D}()

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

function (fbr::Fiber{<:ElementLevel})()
    q = envposition(fbr.env)
    return fbr.lvl.val[q]
end



struct VirtualElementLevel
    ex
    Tv
    D
    dirty
    val
end

(ctx::Finch.LowerJulia)(lvl::VirtualElementLevel) = lvl.ex
function virtualize(ex, ::Type{ElementLevel{D, Tv}}, ctx, tag=:lvl) where {D, Tv}
    sym = ctx.freshen(tag)
    val_alloc = ctx.freshen(sym, :_val_alloc)
    val = ctx.freshen(sym, :_val)
    push!(ctx.preamble, quote
        $sym = $ex
        $val = $D
    end)
    dirty = ctx.freshen(sym, :_dirty)
    VirtualElementLevel(sym, Tv, D, dirty, val)
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

set_clean!(lvl::VirtualElementLevel, ctx) = :($(lvl.dirty) = false)
get_dirty(lvl::VirtualElementLevel, ctx) = value(lvl.dirty, Bool)

function get_level_reader(lvl::VirtualElementLevel, ctx, pos)
    return Thunk(
        preamble = quote
            $(lvl.val) = $(lvl.ex).val[$(ctx(pos))]
        end,
        body = VirtualFiber(lvl, VirtualEnvironment(position = pos)),
    )
end

function get_level_updater(lvl::VirtualElementLevel, ctx, pos)
    return Thunk(
        preamble = quote
            $(lvl.val) = $(lvl.ex).val[$(ctx(pos))]
        end,
        body = VirtualFiber(lvl, VirtualEnvironment(position = pos)),
        epilogue = quote
            $(lvl.ex).val[$(ctx(pos))] = $(lvl.val)
        end,
    )
end

function lowerjulia_access(ctx::Finch.LowerJulia, node, tns::VirtualFiber{VirtualElementLevel})
    @assert isempty(node.idxs)

    if node.mode.kind === updater
        push!(ctx.preamble, quote
            $(tns.lvl.dirty) = true
        end)
    end
    tns.lvl.val
end