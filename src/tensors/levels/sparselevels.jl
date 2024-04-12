struct DictTable{Ti, Tp, Ptr, Idx, Val, Tbl}
    ptr::Ptr
    idx::Idx
    val::Val
    tbl::Tbl
end

Base.:(==)(a::DictTable, b::DictTable) = 
    a.ptr == b.ptr &&
    a.idx == b.idx &&
    a.val == b.val &&
    a.tbl == b.tbl

DictTable{Ti, Tp}() where {Ti, Tp} =
    DictTable{Ti, Tp}(Tp[1], Ti[], Tp[], Dict{Tuple{Tp, Ti}, Tp}())
DictTable{Ti, Tp}(ptr::Ptr, idx::Idx, val::Val, tbl::Tbl) where {Ti, Tp, Ptr, Idx, Val, Tbl} =
    DictTable{Ti, Tp, Ptr, Idx, Val, Tbl}(ptr, idx, val, tbl)

function table_coords(tbl::DictTable{Ti, Tp}, pos) where {Ti, Tp}
    @view tbl.idx[tbl.ptr[pos]:tbl.ptr[pos + 1] - 1]
end

function declare_table!(tbl::DictTable{Ti, Tp}, pos) where {Ti, Tp}
    resize!(tbl.ptr, pos + Tp(1))
    fill_range!(tbl.ptr, 0, pos + Tp(1), pos + Tp(1))
    empty!(tbl.tbl)
    return Tp(0)
end

function assemble_table!(tbl::DictTable, pos_start, pos_stop)
    resize_if_smaller!(tbl.ptr, pos_stop + 1)
    fill_range!(tbl.ptr, 0, pos_start + 1, pos_stop + 1)
end

function freeze_table!(tbl::DictTable, pos_stop)
    srt = sort(collect(pairs(tbl.tbl)))
    resize!(tbl.idx, length(srt))
    resize!(tbl.val, length(srt))
    for (q, ((p, i), v)) in enumerate(srt)
        tbl.val[q] = v
        tbl.idx[q] = i
    end
    resize!(tbl.ptr, pos_stop + 1)
    tbl.ptr[1] = 1
    for p = 2:pos_stop + 1
        tbl.ptr[p] += tbl.ptr[p - 1]
    end
    tbl.ptr[pos_stop + 1] - 1
end

function thaw_table!(tbl::DictTable, pos_stop)
    qos_stop = tbl.ptr[pos_stop + 1] - 1
    for p = pos_stop:-1:1
        tbl.ptr[p + 1] -= tbl.ptr[p]
    end
    qos_stop
end

function table_length(tbl::DictTable)
    return length(tbl.ptr) - 1
end

function moveto(tbl::DictTable, arch)
    error(
        "The table type $(typeof(tbl)) does not support moveto. ",
        "Please use a table type that supports moveto."
    )
end

table_isdefined(tbl::DictTable{Ti, Tp}, p) where {Ti, Tp} = p + 1 <= length(tbl.ptr)

table_pos(tbl::DictTable{Ti, Tp}, p) where {Ti, Tp} = tbl.ptr[p + 1]

table_query(tbl::DictTable{Ti, Tp}, p) where {Ti, Tp} = (p, tbl.ptr[p], tbl.ptr[p + 1])

subtable_init(tbl::DictTable{Ti}, (p, start, stop)) where {Ti} = start < stop ? (tbl.idx[start], tbl.idx[stop - 1], start) : (Ti(1), Ti(0), start)

subtable_next(tbl::DictTable, (p, start, stop), q) = q + 1

subtable_get(tbl::DictTable, (p, start, stop), q) = (tbl.idx[q], tbl.val[q])

function subtable_seek(tbl, subtbl, state, i, j)
    while i < j
        state = subtable_next(tbl, subtbl, state)
        (i, q) = subtable_get(tbl, subtbl, state)
    end
    return (i, state)
end

function subtable_seek(tbl::DictTable, (p, start, stop), q, i, j)
    q = Finch.scansearch(tbl.idx, j, q, stop - 1)
    return (tbl.idx[q], q)
end

function table_register(tbl::DictTable, pos)
    pos
end

function table_commit(tbl::DictTable, pos)
end

function subtable_register(tbl::DictTable, pos, idx)
    return get(tbl.tbl, (pos, idx), length(tbl.tbl) + 1)
end

