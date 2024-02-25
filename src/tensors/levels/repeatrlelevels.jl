"""
    RepeatRLELevel{[D], [Ti=Int], [Tp=Int], [Tv=typeof(D)]}([dim])

A subfiber of a repeat level is a vector that only stores contiguous repeated
values once. The RepeatRLELevel records locations of repeats using a sorted
list. Optionally, `dim` is the size of the vectors.

The fibers have type `Tv`, initialized to `D`. `D` may optionally be given as
the first argument.  `Ti` is the type of the last tensor index, and `Tp` is the
type used for positions in the level.

```jldoctest
julia> Tensor(RepeatRLE(0.0), [11, 11, 22, 22, 00, 00, 00, 33, 33])
RepeatRLE [1:9]
├─ [1:2]: 11.0
├─ [3:4]: 22.0
├─ [5:7]: 0.0
├─ [8:9]: 33.0
└─ [10:9]: 0.0

```
"""
struct RepeatRLELevel{D, Ti, Tp, Tv, Ptr, Idx, Val} <: AbstractLevel
    shape::Ti
    ptr::Ptr
    idx::Idx
    val::Val
end

const RepeatRLE = RepeatRLELevel
function RepeatRLELevel(d, args...)
    isbits(d) || throw(ArgumentError("Finch currently only supports isbits defaults"))
    RepeatRLELevel{d}(args...)
end
RepeatRLELevel{D}() where {D} = RepeatRLELevel{D, Int}()
RepeatRLELevel{D}(shape::Ti, args...) where {D, Ti} = RepeatRLELevel{D, Ti}(shape, args...)
RepeatRLELevel{D, Ti}(args...) where {D, Ti} = RepeatRLELevel{D, Ti, Int}(args...)
RepeatRLELevel{D, Ti, Tp}(args...) where {D, Ti, Tp} = RepeatRLELevel{D, Ti, Tp, typeof(D)}(args...)
RepeatRLELevel{D, Ti, Tp, Tv}() where {D, Ti, Tp, Tv} = RepeatRLELevel{D, Ti, Tp, Tv}(zero(Ti))

RepeatRLELevel{D, Ti, Tp, Tv}(shape) where {D, Ti, Tp, Tv} = RepeatRLELevel{D, Ti, Tp, Tv}(Ti(shape), Tp[1], Ti[], Tv[])
RepeatRLELevel{D, Ti, Tp, Tv}(shape, ptr::Ptr, idx::Idx, val::Val) where {D, Ti, Tp, Tv, Ptr, Idx, Val} =
    RepeatRLELevel{D, Ti, Tp, Tv, Ptr, Idx, Val}(shape, ptr, idx, val)

Base.summary(::RepeatRLE{D}) where {D} = "RepeatRLE($(D))"
similar_level(::RepeatRLELevel{D}) where {D} = RepeatRLE{D}()
similar_level(::RepeatRLELevel{D}, dim, tail...) where {D} = RepeatRLE{D}(dim)
data_rep_level(::Type{<:RepeatRLELevel{D, Ti, Tp, Tv, Ptr, Idx, Val}}) where {D, Ti, Tp, Tv, Ptr, Idx, Val} = RepeatData(D, Tv)

function postype(::Type{RepeatRLELevel{D, Ti, Tp, Tv, Ptr, Idx, Val}}) where {D, Ti, Tp, Tv, Ptr, Idx, Val}
    return Tp
end

function moveto(lvl::RepeatRLELevel{D, Ti, Tp, Tv, Ptr, Idx, Val}, device) where {D, Ti, Tp, Tv, Ptr, Idx, Val}
    ptr_2 = moveto(lvl.ptr, device)
    idx_2 = moveto(lvl.idx, device)
    val_2 = moveto(lvl.val, device)
    return RepeatRLELevel{D, Ti, Tp}(lvl.shape, ptr_2, idx_2, val_2)
end

countstored_level(lvl::RepeatRLELevel, pos) = lvl.ptr[pos + 1] - 1

pattern!(lvl::RepeatRLELevel{D, Ti}) where {D, Ti} = 
    DenseLevel{Ti}(Pattern(), lvl.shape)

redefault!(lvl::RepeatRLELevel{D, Ti, Tp, Tv, Ptr, Idx, Val}, init) where {D, Ti, Tp, Tv, Ptr, Idx, Val} = 
    RepeatRLELevel{init, Ti, Tp, Tv, Ptr, Idx, Val}(lvl.shape, lvl.ptr, lvl.idx, lvl.val)

