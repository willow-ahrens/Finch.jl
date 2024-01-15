"""
    AtomicLevel{Lvl, Val}()

Atomic Level Protects the level directly below it with atomics

Each sublevel is stored in a vector of type `Val` with `eltype(Val) = Lvl`. 

```jldoctest
julia> Tensor(Dense(Separation(Element(0.0))), [1, 2, 3])
Dense [1:3]
├─[1]: Pointer -> 1.0
├─[2]: Pointer -> 2.0
├─[3]: Pointer -> 3.0
```
"""
struct AtomicLevel{AVal, Lvl} <: AbstractLevel
    lvl::Lvl
    atomicsArray::AVal
end
const Atomic = AtomicLevel

# FIXME: Need to allocate the correct number of poses.
AtomicLevel(lvl::Lvl) where {Lvl} = AtomicLevel{Vector{Bool}, Lvl}(lvl, Vector{Bool}([]))
AtomicLevel{AVal, Lvl}(lvl::Lvl, atomics::AVal) where {Lvl, AVal} =  SeparationLevel{AVal, Lvl}(lvl, atomics)
Base.summary(::AtomicLevel{AVal, Lvl}) where {Lvl, AVal} = "AtomicLevel($(AVal), $(Lvl))"

similar_level(lvl::Atomic{AVal, Lvl}) where {Lvl, AVal} = AtomicLevel{AVal, Lvl}(similar_level(lvl.lvl))

postype(::Type{<:AtomicLevel{AVal, Lvl}}) where {Lvl, AVal} = postype(Lvl)

function moveto(lvl::AtomicLevel, device)
    lvl_2 = moveto(lvl.lvl, device)
    atomicsArray_2 = moveto(lvl.atomicsArray, device)
    return AtomicLevel(lvl_2, atomicsArray_2)
end

pattern!(lvl::AtomicLevel) = AtomicLevel(pattern!(lvl.lvl), lvl.atomicsArray)
redefault!(lvl::AtomicLevel, init) = AtomicLevel(redefault!(lvl.lvl, init), lvl.atomicsArray)
# TODO: FIXME: Need toa dopt the number of dims
Base.resize!(lvl::AtomicLevel, dims...) = AtomicLevel(resize!(lvl.lvl, dims...), resize!(lvl.atomicsArray, dims[end]))


function Base.show(io::IO, lvl::AtomicLevel{AVal, Lvl}) where {AVal, Lvl}
    print(io, "Atomic(")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>AVal), lvl.atomicsArray)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Val), lvl.lvl)
    end
    print(io, ")")
end 

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:AtomicLevel}, depth)
    p = fbr.pos
    lvl = fbr.lvl
    if p > length(lvl.val)
        print(io, "Atomic -> undef")
        return
    end
    print(io, "Atomic -> ")
    display_fiber(io, mime, SubFiber(fbr.lvl.val[p], 1), depth)
end

@inline level_ndims(::Type{<:AtomicLevel{AVal, Lvl}}) where {AVal, Lvl} = level_ndims(Lvl)
@inline level_size(lvl::AtomicLevel{AVal, Lvl}) where {AVal, Lvl} = level_size(lvl.lvl)
@inline level_axes(lvl::AtomicLevel{AVal, Lvl}) where {AVal, Lvl} = level_axes(lvl.lvl)
@inline level_eltype(::Type{AtomicLevel{AVal, Lvl}}) where {AVal, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:AtomicLevel{AVal, Lvl}}) where {AVal, Lvl} = level_default(Lvl)

(fbr::Tensor{<:AtomicLevel})() = SubFiber(fbr.lvl, 1)()
(fbr::SubFiber{<:AtomicLevel})() = fbr #TODO this is not consistent somehow
function (fbr::SubFiber{<:AtomicLevel})(idxs...)
    q = fbr.pos
    return Tensor(fbr.lvl.val[q])(idxs...)
end

countstored_level(lvl::AtomicLevel, pos) = pos

mutable struct VirtualAtomicLevel <: AbstractVirtualLevel
    lvl
    ex
    Tv
    Val
    Lvl
end

postype(lvl:: AtomicLevel) = postype(lvl.lvl)

is_level_injective(::AtomicLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., true]
is_level_concurrent(::AtomicLevel, ctx) = [is_level_concurrent(lvl.lvl, ctx)..., true]
is_level_atomic(lvl::AtomicLevel, ctx) = true

