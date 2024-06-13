"""
    SparseLevel{[Ti=Int], [Tp=Int], [Ptr, Idx, Val, Tbl=Dict]}(lvl, [dim])

A subfiber of a sparse level does not need to represent slices `A[:, ..., :, i]`
which are entirely [`fill_value`](@ref). Instead, only potentially non-fill
slices are stored as subfibers in `lvl`.  A datastructure specified by Tbl is used to record which
slices are stored. Optionally, `dim` is the size of the last dimension.

`Ti` is the type of the last fiber index, and `Tp` is the type used for
positions in the level. The types `Ptr` and `Idx` are the types of the
arrays used to store positions and indicies.

```jldoctest
julia> Tensor(Dense(Sparse(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
3×3-Tensor
└─ Dense [:,1:3]
   ├─ [:, 1]: Sparse (0.0) [1:3]
   │  ├─ [1]: 10.0
   │  └─ [2]: 30.0
   ├─ [:, 2]: Sparse (0.0) [1:3]
   └─ [:, 3]: Sparse (0.0) [1:3]
      ├─ [1]: 20.0
      └─ [3]: 40.0

julia> Tensor(Sparse(Sparse(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
3×3-Tensor
└─ Sparse (0.0) [:,1:3]
   ├─ [:, 1]: Sparse (0.0) [1:3]
   │  ├─ [1]: 10.0
   │  └─ [2]: 30.0
   └─ [:, 3]: Sparse (0.0) [1:3]
      ├─ [1]: 20.0
      └─ [3]: 40.0

```
"""
struct SparseLevel{Ti, Ptr, Idx, Val, Tbl, Lvl} <: AbstractLevel
    lvl::Lvl
    shape::Ti
    ptr::Ptr
    idx::Idx
    val::Val
    tbl::Tbl
end
const Sparse = SparseLevel
const SparseDict = SparseLevel
SparseLevel(lvl) = SparseLevel{Int}(lvl)
SparseLevel(lvl, shape::Ti) where {Ti} = SparseLevel{Ti}(lvl, shape)
SparseLevel{Ti}(lvl) where {Ti} = SparseLevel{Ti}(lvl, zero(Ti))
SparseLevel{Ti}(lvl, shape) where {Ti} = SparseLevel{Ti}(lvl, shape, postype(lvl)[1], Ti[], postype(lvl)[], Dict{Tuple{postype(lvl), Ti}, postype(lvl)}())

SparseLevel{Ti}(lvl::Lvl, shape, ptr::Ptr, idx::Idx, val::Val, tbl::Tbl) where {Ti, Ptr, Idx, Val, Tbl, Lvl} =
    SparseLevel{Ti, Ptr, Idx, Val, Tbl, Lvl}(lvl, shape, ptr, idx, val, tbl)

Base.summary(lvl::SparseLevel) = "Sparse($(summary(lvl.lvl)))"
similar_level(lvl::SparseLevel, fill_value, eltype::Type, dim, tail...) =
    Sparse(similar_level(lvl.lvl, fill_value, eltype, tail...), dim)

function postype(::Type{SparseLevel{Ti, Ptr, Idx, Val, Tbl, Lvl}}) where {Ti, Ptr, Idx, Val, Tbl, Lvl}
    return postype(Lvl)
end

Base.resize!(lvl::SparseLevel{Ti}, dims...) where {Ti} =
    SparseLevel{Ti}(resize!(lvl.lvl, dims[1:end-1]...), dims[end], lvl.ptr, lvl.idx, lvl.val, lvl.tbl)

function moveto(lvl::SparseLevel{Ti, Ptr, Idx, Val, Tbl, Lvl}, Tm) where {Ti, Ptr, Idx, Val, Tbl, Lvl}
    lvl_2 = moveto(lvl.lvl, Tm)
    tbl_2 = moveto(lvl.tbl, Tm)
    return SparseLevel{Ti}(lvl_2, lvl.shape, tbl_2)
end

function countstored_level(lvl::SparseLevel, pos)
    pos == 0 && return countstored_level(lvl.lvl, pos)
    countstored_level(lvl.lvl, lvl.ptr[pos + 1]  - 1)
