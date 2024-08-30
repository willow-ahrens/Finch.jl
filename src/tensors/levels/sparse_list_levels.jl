"""
    SparseListLevel{[Ti=Int], [Ptr, Idx]}(lvl, [dim])

A subfiber of a sparse level does not need to represent slices `A[:, ..., :, i]`
which are entirely [`fill_value`](@ref). Instead, only potentially non-fill
slices are stored as subfibers in `lvl`.  A sorted list is used to record which
slices are stored. Optionally, `dim` is the size of the last dimension.

`Ti` is the type of the last tensor index, and `Tp` is the type used for
positions in the level. The types `Ptr` and `Idx` are the types of the
arrays used to store positions and indicies.

```jldoctest
julia> Tensor(Dense(SparseList(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
3×3-Tensor
└─ Dense [:,1:3]
   ├─ [:, 1]: SparseList (0.0) [1:3]
   │  ├─ [1]: 10.0
   │  └─ [2]: 30.0
   ├─ [:, 2]: SparseList (0.0) [1:3]
   └─ [:, 3]: SparseList (0.0) [1:3]
      ├─ [1]: 20.0
      └─ [3]: 40.0

julia> Tensor(SparseList(SparseList(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
3×3-Tensor
└─ SparseList (0.0) [:,1:3]
   ├─ [:, 1]: SparseList (0.0) [1:3]
   │  ├─ [1]: 10.0
   │  └─ [2]: 30.0
   └─ [:, 3]: SparseList (0.0) [1:3]
      ├─ [1]: 20.0
      └─ [3]: 40.0

```
"""
struct SparseListLevel{Ti, Ptr, Idx, Lvl} <: AbstractLevel
    lvl::Lvl
    shape::Ti
    ptr::Ptr
    idx::Idx
end
const SparseList = SparseListLevel
SparseListLevel(lvl) = SparseListLevel{Int}(lvl)
SparseListLevel(lvl, shape::Ti) where {Ti} = SparseListLevel{Ti}(lvl, shape)
SparseListLevel{Ti}(lvl) where {Ti} = SparseListLevel{Ti}(lvl, zero(Ti))
SparseListLevel{Ti}(lvl, shape) where {Ti} = SparseListLevel{Ti}(lvl, shape, postype(lvl)[1], Ti[])

SparseListLevel{Ti}(lvl::Lvl, shape, ptr::Ptr, idx::Idx) where {Ti, Lvl, Ptr, Idx} =
    SparseListLevel{Ti, Ptr, Idx, Lvl}(lvl, shape, ptr, idx)

Base.summary(lvl::SparseListLevel) = "SparseList($(summary(lvl.lvl)))"
similar_level(lvl::SparseListLevel, fill_value, eltype::Type, dim, tail...) =
    SparseList(similar_level(lvl.lvl, fill_value, eltype, tail...), dim)