Base.resize!(lvl::RepeatRLELevel{D, Ti, Tp, Tv, Ptr, Idx, Val}, dim) where {D, Ti, Tp, Tv, Ptr, Idx, Val} = 
    RepeatRLELevel{D, Ti, Tp, Tv, Ptr, Idx, Val}(dim, lvl.ptr, lvl.idx, lvl.val)

function Base.show(io::IO, lvl::RepeatRLELevel{D, Ti, Tp, Tv, Ptr, Idx, Val}) where {D, Ti, Tp, Tv, Ptr, Idx, Val}
    print(io, "RepeatRLE{")
    print(io, D)
    if get(io, :compact, false)
        print(io, "}(")
    else
        print(io, ", $Ti, $Tp, $Tv}(")
    end

    show(io, lvl.shape)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(io, lvl.ptr)
        print(io, ", ")
        show(io, lvl.idx)
        print(io, ", ")
        show(io, lvl.val)
    end
    print(io, ")")
end

labelled_show(io::IO, fbr::SubFiber{<:RepeatRLELevel}) =
    print(io, "RepeatRLE [", ":,"^(ndims(fbr) - 1), "1:", size(fbr)[end], "]")

function labelled_children(fbr::SubFiber{<:RepeatRLELevel})
    lvl = fbr.lvl
    pos = fbr.pos
    pos + 1 > length(lvl.ptr) && return []
    map(lvl.ptr[pos]:lvl.ptr[pos + 1] - 1) do qos
        LabelledTree(cartesian_label(range_label(qos == lvl.ptr[pos] ? 1 : lvl.idx[qos - 1] + 1, lvl.idx[qos])), lvl.val[qos])
    end
end

@inline level_ndims(::Type{<:RepeatRLELevel}) = 1
@inline level_size(lvl::RepeatRLELevel) = (lvl.shape,)
@inline level_axes(lvl::RepeatRLELevel) = (Base.OneTo(lvl.shape),)
@inline level_eltype(::Type{RepeatRLELevel{D, Ti, Tp, Tv, Ptr, Idx, Val}}) where {D, Ti, Tp, Tv, Ptr, Idx, Val} = Tv
@inline level_default(::Type{<:RepeatRLELevel{D}}) where {D} = D
(fbr::AbstractFiber{<:RepeatRLELevel})() = fbr
(fbr::Tensor{<:RepeatRLELevel})(idx...) = SubFiber(fbr.lvl, 1)(idx...)
function (fbr::SubFiber{<:RepeatRLELevel})(i, tail...)
    lvl = fbr.lvl
    p = fbr.pos
    r = searchsortedfirst(@view(lvl.idx[lvl.ptr[p]:lvl.ptr[p + 1] - 1]), i)
    q = lvl.ptr[p] + r - 1
    return lvl.val[q]
end

mutable struct VirtualRepeatRLELevel <: AbstractVirtualLevel
    ex
    D
    Ti
    Tp
    Tv
    ptr
    idx
    val
    shape
    ros_fill
    qos_stop
    dirty
    prev_pos
end
is_level_injective(::VirtualRepeatRLELevel, ctx) = [false]
is_level_atomic(lvl::VirtualRepeatRLELevel, ctx) = false

function virtualize(ex, ::Type{RepeatRLELevel{D, Ti, Tp, Tv, Ptr, Idx, Val}}, ctx, tag=:lvl) where {D, Ti, Tp, Tv, Ptr, Idx, Val}
    sym = freshen(ctx, tag)
    shape = value(:($sym.shape), Int)
    ros_fill = freshen(ctx, sym, :_ros_fill)
    qos_stop = freshen(ctx, sym, :_qos_stop)
    ptr = freshen(ctx, tag, :_ptr)
    idx = freshen(ctx, tag, :_idx)
    val = freshen(ctx, tag, :_val)
    push!(ctx.preamble, quote
        $sym = $ex
        $ptr = $ex.ptr
        $idx = $ex.idx
        $val = $ex.val
    end)
    dirty = freshen(ctx, sym, :_dirty)
    prev_pos = freshen(ctx, sym, :_prev_pos)
    VirtualRepeatRLELevel(sym, D, Ti, Tp, Tv, ptr, idx, val, shape, ros_fill, qos_stop, dirty, prev_pos)
