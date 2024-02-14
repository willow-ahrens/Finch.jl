
"""
    AtomicLevel{Val, Lvl}()

Atomic Level Protects the level directly below it with atomics

Each position in the level below the atomic level is protected by an atomic.
```jldoctest
julia> Tensor(Dense(Atomic(Element(0.0))), [1, 2, 3])
Dense [1:3]
├─[1]: Atomic -> 1.0
├─[2]: Atomic -> 2.0
├─[3]: Atomic -> 3.0
```
"""

struct AtomicLevel{AVal <: AbstractVector, Lvl} <: AbstractLevel
    lvl::Lvl
    locks::AVal
end
const Atomic = AtomicLevel


AtomicLevel(lvl::Lvl) where {Lvl} = AtomicLevel{Vector{Base.Threads.SpinLock}, Lvl}(lvl, Vector{Base.Threads.SpinLock}([]))
# AtomicLevel{AVal, Lvl}(atomics::AVal, lvl::Lvl) where {Lvl, AVal} =  AtomicLevel{AVal, Lvl}(lvl, atomics)
Base.summary(::AtomicLevel{AVal, Lvl}) where {Lvl, AVal} = "AtomicLevel($(AVal), $(Lvl))"

similar_level(lvl::Atomic{AVal, Lvl}) where {Lvl, AVal} = AtomicLevel{AVal, Lvl}(similar_level(lvl.lvl))

postype(::Type{<:AtomicLevel{AVal, Lvl}}) where {Lvl, AVal} = postype(Lvl)

function moveto(lvl::AtomicLevel, device)
    lvl_2 = moveto(lvl.lvl, device)
    locks_2 = moveto(lvl.locks, device)
    return AtomicLevel(lvl_2, locks_2)
end

pattern!(lvl::AtomicLevel) = AtomicLevel(pattern!(lvl.lvl), lvl.locks)
redefault!(lvl::AtomicLevel, init) = AtomicLevel(redefault!(lvl.lvl, init), lvl.locks)
# TODO: FIXME: Need toa dopt the number of dims
Base.resize!(lvl::AtomicLevel, dims...) = AtomicLevel(resize!(lvl.lvl, dims...), lvl.locks)


function Base.show(io::IO, lvl::AtomicLevel{AVal, Lvl}) where {AVal, Lvl}
    print(io, "Atomic(")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>AVal), lvl.locks)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Val), lvl.lvl)
    end
    print(io, ")")
end 

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:AtomicLevel}, depth)
    p = fbr.pos
    lvl = fbr.lvl
    if p > length(lvl.locks)
        print(io, "Atomic -> undef")
        return
    end
    print(io, "Atomic -> ")
    display_fiber(io, mime, SubFiber(lvl.lvl, p), depth)
end

function Base.show(io::IO, node::LabelledFiberTree{<:SubFiber{<:AtomicLevel}})
    node.print_key(io)
    fbr = node.fbr
    print(io, "Atomic -> ")
end

function AbstractTrees.children(node::LabelledFiberTree{<:SubFiber{<:AtomicLevel}})
    fbr = node.fbr
    lvl = fbr.lvl
    pos = fbr.pos
    [LabelledFiberTree(SubFiber(lvl.lvl, pos)) do io
    end]
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
    locks
    Tv
    Val
    AVal
    Lvl
end
postype(lvl:: AtomicLevel) = postype(lvl.lvl)

postype(lvl:: VirtualAtomicLevel) = postype(lvl.lvl)

is_level_injective(lvl::VirtualAtomicLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., true]
is_level_concurrent(lvl::VirtualAtomicLevel, ctx) = [is_level_concurrent(lvl.lvl, ctx)..., true]
is_level_atomic(lvl::VirtualAtomicLevel, ctx) = true