function subtable_commit(tbl::DictTable, pos, qos, idx)
    if qos > length(tbl.tbl)
        tbl.tbl[(pos, idx)] = qos
        tbl.ptr[pos + 1] += 1
    end
end

"""
    SparseLevel{[Ti=Int], [Tp=Int], [Tbl=TreeTable]}(lvl, [dim])

A subfiber of a sparse level does not need to represent slices `A[:, ..., :, i]`
which are entirely [`default`](@ref). Instead, only potentially non-default
slices are stored as subfibers in `lvl`.  A datastructure specified by Tbl is used to record which
slices are stored. Optionally, `dim` is the size of the last dimension.

`Ti` is the type of the last fiber index, and `Tp` is the type used for
positions in the level. The types `Ptr` and `Idx` are the types of the
arrays used to store positions and indicies. 

```jldoctest
julia> Tensor(Dense(Sparse(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
Dense [:,1:3]
├─ [:, 1]: Sparse (0.0) [1:3]
│  ├─ [1]: 10.0
│  └─ [2]: 30.0
├─ [:, 2]: Sparse (0.0) [1:3]
└─ [:, 3]: Sparse (0.0) [1:3]
   ├─ [1]: 20.0
   └─ [3]: 40.0

julia> Tensor(Sparse(Sparse(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
Sparse (0.0) [:,1:3]
├─ [:, 1]: Sparse (0.0) [1:3]
│  ├─ [1]: 10.0
│  └─ [2]: 30.0
└─ [:, 3]: Sparse (0.0) [1:3]
   ├─ [1]: 20.0
   └─ [3]: 40.0

```
"""
struct SparseLevel{Ti, Tbl, Lvl} <: AbstractLevel
    lvl::Lvl
    shape::Ti
    tbl::Tbl
end
const Sparse = SparseLevel
const SparseDict = SparseLevel
SparseLevel(lvl) = SparseLevel{Int}(lvl)
SparseLevel(lvl, shape::Ti) where {Ti} = SparseLevel{Ti}(lvl, shape)
SparseLevel{Ti}(lvl) where {Ti} = SparseLevel{Ti}(lvl, zero(Ti))
SparseLevel{Ti}(lvl, shape) where {Ti} = SparseLevel{Ti}(lvl, shape, DictTable{Ti, postype(lvl)}())

SparseLevel{Ti}(lvl::Lvl, shape, tbl::Tbl) where {Ti, Lvl, Tbl} =
    SparseLevel{Ti, Tbl, Lvl}(lvl, shape, tbl)
    
Base.summary(lvl::SparseLevel) = "Sparse($(summary(lvl.lvl)))"
similar_level(lvl::SparseLevel, fill_value, eltype::Type, dim, tail...) =
    Sparse(similar_level(lvl.lvl, fill_value, eltype, tail...), dim)

function postype(::Type{SparseLevel{Ti, Tbl, Lvl}}) where {Ti, Tbl, Lvl}
    return postype(Lvl)
end

Base.resize!(lvl::SparseLevel{Ti}, dims...) where {Ti} = 
    SparseLevel{Ti}(resize!(lvl.lvl, dims[1:end-1]...), dims[end], lvl.tbl)

function moveto(lvl::SparseLevel{Ti, Tbl, Lvl}, Tm) where {Ti, Tbl, Lvl}
    lvl_2 = moveto(lvl.lvl, Tm)
    tbl_2 = moveto(lvl.tbl, Tm)
    return SparseLevel{Ti}(lvl_2, lvl.shape, tbl_2)
end

function countstored_level(lvl::SparseLevel, pos)
    pos == 0 && return countstored_level(lvl.lvl, pos)
    countstored_level(lvl.lvl, table_pos(lvl.tbl, pos) - 1)
end

pattern!(lvl::SparseLevel{Ti}) where {Ti} = 
    SparseLevel{Ti}(pattern!(lvl.lvl), lvl.shape, lvl.tbl)

redefault!(lvl::SparseLevel{Ti}, init) where {Ti} = 
    SparseLevel{Ti}(redefault!(lvl.lvl, init), lvl.shape, lvl.tbl)

function Base.show(io::IO, lvl::SparseLevel{Ti, Tbl, Lvl}) where {Ti, Tbl, Lvl}
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
        show(io, lvl.tbl)
    end
    print(io, ")")
end

labelled_show(io::IO, fbr::SubFiber{<:SparseLevel}) =
    print(io, "Sparse (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", size(fbr)[end], "]")