end
function lower(lvl::VirtualRepeatRLELevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $RepeatRLELevel{$(lvl.D), $(lvl.Ti), $(lvl.Tp), $(lvl.Tv)}(
            $(ctx(lvl.shape)),
            $(lvl.ptr),
            $(lvl.idx),
            $(lvl.val)
        )
    end
end

Base.summary(lvl::VirtualRepeatRLELevel) = "RepeatRLE($(lvl.D))"

function virtual_level_size(lvl::VirtualRepeatRLELevel, ctx)
    ext = Extent(literal(lvl.Ti(1)), lvl.shape)
    (ext,)
end

function virtual_level_resize!(lvl::VirtualRepeatRLELevel, ctx, dim)
    lvl.shape = getstop(dim)
    lvl
end

virtual_level_default(lvl::VirtualRepeatRLELevel) = lvl.D
virtual_level_eltype(lvl::VirtualRepeatRLELevel) = lvl.Tv
postype(lvl::VirtualRepeatRLELevel) = lvl.Tp

function virtual_moveto_level(lvl::VirtualRepeatRLELevel, ctx::AbstractCompiler, arch)
    ptr_2 = freshen(ctx.code, lvl.ptr)
    idx_2 = freshen(ctx.code, lvl.idx)
    val_2 = freshen(ctx.code, lvl.val)
    push!(ctx.code.preamble, quote
        $ptr_2 = $(lvl.ptr)
        $idx_2 = $(lvl.idx)
        $val_2 = $(lvl.val)
        $(lvl.ptr) = $moveto($(lvl.ptr), $(ctx(arch)))
        $(lvl.idx) = $moveto($(lvl.idx), $(ctx(arch)))
        $(lvl.val) = $moveto($(lvl.val), $(ctx(arch)))
    end)
    push!(ctx.code.epilogue, quote
        $(lvl.ptr) = $ptr_2
        $(lvl.idx) = $idx_2
        $(lvl.val) = $val_2
    end)
    virtual_moveto_level(lvl.lvl, ctx, arch)
end

function declare_level!(lvl::VirtualRepeatRLELevel, ctx::AbstractCompiler, mode, init)
    init == literal(lvl.D) || throw(FinchProtocolError("Cannot initialize RepeatRLE Levels to non-default values"))
    Tp = lvl.Tp
    Ti = lvl.Ti
    push!(ctx.code.preamble, quote
        $(lvl.ptr)[1] = $(Tp(1))
        $(lvl.ros_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
    end)
    if issafe(ctx.mode)
        push!(ctx.code.preamble, quote
            $(lvl.prev_pos) = $(Tp(0))
        end)
    end
    return lvl
end

function assemble_level!(lvl::VirtualRepeatRLELevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_stop, pos_stop))
    quote
        Finch.resize_if_smaller!($(lvl.ptr), $pos_stop + 1)
        Finch.fill_range!($(lvl.ptr), 1, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(lvl::VirtualRepeatRLELevel, ctx::AbstractCompiler, pos_stop)
    Tp = lvl.Tp
    Ti = lvl.Ti
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :p_stop, pos_stop))
    qos_stop = lvl.qos_stop
    qos_fill = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        resize!($(lvl.ptr), $pos_stop + 1)
        for $p = 2:($pos_stop + 1)
            $(lvl.ptr)[$p] += $(lvl.ptr)[$p - 1]
        end
        $qos_fill = $(lvl.ptr)[$pos_stop + 1] - 1
        resize!($(lvl.idx), $qos_fill)
        Finch.fill_range!($(lvl.idx), $(ctx(lvl.shape)), $qos_stop + 1, $qos_fill)
        resize!($(lvl.val), $qos_fill)
        Finch.fill_range!($(lvl.val), $(lvl.D), $qos_stop + 1, $qos_fill)
        $qos_stop = $qos_fill
    end)
    return lvl
end