end

pattern!(lvl::SparseLevel{Ti}) where {Ti} =
    SparseLevel{Ti}(pattern!(lvl.lvl), lvl.shape, lvl.ptr, lvl.idx, lvl.val, lvl.tbl)

set_fill_value!(lvl::SparseLevel{Ti}, init) where {Ti} =
    SparseLevel{Ti}(set_fill_value!(lvl.lvl, init), lvl.shape, lvl.ptr, lvl.idx, lvl.val, lvl.tbl)

function Base.show(io::IO, lvl::SparseLevel{Ti}) where {Ti}
    if get(io, :compact, false)
        print(io, "Sparse(")
    else
        print(io, "Sparse{$Ti}(")
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
        print(io, ", ")
        show(io, lvl.val)
        print(io, ", ")
        show(io, lvl.tbl)
    end
    print(io, ")")
end

labelled_show(io::IO, fbr::SubFiber{<:SparseLevel}) =
    print(io, "Sparse (", fill_value(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", size(fbr)[end], "]")

function labelled_children(fbr::SubFiber{<:SparseLevel})
    lvl = fbr.lvl
    pos = fbr.pos
    pos + 1 > length(lvl.ptr) && return []
    map(lvl.ptr[pos]:lvl.ptr[pos + 1] - 1) do qos
        LabelledTree(cartesian_label([range_label() for _ = 1:ndims(fbr) - 1]..., lvl.idx[qos]), SubFiber(lvl.lvl, lvl.val[qos]))
    end
end

@inline level_ndims(::Type{<:SparseLevel{Ti, Ptr, Idx, Val, Tbl, Lvl}}) where {Ti, Ptr, Idx, Val, Tbl, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SparseLevel) = (level_size(lvl.lvl)..., lvl.shape)
@inline level_axes(lvl::SparseLevel) = (level_axes(lvl.lvl)..., Base.OneTo(lvl.shape))
@inline level_eltype(::Type{<:SparseLevel{Ti, Ptr, Idx, Val, Tbl, Lvl}}) where {Ti, Ptr, Idx, Val, Tbl, Lvl} = level_eltype(Lvl)
@inline level_fill_value(::Type{<:SparseLevel{Ti, Ptr, Idx, Val, Tbl, Lvl}}) where {Ti, Ptr, Idx, Val, Tbl, Lvl} = level_fill_value(Lvl)
data_rep_level(::Type{<:SparseLevel{Ti, Ptr, Idx, Val, Tbl, Lvl}}) where {Ti, Ptr, Idx, Val, Tbl, Lvl} = SparseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:SparseLevel})() = fbr
function (fbr::SubFiber{<:SparseLevel{Ti}})(idxs...) where {Ti}
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    crds = @view lvl.idx[lvl.ptr[p]:lvl.ptr[p + 1] - 1]
    r = searchsorted(crds, idxs[end])
    q = lvl.ptr[p] + first(r) - 1
    length(r) == 0 ? fill_value(fbr) : SubFiber(lvl.lvl, lvl.val[q])(idxs[1:end-1]...)
end

mutable struct VirtualSparseLevel <: AbstractVirtualLevel
    lvl
    ex
    Ti
    ptr
    idx
    val
    tbl
    shape
    qos_stop
end

is_level_injective(ctx, lvl::VirtualSparseLevel) = [is_level_injective(ctx, lvl.lvl)..., false]
function is_level_atomic(ctx, lvl::VirtualSparseLevel)
    (below, atomic) = is_level_atomic(ctx, lvl.lvl)
    return ([below; [atomic]], atomic)
end
function is_level_concurrent(ctx, lvl::VirtualSparseLevel)
    (data, _) = is_level_concurrent(ctx, lvl.lvl)
    return ([data; [false]], false)
end