function labelled_children(fbr::SubFiber{<:SparseLevel})
    lvl = fbr.lvl
    pos = fbr.pos
    table_isdefined(lvl.tbl, pos) || return []
    subtbl = table_query(lvl.tbl, pos)
    i, stop, state = subtable_init(lvl.tbl, subtbl)
    res = []
    while i <= stop
        (i, q) = subtable_get(lvl.tbl, subtbl, state)
        push!(res, LabelledTree(cartesian_label([range_label() for _ = 1:ndims(fbr) - 1]..., i), SubFiber(lvl.lvl, q)))
        if i == stop
            break
        end
        state = subtable_next(lvl.tbl, subtbl, state)
    end
    res
end

@inline level_ndims(::Type{<:SparseLevel{Ti, Tbl, Lvl}}) where {Ti, Tbl, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SparseLevel) = (level_size(lvl.lvl)..., lvl.shape)
@inline level_axes(lvl::SparseLevel) = (level_axes(lvl.lvl)..., Base.OneTo(lvl.shape))
@inline level_eltype(::Type{<:SparseLevel{Ti, Tbl, Lvl}}) where {Ti, Tbl, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseLevel{Ti, Tbl, Lvl}}) where {Ti, Tbl, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:SparseLevel{Ti, Tbl, Lvl}}) where {Ti, Tbl, Lvl} = SparseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:SparseLevel})() = fbr
function (fbr::SubFiber{<:SparseLevel{Ti}})(idxs...) where {Ti}
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    crds = table_coords(lvl.tbl, p)
    r = searchsorted(crds, idxs[end])
    q = lvl.tbl.ptr[p] + first(r) - 1
    length(r) == 0 ? default(fbr) : SubFiber(lvl.lvl, lvl.tbl.val[q])(idxs[1:end-1]...)
end

mutable struct VirtualSparseLevel <: AbstractVirtualLevel
    lvl
    ex
    Ti
    tbl
    shape
    qos_stop
end
  
is_level_injective(lvl::VirtualSparseLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., false]
is_level_atomic(lvl::VirtualSparseLevel, ctx) = false

function virtualize(ctx, ex, ::Type{SparseLevel{Ti, Tbl, Lvl}}, tag=:lvl) where {Ti, Tbl, Lvl}
    sym = freshen(ctx, tag)
    tbl = freshen(ctx, tag, :_tbl)
    qos_stop = freshen(ctx, tag, :_qos_stop)
    push!(ctx.preamble, quote
        $sym = $ex
        $tbl = $sym.tbl
        $qos_stop = table_length($tbl)
    end)
    lvl_2 = virtualize(ctx, :($sym.lvl), Lvl, sym)
    shape = value(:($sym.shape), Int)
    VirtualSparseLevel(lvl_2, sym, Ti, tbl, shape, qos_stop)
end
function lower(lvl::VirtualSparseLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $SparseLevel{$(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
            $(lvl.tbl),
        )
    end
end

Base.summary(lvl::VirtualSparseLevel) = "Sparse($(summary(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSparseLevel, ctx)
    ext = make_extent(lvl.Ti, literal(lvl.Ti(1)), lvl.shape)
    (virtual_level_size(lvl.lvl, ctx)..., ext)
end

function virtual_level_resize!(lvl::VirtualSparseLevel, ctx, dims...)
    lvl.shape = getstop(dims[end])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end-1]...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseLevel) = virtual_level_default(lvl.lvl)

postype(lvl::VirtualSparseLevel) = postype(lvl.lvl)

function declare_level!(lvl::VirtualSparseLevel, ctx::AbstractCompiler, pos, init)
    #TODO check that init == default
    Ti = lvl.Ti
    Tp = postype(lvl)
    qos = freshen(ctx.code, :qos)
    push!(ctx.code.preamble, quote
        $qos = Finch.declare_table!($(lvl.tbl), $(ctx(pos)))
        $(lvl.qos_stop) = 0
    end)
    lvl.lvl = declare_level!(lvl.lvl, ctx, value(qos, Tp), init)
    return lvl
end

