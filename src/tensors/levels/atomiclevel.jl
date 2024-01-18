
"""
    AtomicLevel{Lvl, Val}()

Atomic Level Protects the level directly below it with atomics

Each sublevel is stored in a vector of type Val with eltype(Val) = Lvl.
julia> Tensor(Dense(Atomic(Element(0.0))), [1, 2, 3])
Dense [1:3] -> Atomic
├─[1]: 1.0
├─[2]: 2.0
├─[3]: 3.0
"""

struct AtomicLevel{AVal <: AbstractVector, Lvl} <: AbstractLevel
    lvl::Lvl
    atomicsArray::AVal
end
const Atomic = AtomicLevel


AtomicLevel(lvl::Lvl) where {Lvl} = AtomicLevel{Vector{Base.Threads.SpinLock}, Lvl}(lvl, Vector{Base.Threads.SpinLock}([]))
AtomicLevel{AVal, Lvl}(atomics::AVal, lvl::Lvl,) where {Lvl, AVal} =  AtomicLevel{AVal, Lvl}(lvl, atomics)
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
Base.resize!(lvl::AtomicLevel, dims...) = AtomicLevel(resize!(lvl.lvl, dims...), lvl.atomicsArray)


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
    display_fiber(io, mime, SubFiber(fbr.lvl, 1), depth)
end

@inline level_ndims(::Type{<:AtomicLevel{AVal, Lvl}}) where {AVal, Lvl} = level_ndims(Lvl)
@inline level_size(lvl::AtomicLevel{AVal, Lvl}) where {AVal, Lvl} = level_size(lvl.lvl)
@inline level_axes(lvl::AtomicLevel{AVal, Lvl}) where {AVal, Lvl} = level_axes(lvl.lvl)
@inline level_eltype(::Type{AtomicLevel{AVal, Lvl}}) where {AVal, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:AtomicLevel{AVal, Lvl}}) where {AVal, Lvl} = level_default(Lvl)

# FIXME: These.
(fbr::Tensor{<:AtomicLevel})() = SubFiber(fbr.lvl, 1)()
(fbr::SubFiber{<:AtomicLevel})() = fbr #TODO this is not consistent somehow
function (fbr::SubFiber{<:AtomicLevel})(idxs...)
    return Tensor(fbr.lvl)(idxs...)
end

countstored_level(lvl::AtomicLevel, pos) = countstored_level(lvl.lvl, pos)

mutable struct VirtualAtomicLevel <: AbstractVirtualLevel
    lvl # the level below us.
    ex
    Tv
    Val
    AVal
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
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    temp = VirtualAtomicLevel(lvl_2, sym, typeof(level_default(Lvl)), Val, AVal, Lvl)
    print(temp, "\n")
    print(virtual_level_size(lvl_2, ctx), "\n")

    temp
end

Base.summary(lvl::VirtualAtomicLevel) = "Atomic($(lvl.Lvl))"
virtual_level_resize!(lvl::VirtualAtomicLevel, ctx, dims...) = (lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims...); lvl)
virtual_level_size(lvl::VirtualAtomicLevel, ctx) = virtual_level_size(lvl.lvl, ctx)
virtual_level_size(x, ctx) = error(string("Not defined for", x))
virtual_level_eltype(lvl::VirtualAtomicLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualAtomicLevel) = virtual_level_default(lvl.lvl)

function declare_level!(lvl::VirtualAtomicLevel, ctx, pos, init)
    posV = ctx(pos)
    idx = freshen(ctx.code, :idx)
    push!(ctx.code.preamble, quote 
              Finch.resize_if_smaller!($(lvl.ex).atomicsArray, ctx, $posV)
              @inbounds for $idx = 1:$posV
                  $(lvl.ex).atomicsArray[i] = make_lock(eltype($(lvl.AVal)))
              end
          end)
    lvl.lvl = declare_level!(lvl.lvl, ctx, pos, init)
    return lvl
end

function assemble_level!(lvl::VirtualAtomicLevel, ctx, pos_start, pos_stop)
    lvl.lvl = assemble_level!(lvl.lvl, ctx, pos_start, pos_stop)
    lvl
end

supports_reassembly(lvl::VirtualAtomicLevel) = supports_reassembly(lvl.lvl)
function reassemble_level!(lvl::VirtualAtomicLevel, ctx, pos_start, pos_stop)
    lvl.lvl = reassemble_level!(lvl.lvl, ctx, pos_start, pos_stop)
    lvl
end

function freeze_level!(lvl::VirtualAtomicLevel, ctx, pos)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, pos)
    return lvl
end

function thaw_level!(lvl::VirtualAtomicLevel, ctx::AbstractCompiler, pos)
    lvl.lvl = thaw_level!(lvl.lvl, ctx, pos)
    return lvl
end

function trim_level!(lvl::VirtualAtomicLevel, ctx::AbstractCompiler, pos)
    # FIXME: Deallocate atomics?
    posV = ctx(pos)
    idx = freshen(ctx.code, :idx)
    push!(ctx.code.preamble, quote
              resize!($(lvl.ex).atomicsArray, $posV)
          end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, pos)
    lvl
end

function instantiate(fbr::VirtualSubFiber{VirtualAtomicLevel}, ctx, mode::Reader, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    lvl = freshen(ctx.code, lvl.ex, :_lvl)
    sym = freshen(ctx.code, lvl.ex, :after_atomic_lvl)
    return body = Thunk(
        body = (ctx) -> begin
            instantiate(VirtualSubFiber(lvl.lvl, pos), ctx, mode, protos)
        end,
    )
end

function instantiate(fbr::VirtualSubFiber{VirtualAtomicLevel}, ctx, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    lvl = freshen(ctx.code, lvl.ex, :_lvl)
    sym = freshen(ctx.code, lvl.ex, :after_atomic_lvl)
    atomicData = freshen(ctx.code, lvl.ex, :atomicArrays)
    lockVal = freshen(ctx.code, lvl.ex, :lockVal)
    dev = (ctx.task.device)

    return body = Thunk(
        body = (ctx) -> begin
            lvl_2 = lvl.lvl
            push!(ctx.code.preamble, 
            quote
                $atomicData =  promote_val_to_lock($dev, $(lvl.ex).atomicsArray, $(ctx(pos)), eltype($(lvl.AVal)))
                $lock = get_lock($dev, $atomicData) 
            end)
            push!(ctx.code.epilogue,
            quote 
                release_lock($dev, $lock)
            end )
            update = instantiate(VirtualSubFiber(lvl_2, pos), ctx, mode, protos)
            return update
        end
    )
end
function instantiate(fbr::VirtualHollowSubFiber{VirtualAtomicLevel}, ctx, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    lvl = freshen(ctx.code, lvl.ex, :_lvl)
    sym = freshen(ctx.code, lvl.ex, :after_atomic_lvl)
    atomicData = freshen(ctx.code, lvl.ex, :atomicArrays)
    lockVal = freshen(ctx.code, lvl.ex, :lockVal)
    dev = (ctx.task.device)



    return body = Thunk(
        body = (ctx) -> begin
            lvl_2 = lvl.lvl
            push!(ctx.code.preamble, 
            quote
                $atomicData =  promote_val_to_lock($dev, $(lvl.ex).atomicsArray, $(ctx(pos)), eltype($(lvl.AVal)))
                $lock = get_lock($dev, $atomicData) 
            end)
            push!(ctx.code.epilogue,
            quote 
                release_lock($dev, $lock)
            end )
            update = instantiate(VirtualHollowSubFiber(lvl_2, pos, fbr.dirty), ctx, mode, protos)
            return update
        end
    )
end