function lower(lvl::VirtualAtomicLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $AtomicLevel{$(lvl.AVal), $(lvl.Lvl)}($(ctx(lvl.lvl)), $(lvl.locks))
    end
end

function virtualize(ex, ::Type{AtomicLevel{AVal, Lvl}}, ctx, tag=:lvl) where {AVal, Lvl}
    sym = freshen(ctx, tag)
    atomics = freshen(ctx, tag, :_locks)
    push!(ctx.preamble, quote
            $sym = $ex
            $atomics = $ex.locks
        end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    temp = VirtualAtomicLevel(lvl_2, sym, atomics, typeof(level_default(Lvl)), Val, AVal, Lvl)
    temp
end

Base.summary(lvl::VirtualAtomicLevel) = "Atomic($(lvl.Lvl))"
virtual_level_resize!(lvl::VirtualAtomicLevel, ctx, dims...) = (lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims...); lvl)
virtual_level_size(lvl::VirtualAtomicLevel, ctx) = virtual_level_size(lvl.lvl, ctx)
virtual_level_size(x, ctx) = error(string("Not defined for", x))
virtual_level_eltype(lvl::VirtualAtomicLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualAtomicLevel) = virtual_level_default(lvl.lvl)

function declare_level!(lvl::VirtualAtomicLevel, ctx, pos, init)
    lvl.lvl = declare_level!(lvl.lvl, ctx, pos, init)
    return lvl
end

function assemble_level!(lvl::VirtualAtomicLevel, ctx, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(pos_start, ctx))
    pos_stop = cache!(ctx, :pos_stop, simplify(pos_stop, ctx))
    idx = freshen(ctx.code, :idx)
    lockVal = freshen(ctx.code, :lock)
    push!(ctx.code.preamble, quote 
              Finch.resize_if_smaller!($(lvl.locks), $(ctx(pos_stop))) 
              @inbounds for $idx = $(ctx(pos_start)):$(ctx(pos_stop))
                $(lvl.locks)[$idx] = make_lock(eltype($(lvl.AVal)))
              end
          end)
    assemble_level!(lvl.lvl, ctx, pos_start, pos_stop)
end

supports_reassembly(lvl::VirtualAtomicLevel) = supports_reassembly(lvl.lvl)
function reassemble_level!(lvl::VirtualAtomicLevel, ctx, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(pos_start, ctx))
    pos_stop = cache!(ctx, :pos_stop, simplify(pos_stop, ctx))
    idx = freshen(ctx.code, :idx)
    lockVal = freshen(ctx.code, :lock)
    push!(ctx.code.preamble, quote 
              Finch.resize_if_smaller!($lvl.locks, $(ctx(pos_stop))) 
              @inbounds for $idx = $(ctx(pos_start)):$(ctx(pos_stop))
                $lvl.locks[$idx] = Finch.make_lock(eltype($(lvl.AVal)))
              end
          end)
    reassemble_level!(lvl.lvl, ctx, pos_start, pos_stop)
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
              resize!($(lvl.locks), $posV)
          end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, pos)
    lvl
end

function virtual_moveto_level(lvl::VirtualAtomicLevel, ctx::AbstractCompiler, arch)
    #Add for seperation level too.
    atomics = freshen(ctx.code, :locksArray)

    push!(ctx.code.preamble, quote
        $atomics = $(lvl.locks)
        $(lvl.locks) = $moveto($(lvl.locks), $(ctx(arch)))
    end)
    push!(ctx.code.epilogue, quote
        $(lvl.locks) = $atomics
    end)
    virtual_moveto_level(lvl.lvl, ctx, arch)
end

function instantiate(fbr::VirtualSubFiber{VirtualAtomicLevel}, ctx, mode::Reader, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    # lvlp = freshen(ctx.code, lvl.ex, :_lvl)
    # sym = freshen(ctx.code, lvl.ex, :_after_atomic_lvl)
    return body = Thunk(
        body = (ctx) -> begin
            instantiate(VirtualSubFiber(lvl.lvl, pos), ctx, mode, protos)
        end,
    )
end

function instantiate(fbr::VirtualSubFiber{VirtualAtomicLevel}, ctx, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    sym = freshen(ctx.code, lvl.ex, :after_atomic_lvl)
    atomicData = freshen(ctx.code, lvl.ex, :atomicArraysAcc)
    lockVal = freshen(ctx.code, lvl.ex, :lockVal) 
    dev = lower(virtual_get_device(ctx.code.task), ctx, DefaultStyle())
    return Thunk(
        preamble = quote  
            $atomicData =  get_lock($dev, $(lvl.locks), $(ctx(pos)), eltype($(lvl.AVal)))
            $lockVal = aquire_lock!($dev, $atomicData)
        end,
        body =  (ctx) -> begin
            lvl_2 = lvl.lvl
            update = instantiate(VirtualSubFiber(lvl_2, pos), ctx, mode, protos)
            return update
        end,
        epilogue = quote 
            release_lock!($dev, $atomicData) end 
    )
end
function instantiate(fbr::VirtualHollowSubFiber{VirtualAtomicLevel}, ctx, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    sym = freshen(ctx.code, lvl.ex, :after_atomic_lvl)
    atomicData = freshen(ctx.code, lvl.ex, :atomicArrays)
    lockVal = freshen(ctx.code, lvl.ex, :lockVal)
    dev = lower(virtual_get_device(ctx.code.task), ctx, DefaultStyle())
    return Thunk(
        preamble = quote  
            $atomicData =  get_lock($dev, $(lvl.locks), $(ctx(pos)), eltype($(lvl.AVal)))
            $lockVal = aquire_lock!($dev, $atomicData)
        end,
        body =  (ctx) -> begin
            lvl_2 = lvl.lvl
            update = instantiate(VirtualHollowSubFiber(lvl_2, pos, fbr.dirty), ctx, mode, protos)
            return update
        end,
        epilogue = quote 
            release_lock!($dev, $atomicData) end 
    )
end