function lower(lvl::AtomicLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $AtomicLevel{$(lvl.Lvl)}($(lvl.ex).atomicsArray, $(ctx(lvl.lvl)))
    end
end

function virtualize(ex, ::Type{AtomicLevel{AVal, Lvl}}, ctx, tag=:lvl) where {AVal, Lvl}
    sym = freshen(ctx, tag)
    push!(ctx.preamble, quote
        $sym = $ex
          end)
    #FIXME ME We probalby don't need this.
    lvl_2 = virtualize(:($ex.lvl), Lvl, ctx, sym)
    VirtualAtomicLevel(lvl_2, sym, typeof(level_default(Lvl)), Val, Lvl)
end

Base.summary(lvl::VirtualAtomicLevel) = "Separation($(lvl.Lvl))"

virtual_level_resize!(lvl::VirtualAtomicLevel, ctx, dims...) = (lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims...); lvl)
virtual_level_size(lvl::VirtualAtomicLevel, ctx) = virtual_level_size(lvl.lvl, ctx)
virtual_level_eltype(lvl::VirtualAtomicLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualAtomicLevel) = virtual_level_default(lvl.lvl)

function declare_level!(lvl::VirtualAtomicLevel, ctx, pos, init)
    #declare_level!(lvl.lvl, ctx_2, literal(1), init)
    # FIXME: We need to adjust the size of the atomics here; we should ensure we have up to pos many.
    return lvl
end

function assemble_level!(lvl::VirtualSeparationLevel, ctx, pos_start, pos_stop)
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

supports_reassembly(::VirtualSeparationLevel) = true
function reassemble_level!(lvl::VirtualSeparationLevel, ctx, pos_start, pos_stop)
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

function freeze_level!(lvl::VirtualSeparationLevel, ctx, pos)
    return lvl
end

function thaw_level!(lvl::VirtualSeparationLevel, ctx::AbstractCompiler, pos)
    return lvl
end

function trim_level!(lvl::VirtualSeparationLevel, ctx::AbstractCompiler, pos)
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

function instantiate(fbr::VirtualSubFiber{VirtualSeparationLevel}, ctx, mode::Reader, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    isnulltest = freshen(ctx.code, tag, :_nulltest)
    D = level_default(lvl.Lvl)
    sym = freshen(ctx.code, :pointer_to_lvl)
    val = freshen(ctx.code, lvl.ex, :_val)
    return body = Thunk(
        body = (ctx) -> begin
            lvl_2 = virtualize(:($(lvl.ex).val[$(ctx(pos))]), lvl.Lvl, ctx.code, sym)
            instantiate(VirtualSubFiber(lvl_2, literal(1)), ctx, mode, protos)
        end,
    )
end

function instantiate(fbr::VirtualSubFiber{VirtualSeparationLevel}, ctx, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    sym = freshen(ctx.code, :pointer_to_lvl)

    return body = Thunk(
        body = (ctx) -> begin
            lvl_2 = virtualize(:($(lvl.ex).val[$(ctx(pos))]), lvl.Lvl, ctx.code, sym)
            thaw_level!(lvl_2, ctx, literal(1))
            push!(ctx.code.preamble, assemble_level!(lvl_2, ctx, literal(1), literal(1)))
            res = instantiate(VirtualSubFiber(lvl_2, literal(1)), ctx, mode, protos)
            freeze_level!(lvl, ctx, literal(1))
            res
        end
    )
end
function instantiate(fbr::VirtualHollowSubFiber{VirtualSeparationLevel}, ctx, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    sym = freshen(ctx.code, :pointer_to_lvl)

    return body = Thunk(
        body = (ctx) -> begin
            lvl_2 = virtualize(:($(lvl.ex).val[$(ctx(pos))]), lvl.Lvl, ctx.code, sym)
            thaw_level!(lvl_2, ctx, literal(1))
            push!(ctx.code.preamble, assemble_level!(lvl_2, ctx, literal(1), literal(1)))
            res = instantiate(VirtualHollowSubFiber(lvl_2, literal(1), fbr.dirty), ctx, mode, protos)
            freeze_level!(lvl, ctx, literal(1))
            res
        end
    )
end
