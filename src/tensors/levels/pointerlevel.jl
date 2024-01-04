"""
    PointerLevel{Lvl, [Val]}()

A subfiber of a pointer level is a separate fiber of type `Lvl`, in it's 
own memory space.

Each sublevel is stored in a vector of type `Val` with `eltype(Val) = Lvl`. 

```jldoctest
julia> Fiber!(Dense(Pointer(Dense(Element(0.0)))), [[1, 2, 3]])
Dense [1:3]
├─[1]: 1.0
├─[2]: 2.0
├─[3]: 3.0
```
"""
struct PointerLevel{Val, Lvl}
    val::Val
    lvl::Lvl
end
const Pointer = PointerLevel

PointerLevel(lvl::Lvl) where {Lvl} = PointerLevel([lvl], lvl)
PointerLevel{Val, Lvl}(lvl::Lvl) where {Val, Lvl} =  PointerLevel{Val, Lvl}([lvl], lvl)
Base.summary(::Pointer{Val, Lvl}) where {Val, Lvl} = "Pointer($(Lvl))"

similar_level(lvl::Pointer{Val, Lvl}) where {Val, Lvl} = PointerLevel{Val, Lvl}(similar_level(lvl.lvl))

postype(::Type{<:Pointer{Val, Lvl}}) where {Val, Lvl} = postype(Lvl)

function moveto(lvl::PointerLevel, device)
    lvl_2 = moveto(lvl.lvl, device)
    val_2 = moveto(lvl.val, device)
    return PointerLevel(val_2, lvl_2)
end

pattern!(lvl::PointerLevel) = PointerLevel(map(pattern!, lvl.val), pattern!(lvl.lvl))
redefault!(lvl::PointerLevel, init) = PointerLevel(map(lvl_2->redefault!(lvl_2, init), lvl.val), redefault!(lvl.lvl, init))

function Base.show(io::IO, lvl::PointerLevel{Val, Lvl}) where {Val, Lvl}
    print(io, "Pointer(")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>Val), lvl.val)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Val), lvl.lvl)
    end
    print(io, ")")
end 

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:PointerLevel}, depth)
    p = fbr.pos
    print(io, "Pointer -> ")
    display_fiber(io, mime, SubFiber(fbr.lvl.val[p], 1), depth)
end

@inline level_ndims(::Type{<:PointerLevel{Val, Lvl}}) where {Val, Lvl} = level_ndims(Lvl)
@inline level_size(lvl::PointerLevel{Val, Lvl}) where {Val, Lvl} = level_size(lvl.lvl)
@inline level_axes(lvl::PointerLevel{Val, Lvl}) where {Val, Lvl} = level_axes(lvl.lvl)
@inline level_eltype(::Type{PointerLevel{Val, Lvl}}) where {Val, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:PointerLevel{Val, Lvl}}) where {Val, Lvl} = level_default(Lvl)

(fbr::Fiber{<:PointerLevel})() = SubFiber(fbr.lvl, 1)()
(fbr::SubFiber{<:PointerLevel})() = fbr #TODO this is not consistent somehow
function (fbr::SubFiber{<:PointerLevel})(idxs...)
    q = fbr.pos
    return Fiber(fbr.lvl.val[q])(idxs...)
end

countstored_level(lvl::PointerLevel, pos) = pos

mutable struct VirtualPointerLevel <: AbstractVirtualLevel
    lvl  # stand in for the sublevel for virutal resize, etc.
    ex
    Tv
    Val
    Lvl
end

postype(lvl:: VirtualPointerLevel) = postype(lvl.lvl)

is_level_injective(::VirtualPointerLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., true]
is_level_concurrent(::VirtualPointerLevel, ctx) = [is_level_concurrent(lvl.lvl, ctx)..., true]
is_level_atomic(lvl::VirtualPointerLevel, ctx) = is_level_atomic(lvl.lvl, ctx)

function lower(lvl::VirtualPointerLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $PointerLevel{$(lvl.Val), $(lvl.Lvl)}($(lvl.ex).val, $(ctx(lvl.lvl)))
    end
end

function virtualize(ex, ::Type{PointerLevel{Val, Lvl}}, ctx, tag=:lvl) where {Val, Lvl}
    sym = freshen(ctx, tag)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($ex.lvl), Lvl, ctx, sym)
    VirtualPointerLevel(lvl_2, sym, typeof(level_default(Lvl)), Val, Lvl)
end

Base.summary(lvl::VirtualPointerLevel) = "Pointer($(lvl.Lvl))"

virtual_level_resize!(lvl::VirtualPointerLevel, ctx, dims...) = (lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims...); lvl)
virtual_level_size(lvl::VirtualPointerLevel, ctx) = virtual_level_size(lvl.lvl, ctx)
virtual_level_eltype(lvl::VirtualPointerLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualPointerLevel) = virtual_level_default(lvl.lvl)

function declare_level!(lvl::VirtualPointerLevel, ctx, pos, init)
    #declare_level!(lvl.lvl, ctx_2, literal(1), init)
    return lvl
end

