virtual_level_resize!(lvl::VirtualAtomicLevel, ctx, dims...) = (lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims...); lvl)
virtual_level_size(lvl::VirtualAtomicLevel, ctx) = virtual_level_size(lvl.lvl, ctx)
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

# PLaceholder - things I had not figured out yet
# THough they are pretty obvious

function instantiate(fbr::VirtualSubFiber{VirtualAtomicLevel}, ctx, mode::Reader, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    lvl = freshen(ctx.code, lvl.ex, :_lvl)
    sym = freshen(ctx.code, lvl.ex, :after_atomic_lvl)
    return body = Thunk(
        body = (ctx) -> begin
            lvl_2 = virtualize(:($(lvl.ex).lvl), lvl.Lvl, ctx.code, sym)
            instantiate(VirtualSubFiber(lvl_2, $(ctx(pos))), ctx, mode, protos)
        end,
    )
end

function instantiate(fbr::VirtualSubFiber{VirtualAtomicLevel}, ctx, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    lvl = freshen(ctx.code, lvl.ex, :_lvl)
    sym = freshen(ctx.code, lvl.ex, :after_atomic_lvl)
    atomicData = freshen(ctx.code, lvl.ex, :atomicArrays)
    lockVal = freshen(ctx.code, lvl.ex, :lockVal)
    dev = $(ctx.task.device)

    return body = Thunk(
        body = (ctx) -> begin
            lvl_2 = virtualize(:($(lvl.ex).lvl), lvl.Lvl, ctx.code, sym)
            update = instantiate(VirtualSubFiber(lvl_2, $(ctx(pos))), ctx, mode, protos)
            return quote
                $atomicData = promote_val_to_lock($dev, $(lvl.ex).atomicsArray, $(ctx(pos)), eltype($(lvl.AVal)))
                $lock = get_lock($dev, $atomicData)
                $update
                release_lock($dev, $lock)
            end
        end
    )
end
function instantiate(fbr::VirtualHollowSubFiber{VirtualAtomicLevel}, ctx, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    lvl = freshen(ctx.code, lvl.ex, :_lvl)
    sym = freshen(ctx.code, lvl.ex, :after_atomic_lvl)
    atomicData = freshen(ctx.code, lvl.ex, :atomicArrays)
    lockVal = freshen(ctx.code, lvl.ex, :lockVal)
    dev = $(ctx.task.device)

    return body = Thunk(
        body = (ctx) -> begin
            lvl_2 = virtualize(:($(lvl.ex).lvl), lvl.Lvl, ctx.code, sym)
            update = instantiate(VirtualSubFiber(lvl_2, $(ctx(pos))), ctx, mode, protos)
            return quote
                $atomicData = promote_val_to_lock($dev, $(lvl.ex).atomicsArray, $(ctx(pos)), eltype($(lvl.AVal)))
                $lock = get_lock($dev, $atomicData)
                $update
                release_lock($dev, $lock)
            end
        end
    )
end