function instantiate(fbr::VirtualSubFiber{VirtualRepeatRLELevel}, ctx, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_i = freshen(ctx.code, tag, :_i)
    my_q = freshen(ctx.code, tag, :_q)
    my_q_stop = freshen(ctx.code, tag, :_q_stop)
    my_i1 = freshen(ctx.code, tag, :_i1)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = (quote
                $my_q = $(lvl.ptr)[$(ctx(pos))]
                $my_q_stop = $(lvl.ptr)[$(ctx(pos)) + $(Tp(1))]
                #TODO I think this if is only ever true
                if $my_q < $my_q_stop
                    $my_i = $(lvl.idx)[$my_q]
                    $my_i1 = $(lvl.idx)[$my_q_stop - $(Tp(1))]
                else
                    $my_i = $(Ti(1))
                    $my_i1 = $(Ti(0))
                end
            end),
            body = (ctx) -> Stepper(
                seek = (ctx, ext) -> quote
                    if $(lvl.idx)[$my_q] < $(ctx(getstart(ext)))
                        $my_q = Finch.scansearch($(lvl.idx), $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                    end
                end,
                preamble = :($my_i = $(lvl.idx)[$my_q]),
                stop = (ctx, ext) -> value(my_i),
                chunk = Run(Fill(value(:($(lvl.val)[$my_q]), lvl.Tv))), #TODO Flesh out fill to assert ndims and handle writes
                next = (ctx, ext) -> :($my_q += $(Tp(1)))
            )
        )
    )
end

instantiate(fbr::VirtualSubFiber{VirtualRepeatRLELevel}, ctx, mode::Updater, protos) = 
    instantiate(VirtualHollowSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, mode, protos)
function instantiate(fbr::VirtualHollowSubFiber{VirtualRepeatRLELevel}, ctx, mode::Updater, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_q = freshen(ctx.code, tag, :_q)
    my_p = freshen(ctx.code, tag, :_p)
    my_v = freshen(ctx.code, tag, :_v)
    D = lvl.D

    my_i_prev = freshen(ctx.code, tag, :_i_prev)
    my_v_prev = freshen(ctx.code, tag, :_v_prev)

    qos_stop = lvl.qos_stop
    ros_fill = lvl.ros_fill
    qos_fill = freshen(ctx.code, tag, :qos_fill)

    function record_run(ctx, stop, v)
        quote
            if $my_q > $qos_stop
                $qos_fill = $qos_stop
                $qos_stop = max($qos_stop << 1, $my_q)
                Finch.resize_if_smaller!($(lvl.idx), $qos_stop)
                Finch.fill_range!($(lvl.idx), $(ctx(lvl.shape)), $qos_fill + 1, $qos_stop)
                Finch.resize_if_smaller!($(lvl.val), $qos_stop)
                Finch.fill_range!($(lvl.val), $(lvl.D), $qos_fill + 1, $qos_stop)
            end
            $(fbr.dirty) = true
            $(lvl.idx)[$my_q] = $(ctx(stop))
            $(lvl.val)[$my_q] = $v
            $my_q += $(Tp(1))
            $(if issafe(ctx.mode)
                quote
                    $(lvl.prev_pos) = $(ctx(pos))
                end
            end)
        end
    end
    
    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_q = $(lvl.ros_fill) + $(ctx(pos))
                $my_i_prev = $(Ti(0))
                $my_v_prev = $D
                $(if issafe(ctx.mode)
                    quote
                        $(lvl.prev_pos) < $(ctx(pos)) || throw(FinchProtocolError("RepeatRLELevels cannot be updated multiple times"))
                    end
                end)
            end,
            body = (ctx) -> AcceptRun(
                body = (ctx, ext) -> Thunk(
                    preamble = quote
                        if $my_v_prev != $D && ($my_i_prev + 1) < $(ctx(getstart(ext)))
                            $(lvl.dirty) = true
                            $(record_run(ctx, my_i_prev, my_v_prev))
                            $my_v_prev = $D
                        end
                        $my_i_prev = $(ctx(getstart(ext))) - $(Ti(1))
                        $my_v = $D
                    end,
                    body = (ctx) -> Fill(value(my_v, lvl.Tv)),
                    epilogue = quote
                        if $my_v_prev != $my_v && $my_i_prev > 0
                            $(record_run(ctx, my_i_prev, my_v_prev))
                        end
                        $my_v_prev = $my_v
                        $my_i_prev = $(ctx(getstop(ext)))
                    end
                )
            ),
            epilogue = quote
                if $my_v_prev != $D
                    if $my_i_prev < $(ctx(lvl.shape))
                        $(record_run(ctx, my_i_prev, my_v_prev))
                    else
                        $(record_run(ctx, lvl.shape, my_v_prev))
                    end
                end
                $(lvl.ptr)[$(ctx(pos)) + $(Tp(1))] += ($my_q - ($(lvl.ros_fill) + $(ctx(pos))))
                $(lvl.ros_fill) += $my_q - ($(lvl.ros_fill) + $(ctx(pos)))
            end
        )
    )
end