function assemble_level!(lvl::VirtualPointerLevel, ctx, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(pos_start, ctx))
    pos_stop = cache!(ctx, :pos_stop, simplify(pos_stop, ctx))
    idx = freshen(ctx.code, :idx)
    sym = freshen(ctx.code, :pointer_to_lvl)
    push!(ctx.code.preamble, quote
        Finch.resize_if_smaller!($(lvl.ex).val, $(ctx(pos_stop)))
        for $idx in $(ctx(pos_start)):$(ctx(pos_stop))
            $sym = similar_level($(lvl.ex).lvl)
            $(contain(ctx) do ctx_2
                lvl_2 = virtualize(sym, lvl.Lvl, ctx_2.code, sym)
                lvl_2 = declare_level!(lvl_2, ctx_2, literal(0), literal(virtual_level_default(lvl_2)))
                lvl_2 = virtual_level_resize!(lvl_2, ctx_2, virtual_level_size(lvl.lvl, ctx_2)...)
                push!(ctx_2.code.preamble, assemble_level!(lvl_2, ctx_2, literal(1), literal(1)))
                lvl_2 = freeze_level!(lvl_2, ctx_2, literal(1))
                :($(lvl.ex).val[$idx] = $(ctx_2(lvl_2)))
            end)
        end
    end)
    lvl
end

supports_reassembly(::VirtualPointerLevel) = true
function reassemble_level!(lvl::VirtualPointerLevel, ctx, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(pos_start, ctx))
    pos_stop = cache!(ctx, :pos_stop, simplify(pos_stop, ctx))
    idx = freshen(ctx.code, :idx)
    push!(ctx.code.preamble, quote
        for $idx in $(ctx(pos_start)):$(ctx(pos_stop))
            $(contain(ctx) do ctx_2
                lvl_2 = virtualize(:($(lvl.ex).val[$idx]), lvl.Lvl, ctx_2.code, sym)
                declare_level!(lvl_2, ctx_2, literal(1), init)
                push!(ctx_2.code.preamble, assemble_level!(lvl_2, ctx, literal(1), literal(1)))
                lvl_2 = freeze_level!(lvl_2, ctx, literal(1))
                :($(lvl.ex).val[$idx] = $(ctx_2(lvl_2)))
            end)
        end
    end)
    lvl
end

function freeze_level!(lvl::VirtualPointerLevel, ctx, pos)
    return lvl
end

function thaw_level!(lvl::VirtualPointerLevel, ctx::AbstractCompiler, pos)
    return lvl
end

function trim_level!(lvl::VirtualPointerLevel, ctx::AbstractCompiler, pos)
    idx = freshen(ctx.code, :idx)
    sym = freshen(ctx.code, :pointer_to_lvl)
    
    push!(ctx.code.preamble, quote
        for $idx in 1:$(ctx(pos))
            $(contain(ctx) do ctx_2
                lvl_2 = virtualize(:($(lvl.ex).val[$idx]), lvl.Lvl, ctx_2.code, sym)
                trim_level!(lvl_2, ctx_2, literal(1))
            end)
        end
    end)
    lvl
end

function instantiate(fbr::VirtualSubFiber{VirtualPointerLevel}, ctx, mode::Reader, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    isnulltest = freshen(ctx.code, tag, :_nulltest)
    D = level_default(lvl.Lvl)
    sym = freshen(ctx.code, :pointer_to_lvl)
    val = freshen(ctx.code, lvl.ex, :_val)
    lvl_2 = virtualize(:($(lvl.ex).val[$(ctx(pos))]), lvl.Lvl, ctx.code, sym)
    return body = Thunk(
        body = (ctx) -> instantiate(VirtualSubFiber(lvl_2, literal(1)), ctx, mode, protos),
    )
end

function instantiate(fbr::VirtualSubFiber{VirtualPointerLevel}, ctx, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    sym = freshen(ctx.code, :pointer_to_lvl)
    lvl_2 = virtualize(:($(lvl.ex).val[$(ctx(pos))]), lvl.Lvl, ctx.code, sym)

    return body = Thunk(
        body = (ctx) -> begin
            thaw_level!(lvl_2, ctx, literal(1))
            push!(ctx.code.preamble, assemble_level!(lvl_2, ctx, literal(1), literal(1)))
            res = instantiate(VirtualSubFiber(lvl_2, literal(1)), ctx, mode, protos)
            freeze_level!(lvl, ctx, literal(1))
            res
        end
    )
end
function instantiate(fbr::VirtualHollowSubFiber{VirtualPointerLevel}, ctx, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    sym = freshen(ctx.code, :pointer_to_lvl)
    lvl_2 = virtualize(:($(lvl.ex).val[$(ctx(pos))]), lvl.Lvl, ctx.code, sym)

    return body = Thunk(
        body = (ctx) -> begin
            thaw_level!(lvl_2, ctx, literal(1))
            push!(ctx.code.preamble, assemble_level!(lvl_2, ctx, literal(1), literal(1)))
            res = instantiate(VirtualHollowSubFiber(lvl_2, literal(1), fbr.dirty), ctx, mode, protos)
            freeze_level!(lvl, ctx, literal(1))
            res
        end
    )
end
