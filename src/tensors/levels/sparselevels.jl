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
julia> Fiber!(Dense(Sparse(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
Dense [:,1:3]
├─[:,1]: Sparse (0.0) [1:3]
│ ├─[1]: 10.0
│ ├─[2]: 30.0
├─[:,2]: Sparse (0.0) [1:3]
├─[:,3]: Sparse (0.0) [1:3]
│ ├─[1]: 20.0
│ ├─[3]: 40.0

julia> Fiber!(Sparse(Sparse(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
Sparse (0.0) [:,1:3]
├─[:,1]: Sparse (0.0) [1:3]
│ ├─[1]: 10.0
│ ├─[2]: 30.0
├─[:,3]: Sparse (0.0) [1:3]
│ ├─[1]: 20.0
│ ├─[3]: 40.0

```
"""
struct SparseLevel{Ti, Tbl, Lvl}
    lvl::Lvl
    shape::Ti
    tbl::Tbl
end
const Sparse = SparseLevel
SparseLevel(lvl) = SparseLevel{Int}(lvl)
SparseLevel(lvl, shape::Ti) where {Ti} = SparseLevel{Ti}(lvl, shape)
SparseLevel{Ti}(lvl) where {Ti} = SparseLevel{Ti}(lvl, zero(Ti))
SparseLevel{Ti}(lvl, shape) where {Ti} = SparseLevel{Ti}(lvl, shape, TreeTable{Tuple{postype(lvl), Ti}, postype(lvl)}())

SparseLevel{Ti}(lvl::Lvl, shape, tbl::Tbl) where {Ti, Lvl, Tbl} =
    SparseLevel{Ti, Tbl, Lvl}(lvl, shape, tbl)
    
Base.summary(lvl::SparseLevel) = "Sparse($(summary(lvl.lvl)))"
similar_level(lvl::SparseLevel) = Sparse(similar_level(lvl.lvl))
similar_level(lvl::SparseLevel, dim, tail...) = Sparse(similar_level(lvl.lvl, tail...), dim)

function postype(::Type{SparseLevel{Ti, Tbl, Lvl}}) where {Ti, Tbl, Lvl}
    return postype(Lvl)
end

function moveto(lvl::SparseLevel{Ti, Tbl, Lvl}, Tm) where {Ti, Tbl, Lvl}
    lvl_2 = moveto(lvl.lvl, Tm)
    tbl_2 = moveto(lvl.tbl, Tm)
    return SparseLevel{Ti}(lvl_2, lvl.shape, tbl_2)
end

function countstored_level(lvl::SparseLevel, pos)
    countstored_level(lvl.lvl, lvl.ptr[pos + 1] - 1)
end

pattern!(lvl::SparseLevel{Ti}) where {Ti} = 
    SparseLevel{Ti}(pattern!(lvl.lvl), lvl.shape, lvl.tbl)

redefault!(lvl::SparseLevel{Ti}, init) where {Ti} = 
    SparseLevel{Ti}(redefault!(lvl.lvl, init), lvl.shape, lvl.tbl)

function Base.show(io::IO, lvl::SparseLevel{Ti, Ptr, Idx, Lvl}) where {Ti, Lvl, Idx, Ptr}
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
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:SparseLevel}, depth)
    p = fbr.pos
    crds = @view(fbr.lvl.idx[fbr.lvl.ptr[p]:fbr.lvl.ptr[p + 1] - 1])

    print_coord(io, crd) = show(io, crd)
    get_fbr(crd) = fbr(crd)

    print(io, "Sparse (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", fbr.lvl.shape, "]")
    display_fiber_data(io, mime, fbr, depth, 1, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:SparseLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SparseLevel) = (level_size(lvl.lvl)..., lvl.shape)
@inline level_axes(lvl::SparseLevel) = (level_axes(lvl.lvl)..., Base.OneTo(lvl.shape))
@inline level_eltype(::Type{<:SparseLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:SparseLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = SparseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:SparseLevel})() = fbr
function (fbr::SubFiber{<:SparseLevel{Ti}})(idxs...) where {Ti}
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    r = searchsorted(@view(lvl.idx[lvl.ptr[p]:lvl.ptr[p + 1] - 1]), idxs[end])
    q = lvl.ptr[p] + first(r) - 1
    fbr_2 = SubFiber(lvl.lvl, q)
    length(r) == 0 ? default(fbr_2) : fbr_2(idxs[1:end-1]...)
end

mutable struct VirtualSparseLevel <: AbstractVirtualLevel
    lvl
    ex
    Ti
    tbl
    shape
end
  
is_level_injective(lvl::VirtualSparseLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., false]
is_level_atomic(lvl::VirtualSparseLevel, ctx) = false

function virtualize(ex, ::Type{SparseLevel{Ti, Ptr, Idx, Lvl}}, ctx, tag=:lvl) where {Ti, Ptr, Idx, Lvl}
    sym = freshen(ctx, tag)
    tbl = freshen(ctx, tag, :_tbl)
    push!(ctx.preamble, quote
        $sym = $ex
        $tbl = $sym.tbl
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    shape = value(:($sym.shape), Int)
    VirtualSparseLevel(lvl_2, sym, Ti, tbl, shape)
end
function lower(lvl::VirtualSparseLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $SparseLevel{$(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
            $(lvl.ptr),
            $(lvl.idx),
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

struct ListTable{Ti, Tp, Ptr, Idx}
    ptr::Ptr
    idx::Idx
end

ListTable{Ti, Tp}() = ListTable{Ti, Tp}(Tp[1], Ti[], Ref{Ti}(0))
ListTable{Ti, Tp}(ptr::Ptr, idx::Idx) where {Ptr, Idx} = ListTable{Ti, Tp, Ptr, Idx}(Tp[1], Ti[])


function declare_level!(lvl::VirtualSparseLevel, ctx::AbstractCompiler, pos, init)
    #TODO check that init == default
    Ti = lvl.Ti
    Tp = postype(lvl)
    qos = ctx.freshen(qos)
    push!(ctx.code.preamble, quote
        $qos = Finch.declare_table!($(lvl.tbl), $pos)
    end)
    lvl.lvl = declare_level!(lvl.lvl, ctx, value(qos, Tp), init)
    return lvl
end

function declare_table!(tbl::ListTable, pos)
    return tbl.ptr[pos + 1] - 1
end

function trim_level!(lvl::VirtualSparseLevel, ctx::AbstractCompiler, pos)
    qos = freshen(ctx.code, :qos)
    Tp = postype(lvl)
    push!(ctx.code.preamble, quote
        $qos = Finch.trim_table!($(lvl.tbl), $pos)
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos, Tp))
    return lvl
end

function trim_table!(tbl::ListTable, pos)
    resize!(lvl.ptr, pos + 1)
    qos = lvl.ptr[end] - 1
    resize!(lvl.idx, qos)
    return qos
end

function assemble_level!(lvl::VirtualSparseLevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        Finch.assemble_table!($(lvl.tbl), $pos_start, $pos_stop)
    end
end

function assemble_table!(tbl::ListTable, pos_start, pos_stop)
    resize_if_smaller!(tbl.ptr, pos_stop + 1)
    fill_range!(tbl.ptr, 0, pos_start + 1, pos_stop + 1)
end

function freeze_level!(lvl::VirtualSparseLevel, ctx::AbstractCompiler, pos_stop)
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        $qos_stop = Finch.freeze_table!($(lvl.tbl), pos_stop)
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

function freeze_table!(tbl::ListTable, pos_stop)
    for p = 2:(pos_stop + 1)
        tbl.ptr[p] += tbl.ptr[p - 1]
    end
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

function moveto(tbl::ListTable, arch)
    ptr_2 = moveto(ptr_2, arch)
    idx_2 = moveto(idx_2, arch)
    return ListTable(ptr_2, idx_2)
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

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $subtbl = walk_table($(lvl.tbl), $(ctx(pos)))
                (($my_i, $my_q), $state) = iterate($sub_tbl)
            end,
            body = (ctx) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> value(my_i1),
                    body = (ctx, ext) -> Stepper(
                        seek = (ctx, ext) -> quote
                            (($my_i, $my_q), $state) = seek($subtbl, $state, $my_i, $my_q)
                        end,
                        stop = (ctx, ext) -> value(my_i),
                        chunk = Spike(
                            body = Fill(virtual_level_default(lvl)),
                            tail = Simplify(instantiate(VirtualSubFiber(lvl.lvl, value(my_q, Ti)), ctx, mode, subprotos))
                        ),
                        next = (ctx, ext) -> :(($my_i, $my_q), $state = iterate($sub_tbl, $state)) 
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    )
end

struct ListTableWalk{Ti, Tp, Tbl}
    

instantiate(fbr::VirtualSubFiber{VirtualSparseLevel}, ctx, mode::Updater, protos) = begin
    instantiate(VirtualHollowSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, mode, protos)
end
function instantiate(fbr::VirtualHollowSubFiber{VirtualSparseLevel}, ctx, mode::Updater, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    qos = freshen(ctx.code, tag, :_qos)
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    dirty = freshen(ctx.code, tag, :dirty)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $subtbl = open_subtable($(lvl.tbl), $(ctx(pos)))
            end,
            body = (ctx) -> Lookup(
                body = (ctx, idx) -> Thunk(
                    preamble = quote
                        $ref, $qos = register_update($subtbl, $idx)
                        if $qos > $qos_stop
                            $qos_stop = max($qos_stop << 1, 1)
                            $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, Tp), value(qos_stop, Tp)), ctx))
                        end
                        $dirty = false
                    end,
                    body = (ctx) -> instantiate(VirtualHollowSubFiber(lvl.lvl, value(qos, Tp), dirty), ctx, mode, subprotos),
                    epilogue = quote
                        if $dirty
                            $(fbr.dirty) = true
                            commit_update($ref)
                        end
                    end
                )
            ),
            epilogue = quote
                close_subtable($subtbl)
            end
        )
    )
end