function postype(::Type{SparseListLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl}
    return postype(Lvl)
end

function moveto(lvl::SparseListLevel{Ti, Ptr, Idx, Lvl}, Tm) where {Ti, Ptr, Idx, Lvl}
    lvl_2 = moveto(lvl.lvl, Tm)
    ptr_2 = moveto(lvl.ptr, Tm)
    idx_2 = moveto(lvl.idx, Tm)
    return SparseListLevel{Ti}(lvl_2, lvl.shape, ptr_2, idx_2)
end

function countstored_level(lvl::SparseListLevel, pos)
    countstored_level(lvl.lvl, lvl.ptr[pos + 1] - 1)
end

pattern!(lvl::SparseListLevel{Ti}) where {Ti} =
    SparseListLevel{Ti}(pattern!(lvl.lvl), lvl.shape, lvl.ptr, lvl.idx)

set_fill_value!(lvl::SparseListLevel{Ti}, init) where {Ti} =
    SparseListLevel{Ti}(set_fill_value!(lvl.lvl, init), lvl.shape, lvl.ptr, lvl.idx)

Base.resize!(lvl::SparseListLevel{Ti}, dims...) where {Ti} =
    SparseListLevel{Ti}(resize!(lvl.lvl, dims[1:end-1]...), dims[end], lvl.ptr, lvl.idx)

function Base.show(io::IO, lvl::SparseListLevel{Ti, Ptr, Idx, Lvl}) where {Ti, Lvl, Idx, Ptr}
    if get(io, :compact, false)
        print(io, "SparseList(")
    else
        print(io, "SparseList{$Ti}(")
    end
    show(io, lvl.lvl)
    print(io, ", ")
    show(IOContext(io, :typeinfo=>Ti), lvl.shape)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(io, lvl.ptr)
        print(io, ", ")
        show(io, lvl.idx)
    end
    print(io, ")")
end

labelled_show(io::IO, fbr::SubFiber{<:SparseListLevel}) =
    print(io, "SparseList (", fill_value(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", size(fbr)[end], "]")

function labelled_children(fbr::SubFiber{<:SparseListLevel})
    lvl = fbr.lvl
    pos = fbr.pos
    pos + 1 > length(lvl.ptr) && return []
    map(lvl.ptr[pos]:lvl.ptr[pos + 1] - 1) do qos
        LabelledTree(cartesian_label([range_label() for _ = 1:ndims(fbr) - 1]..., lvl.idx[qos]), SubFiber(lvl.lvl, qos))
    end
end

@inline level_ndims(::Type{<:SparseListLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SparseListLevel) = (level_size(lvl.lvl)..., lvl.shape)
@inline level_axes(lvl::SparseListLevel) = (level_axes(lvl.lvl)..., Base.OneTo(lvl.shape))
@inline level_eltype(::Type{<:SparseListLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = level_eltype(Lvl)
@inline level_fill_value(::Type{<:SparseListLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = level_fill_value(Lvl)
data_rep_level(::Type{<:SparseListLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = SparseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:SparseListLevel})() = fbr
function (fbr::SubFiber{<:SparseListLevel{Ti}})(idxs...) where {Ti}
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    r = searchsorted(@view(lvl.idx[lvl.ptr[p]:lvl.ptr[p + 1] - 1]), idxs[end])
    q = lvl.ptr[p] + first(r) - 1
    fbr_2 = SubFiber(lvl.lvl, q)
    length(r) == 0 ? fill_value(fbr_2) : fbr_2(idxs[1:end-1]...)
end

mutable struct VirtualSparseListLevel <: AbstractVirtualLevel
    lvl
    ex
    Ti
    ptr
    idx
    shape
    qos_fill
    qos_stop
    prev_pos
end

is_level_injective(ctx, lvl::VirtualSparseListLevel) = [is_level_injective(ctx, lvl.lvl)..., false]
function is_level_atomic(ctx, lvl::VirtualSparseListLevel)
    (below, atomic) = is_level_atomic(ctx, lvl.lvl)
    return ([below; [atomic]], atomic)
end
function is_level_concurrent(ctx, lvl::VirtualSparseListLevel)
    (data, _) = is_level_concurrent(ctx, lvl.lvl)
    return ([data; [false]], false)
end

function virtualize(ctx, ex, ::Type{SparseListLevel{Ti, Ptr, Idx, Lvl}}, tag=:lvl) where {Ti, Ptr, Idx, Lvl}
    sym = freshen(ctx, tag)
    ptr = freshen(ctx, tag, :_ptr)
    idx = freshen(ctx, tag, :_idx)
    push_preamble!(ctx, quote
        $sym = $ex
        $ptr = $sym.ptr
        $idx = $sym.idx
    end)
    lvl_2 = virtualize(ctx, :($sym.lvl), Lvl, sym)
    shape = value(:($sym.shape), Int)
    qos_fill = freshen(ctx, sym, :_qos_fill)
    qos_stop = freshen(ctx, sym, :_qos_stop)
    prev_pos = freshen(ctx, sym, :_prev_pos)
    VirtualSparseListLevel(lvl_2, sym, Ti, ptr, idx, shape, qos_fill, qos_stop, prev_pos)
end
function lower(ctx::AbstractCompiler, lvl::VirtualSparseListLevel, ::DefaultStyle)
    quote
        $SparseListLevel{$(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
            $(lvl.ptr),
            $(lvl.idx),
        )
    end
end

Base.summary(lvl::VirtualSparseListLevel) = "SparseList($(summary(lvl.lvl)))"

function virtual_level_size(ctx, lvl::VirtualSparseListLevel)
    ext = make_extent(lvl.Ti, literal(lvl.Ti(1)), lvl.shape)
    (virtual_level_size(ctx, lvl.lvl)..., ext)
end

function virtual_level_resize!(ctx, lvl::VirtualSparseListLevel, dims...)
    lvl.shape = getstop(dims[end])
    lvl.lvl = virtual_level_resize!(ctx, lvl.lvl, dims[1:end-1]...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseListLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_fill_value(lvl::VirtualSparseListLevel) = virtual_level_fill_value(lvl.lvl)

postype(lvl::VirtualSparseListLevel) = postype(lvl.lvl)

function declare_level!(ctx::AbstractCompiler, lvl::VirtualSparseListLevel, pos, init)
    #TODO check that init == fill_value
    Ti = lvl.Ti
    Tp = postype(lvl)
    push_preamble!(ctx, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
    end)
    if issafe(get_mode_flag(ctx))
        push_preamble!(ctx, quote
            $(lvl.prev_pos) = $(Tp(0))
        end)
    end
    lvl.lvl = declare_level!(ctx, lvl.lvl, literal(Tp(0)), init)
    return lvl
end

function assemble_level!(ctx, lvl::VirtualSparseListLevel, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        Finch.resize_if_smaller!($(lvl.ptr), $pos_stop + 1)
        Finch.fill_range!($(lvl.ptr), 0, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(ctx::AbstractCompiler, lvl::VirtualSparseListLevel, pos_stop)
    p = freshen(ctx, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(ctx, pos_stop)))
    qos_stop = freshen(ctx, :qos_stop)
    push_preamble!(ctx, quote
        resize!($(lvl.ptr), $pos_stop + 1)
        for $p = 1:$pos_stop
            $(lvl.ptr)[$p + 1] += $(lvl.ptr)[$p]
        end
        $qos_stop = $(lvl.ptr)[$pos_stop + 1] - 1
        resize!($(lvl.idx), $qos_stop)
    end)
    lvl.lvl = freeze_level!(ctx, lvl.lvl, value(qos_stop))
    return lvl
end

function thaw_level!(ctx::AbstractCompiler, lvl::VirtualSparseListLevel, pos_stop)
    p = freshen(ctx, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(ctx, pos_stop)))
    qos_stop = freshen(ctx, :qos_stop)
    push_preamble!(ctx, quote
        $(lvl.qos_fill) = $(lvl.ptr)[$pos_stop + 1] - 1
        $(lvl.qos_stop) = $(lvl.qos_fill)
        $qos_stop = $(lvl.qos_fill)
        $(if issafe(get_mode_flag(ctx))
            quote
                $(lvl.prev_pos) = Finch.scansearch($(lvl.ptr), $(lvl.qos_stop) + 1, 1, $pos_stop) - 1
            end
        end)
        for $p = $pos_stop:-1:1
            $(lvl.ptr)[$p + 1] -= $(lvl.ptr)[$p]
        end
    end)
    lvl.lvl = thaw_level!(ctx, lvl.lvl, value(qos_stop))
    return lvl
end

function virtual_moveto_level(ctx::AbstractCompiler, lvl::VirtualSparseListLevel, arch)
    ptr_2 = freshen(ctx, lvl.ptr)
    idx_2 = freshen(ctx, lvl.idx)
    push_preamble!(ctx, quote
        $ptr_2 = $(lvl.ptr)
        $idx_2 = $(lvl.idx)
        $(lvl.ptr) = $moveto($(lvl.ptr), $(ctx(arch)))
        $(lvl.idx) = $moveto($(lvl.idx), $(ctx(arch)))
    end)
    push_epilogue!(ctx, quote
        $(lvl.ptr) = $ptr_2
        $(lvl.idx) = $idx_2
    end)
    virtual_moveto_level(ctx, lvl.lvl, arch)
end

function instantiate(ctx, fbr::VirtualSubFiber{VirtualSparseListLevel}, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    Ti = lvl.Ti
    my_i = freshen(ctx, tag, :_i)
    my_q = freshen(ctx, tag, :_q)
    my_q_stop = freshen(ctx, tag, :_q_stop)
    my_i1 = freshen(ctx, tag, :_i1)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_q = $(lvl.ptr)[$(ctx(pos))]
                $my_q_stop = $(lvl.ptr)[$(ctx(pos)) + $(Tp(1))]
                if $my_q < $my_q_stop
                    $my_i = $(lvl.idx)[$my_q]
                    $my_i1 = $(lvl.idx)[$my_q_stop - $(Tp(1))]
                else
                    $my_i = $(Ti(1))
                    $my_i1 = $(Ti(0))
                end
            end,
            body = (ctx) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> value(my_i1),
                    body = (ctx, ext) -> Stepper(
                        seek = (ctx, ext) -> quote
                            if $(lvl.idx)[$my_q] < $(ctx(getstart(ext)))
                                $my_q = Finch.scansearch($(lvl.idx), $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                            end
                        end,
                        preamble = :($my_i = $(lvl.idx)[$my_q]),
                        stop = (ctx, ext) -> value(my_i),
                        chunk = Spike(
                            body = FillLeaf(virtual_level_fill_value(lvl)),
                            tail = Simplify(instantiate(ctx, VirtualSubFiber(lvl.lvl, value(my_q, Ti)), mode, subprotos))
                        ),
                        next = (ctx, ext) -> :($my_q += $(Tp(1)))
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Run(FillLeaf(virtual_level_fill_value(lvl)))
                )
            ])
        )
    )
end


function instantiate(ctx, fbr::VirtualSubFiber{VirtualSparseListLevel}, mode::Reader, subprotos, ::typeof(follow))
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    my_q = freshen(ctx, tag, :_q)
    my_q_stop = freshen(ctx, tag, :_q_stop)
    my_qos = freshen(ctx, tag, :_qos)
    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_q = $(lvl.ptr)[$(ctx(pos))]
            end,
            body = (ctx) -> Lookup(
                body = (ctx, i) -> Thunk(
                    preamble = quote
                        $my_q = max($my_q, $(lvl.ptr)[$(ctx(pos))])
                        $my_q_stop = $(lvl.ptr)[$(ctx(pos)) + $(Tp(1))]
                        $my_qos = scansearch($(lvl.idx), $(ctx(i)), $my_q, $my_q_stop-1)
                        $my_q = min($my_q_stop-1, $my_qos)
                    end,
                    body = (ctx) -> Switch([
                        value(:($my_qos < $my_q_stop && $(lvl.idx)[$my_qos] == $(ctx(i)))) => instantiate(ctx, VirtualSubFiber(lvl.lvl, value(my_qos, Tp)), mode, subprotos),
                        literal(true) => FillLeaf(virtual_level_fill_value(lvl))
                    ])
                )
            )
        )
    )
end

function instantiate(ctx, fbr::VirtualSubFiber{VirtualSparseListLevel}, mode::Reader, subprotos, ::typeof(gallop))
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    Ti = lvl.Ti
    my_i = freshen(ctx, tag, :_i)
    my_q = freshen(ctx, tag, :_q)
    my_q_stop = freshen(ctx, tag, :_q_stop)
    my_i1 = freshen(ctx, tag, :_i1)
    my_i2 = freshen(ctx, tag, :_i2)
    my_i3 = freshen(ctx, tag, :_i3)
    my_i4 = freshen(ctx, tag, :_i4)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_q = $(lvl.ptr)[$(ctx(pos))]
                $my_q_stop = $(lvl.ptr)[$(ctx(pos)) + 1]
                if $my_q < $my_q_stop
                    $my_i = $(lvl.idx)[$my_q]
                    $my_i1 = $(lvl.idx)[$my_q_stop - $(Tp(1))]
                else
                    $my_i = $(Ti(1))
                    $my_i1 = $(Ti(0))
                end
            end,
            body = (ctx) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> value(my_i1),
                    body = (ctx, ext) -> Jumper(
                        seek = (ctx, ext) -> quote
                            if $(lvl.idx)[$my_q] < $(ctx(getstart(ext)))
                                $my_q = Finch.scansearch($(lvl.idx), $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                            end
                        end,
                        preamble = :($my_i2 = $(lvl.idx)[$my_q]),
                        stop = (ctx, ext) -> value(my_i2),
                        chunk =  Spike(
                            body = FillLeaf(virtual_level_fill_value(lvl)),
                            tail = instantiate(ctx, VirtualSubFiber(lvl.lvl, value(my_q, Ti)), mode, subprotos),
                        ),
                        next = (ctx, ext) -> :($my_q += $(Tp(1))),
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Run(FillLeaf(virtual_level_fill_value(lvl)))
                )
            ])
        )
    )
end

instantiate(ctx, fbr::VirtualSubFiber{VirtualSparseListLevel}, mode::Updater, protos) = begin
    instantiate(ctx, VirtualHollowSubFiber(fbr.lvl, fbr.pos, freshen(ctx, :null)), mode, protos)
end
function instantiate(ctx, fbr::VirtualHollowSubFiber{VirtualSparseListLevel}, mode::Updater, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    qos = freshen(ctx, tag, :_qos)
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    dirty = freshen(ctx, tag, :dirty)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $qos = $qos_fill + 1
                $(if issafe(get_mode_flag(ctx))
                    quote
                        $(lvl.prev_pos) < $(ctx(pos)) || throw(FinchProtocolError("SparseListLevels cannot be updated multiple times"))
                    end
                end)
            end,
            body = (ctx) -> Lookup(
                body = (ctx, idx) -> Thunk(
                    preamble = quote
                        if $qos > $qos_stop
                            $qos_stop = max($qos_stop << 1, 1)
                            Finch.resize_if_smaller!($(lvl.idx), $qos_stop)
                            $(contain(ctx_2->assemble_level!(ctx_2, lvl.lvl, value(qos, Tp), value(qos_stop, Tp)), ctx))
                        end
                        $dirty = false
                    end,
                    body = (ctx) -> instantiate(ctx, VirtualHollowSubFiber(lvl.lvl, value(qos, Tp), dirty), mode, subprotos),
                    epilogue = quote
                        if $dirty
                            $(fbr.dirty) = true
                            $(lvl.idx)[$qos] = $(ctx(idx))
                            $qos += $(Tp(1))
                            $(if issafe(get_mode_flag(ctx))
                                quote
                                    $(lvl.prev_pos) = $(ctx(pos))
                                end
                            end)
                        end
                    end
                )
            ),
            epilogue = quote
                $(lvl.ptr)[$(ctx(pos)) + 1] += $qos - $qos_fill - 1
                $qos_fill = $qos - 1
            end
        )
    )
end