function assemble_level!(lvl::VirtualSparseLevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    qos_start = freshen(ctx.code, :qos_start)
    qos_stop = freshen(ctx.code, :qos_stop)
    quote
        ($qos_start, $qos_stop) = assemble_table!($(lvl.tbl), $(ctx(pos_start)), $(ctx(pos_stop)))
    end
end

function freeze_level!(lvl::VirtualSparseLevel, ctx::AbstractCompiler, pos_stop)
    p = freshen(ctx.code, :p)
    pos_stop = cache!(ctx, :pos_stop, simplify(pos_stop, ctx))
    qos_stop = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        $qos_stop = Finch.freeze_table!($(lvl.tbl), $(ctx(pos_stop)))
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

function thaw_level!(lvl::VirtualSparseLevel, ctx::AbstractCompiler, pos_stop)
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    push!(ctx.code.preamble, quote
        $(lvl.qos_stop) = Finch.thaw_table!($(lvl.tbl), $(ctx(pos_stop)))
    end)
    lvl.lvl = thaw_level!(lvl.lvl, ctx, value(lvl.qos_stop))
    return lvl
end

function virtual_moveto_level(lvl::VirtualSparseLevel, ctx::AbstractCompiler, arch)
    ptr_2 = freshen(ctx.code, lvl.ptr)
    idx_2 = freshen(ctx.code, lvl.idx)
    push!(ctx.code.preamble, quote
        $tbl_2 = $(lvl.tbl)
        $(lvl.tbl) = $moveto($(lvl.tbl), $(ctx(arch)))
    end)
    push!(ctx.code.epilogue, quote
        $(lvl.tbl) = $tbl_2
    end)
    virtual_moveto_level(lvl.lvl, ctx, arch)
end

function instantiate(fbr::VirtualSubFiber{VirtualSparseLevel}, ctx, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    Ti = lvl.Ti
    my_i = freshen(ctx.code, tag, :_i)
    my_q = freshen(ctx.code, tag, :_q)
    my_q_stop = freshen(ctx.code, tag, :_q_stop)
    my_i1 = freshen(ctx.code, tag, :_i1)
    subtbl = freshen(ctx.code, tag, :_subtbl)
    state = freshen(ctx.code, tag, :_state)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $subtbl = table_query($(lvl.tbl), $(ctx(pos)))
                ($my_i, $my_i1, $state) = subtable_init($(lvl.tbl), $subtbl)
            end,
            body = (ctx) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> value(my_i1),
                    body = (ctx, ext) -> Stepper(
                        seek = (ctx, ext) -> quote
                            if $my_i < $(ctx(getstart(ext)))
                                ($my_i, $state) = subtable_seek($(lvl.tbl), $subtbl, $state, $my_i, $(ctx(getstart(ext))))
                            end
                        end,
                        preamble = :(($my_i, $my_q) = subtable_get($(lvl.tbl), $subtbl, $state)),
                        stop = (ctx, ext) -> value(my_i),
                        chunk = Spike(
                            body = Fill(virtual_level_default(lvl)),
                            tail = Simplify(instantiate(VirtualSubFiber(lvl.lvl, value(my_q, Ti)), ctx, mode, subprotos))
                        ),
                        next = (ctx, ext) -> :($state = subtable_next($(lvl.tbl), $subtbl, $state)) 
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    )
end

instantiate(fbr::VirtualSubFiber{VirtualSparseLevel}, ctx, mode::Updater, protos) = begin
    instantiate(VirtualHollowSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, mode, protos)
end
function instantiate(fbr::VirtualHollowSubFiber{VirtualSparseLevel}, ctx, mode::Updater, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    qos = freshen(ctx.code, tag, :_qos)
    qos_stop = lvl.qos_stop
    dirty = freshen(ctx.code, tag, :_dirty)
    subtbl = freshen(ctx.code, tag, :_subtbl)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $subtbl = table_register($(lvl.tbl), $(ctx(pos)))
            end,
            body = (ctx) -> Lookup(
                body = (ctx, idx) -> Thunk(
                    preamble = quote
                        $qos = subtable_register($(lvl.tbl), $subtbl, $(ctx(idx)))
                        if $qos > $qos_stop
                            $qos_stop = max($qos_stop << 1, 1)
                            $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, Tp), value(qos_stop, Tp)), ctx))
                        end
                        $dirty = false
                    end,
                    body = (ctx) -> instantiate(VirtualHollowSubFiber(lvl.lvl, value(qos, Tp), dirty), ctx, mode, subprotos),
                    epilogue = quote
                        if $dirty
                            subtable_commit($(lvl.tbl), $subtbl, $qos, $(ctx(idx)))
                            $(fbr.dirty) = true
                        end
                    end
                )
            ),
            epilogue = quote
                table_commit($(lvl.tbl), $(ctx(pos)))
            end
        )
    )
end