function virtualize(ctx, ex, ::Type{SparseLevel{Ti, Ptr, Idx, Val, Tbl, Lvl}}, tag=:lvl) where {Ti, Ptr, Idx, Val, Tbl, Lvl}
    sym = freshen(ctx, tag)
    ptr = freshen(ctx, tag, :_ptr)
    idx = freshen(ctx, tag, :_idx)
    val = freshen(ctx, tag, :_val)
    tbl = freshen(ctx, tag, :_tbl)
    qos_stop = freshen(ctx, tag, :_qos_stop)
    push_preamble!(ctx, quote
        $sym = $ex
        $ptr = $sym.ptr
        $idx = $sym.idx
        $val = $sym.val
        $tbl = $sym.tbl
        $qos_stop = length($tbl)
    end)
    lvl_2 = virtualize(ctx, :($sym.lvl), Lvl, sym)
    shape = value(:($sym.shape), Int)
    VirtualSparseLevel(lvl_2, sym, Ti, ptr, idx, val, tbl, shape, qos_stop)
end
function lower(ctx::AbstractCompiler, lvl::VirtualSparseLevel, ::DefaultStyle)
    quote
        $SparseLevel{$(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
            $(lvl.ptr),
            $(lvl.idx),
            $(lvl.val),
            $(lvl.tbl),
        )
    end
end

Base.summary(lvl::VirtualSparseLevel) = "Sparse($(summary(lvl.lvl)))"

function virtual_level_size(ctx, lvl::VirtualSparseLevel)
    ext = make_extent(lvl.Ti, literal(lvl.Ti(1)), lvl.shape)
    (virtual_level_size(ctx, lvl.lvl)..., ext)
end

function virtual_level_resize!(ctx, lvl::VirtualSparseLevel, dims...)
    lvl.shape = getstop(dims[end])
    lvl.lvl = virtual_level_resize!(ctx, lvl.lvl, dims[1:end-1]...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_fill_value(lvl::VirtualSparseLevel) = virtual_level_fill_value(lvl.lvl)

postype(lvl::VirtualSparseLevel) = postype(lvl.lvl)

function declare_level!(ctx::AbstractCompiler, lvl::VirtualSparseLevel, pos, init)
    #TODO check that init == fill_value
    Ti = lvl.Ti
    Tp = postype(lvl)
    qos = freshen(ctx, tag, :qos)
    push_preamble!(ctx, quote
        resize!($(lvl.ptr), $(ctx(pos)) + $(Tp(1)))
        Finch.fill_range!($(lvl.ptr), 0, $(ctx(pos)) + $(Tp(1)), $(ctx(pos)) + $(Tp(1)))
        empty!($(lvl.tbl))
        $qos = $(Tp(0))
        $(lvl.qos_stop) = 0
    end)
    lvl.lvl = declare_level!(ctx, lvl.lvl, value(qos, Tp), init)
    return lvl
end

function assemble_level!(ctx, lvl::VirtualSparseLevel, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    quote
        Finch.resize_if_smaller!($(lvl.ptr), $(ctx(pos_stop)) + 1)
        Finch.fill_range!($(lvl.ptr), 0, $(ctx(pos_start)) + 1, $(ctx(pos_stop)) + 1)
    end
end

function freeze_level!(ctx::AbstractCompiler, lvl::VirtualSparseLevel, pos_stop)
    p = freshen(ctx, :p)
    pos_stop = cache!(ctx, :pos_stop, simplify(ctx, pos_stop))
    qos_stop = freshen(ctx, :qos_stop)
    p = freshen(ctx, :p)
    i = freshen(ctx, :i)
    q = freshen(ctx, :q)
    v = freshen(ctx, :v)
    push_preamble!(ctx, quote
        srt = sort(collect(pairs($(lvl.tbl))))
        resize!($(lvl.idx), length(srt))
        resize!($(lvl.val), length(srt))
        for q in 1:length(srt)
            ((p, i), v) = srt[q]
            $(lvl.val)[q] = v
            $(lvl.idx)[q] = i
        end
        resize!($(lvl.ptr), $(ctx(pos_stop)) + 1)
        $(lvl.ptr)[1] = 1
        for p = 2:$(ctx(pos_stop)) + 1
            $(lvl.ptr)[p] += $(lvl.ptr)[p - 1]
        end
        $qos_stop = $(lvl.ptr)[$(ctx(pos_stop)) + 1] - 1
    end)
    lvl.lvl = freeze_level!(ctx, lvl.lvl, value(qos_stop))
    return lvl
end

function thaw_level!(ctx::AbstractCompiler, lvl::VirtualSparseLevel, pos_stop)
    p = freshen(ctx, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(ctx, pos_stop)))
    push_preamble!(ctx, quote
        $(lvl.qos_stop) = $(lvl.ptr)[$(ctx(pos_stop)) + 1] - 1
        for p = $(ctx(pos_stop)):-1:1
            $(lvl.ptr)[p + 1] -= $(lvl.ptr)[p]
        end
    end)
    lvl.lvl = thaw_level!(ctx, lvl.lvl, value(lvl.qos_stop))
    return lvl
end

function virtual_moveto_level(ctx::AbstractCompiler, lvl::VirtualSparseLevel, arch)
    ptr_2 = freshen(ctx, lvl.ptr)
    idx_2 = freshen(ctx, lvl.idx)
    push_preamble!(ctx, quote
        $tbl_2 = $(lvl.tbl)
        $(lvl.tbl) = $moveto($(lvl.tbl), $(ctx(arch)))
    end)
    push_epilogue!(ctx, quote
        $(lvl.tbl) = $tbl_2
    end)
    virtual_moveto_level(ctx, lvl.lvl, arch)
end

function instantiate(ctx, fbr::VirtualSubFiber{VirtualSparseLevel}, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    Ti = lvl.Ti
    my_i = freshen(ctx, tag, :_i)
    my_q = freshen(ctx, tag, :_q)
    my_q_stop = freshen(ctx, tag, :_q_stop)
    my_i1 = freshen(ctx, tag, :_i1)
    my_v = freshen(ctx, tag, :_v)

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
                                $my_i = $(lvl.idx)[$my_q]
                            end
                        end,
                        preamble = quote
                            $my_i = $(lvl.idx)[$my_q]
                            $my_v = $(lvl.val)[$my_q]
                        end,
                        stop = (ctx, ext) -> value(my_i),
                        chunk = Spike(
                            body = FillLeaf(virtual_level_fill_value(lvl)),
                            tail = Simplify(instantiate(ctx, VirtualSubFiber(lvl.lvl, value(my_v, Ti)), mode, subprotos))
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

instantiate(ctx, fbr::VirtualSubFiber{VirtualSparseLevel}, mode::Updater, protos) = begin
    instantiate(ctx, VirtualHollowSubFiber(fbr.lvl, fbr.pos, freshen(ctx, :null)), mode, protos)
end
function instantiate(ctx, fbr::VirtualHollowSubFiber{VirtualSparseLevel}, mode::Updater, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    qos = freshen(ctx, tag, :_qos)
    qos_stop = lvl.qos_stop
    dirty = freshen(ctx, tag, :_dirty)
    subtbl = freshen(ctx, tag, :_subtbl)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $subtbl = $(ctx(pos))
            end,
            body = (ctx) -> Lookup(
                body = (ctx, idx) -> Thunk(
                    preamble = quote
                        $qos = get($(lvl.tbl), ($subtbl, $(ctx(idx))), length($(lvl.tbl)) + 1)
                        if $qos > $qos_stop
                            $qos_stop = max($qos_stop << 1, 1)
                            $(contain(ctx_2->assemble_level!(ctx_2, lvl.lvl, value(qos, Tp), value(qos_stop, Tp)), ctx))
                        end
                        $dirty = false
                    end,
                    body = (ctx) -> instantiate(ctx, VirtualHollowSubFiber(lvl.lvl, value(qos, Tp), dirty), mode, subprotos),
                    epilogue = quote
                        if $dirty
                            if $qos > length($(lvl.tbl))
                                $(lvl.tbl)[($subtbl, $(ctx(idx)))] = $qos
                                $(lvl.ptr)[$subtbl + 1] += 1
                            end
                            $(fbr.dirty) = true
                        end
                    end
                )
            ),
        )
    )
end