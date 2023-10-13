"""
    RootRootSparseListLevel{[Ti=Int], [Idx=Vector{Ti}]}(lvl, [dim])

The RootRootSparseListLevel is specialized to store a single fiber of a
RootSparseListLevel. Therefore, it does not use a `ptr` array.

```jldoctest
julia> Fiber!(RootRootSparseList(RootSparseList(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
RootRootSparseList (0.0) [:,1:3]
├─[:,1]: RootSparseList (0.0) [1:3]
│ ├─[1]: 10.0
│ ├─[2]: 30.0
├─[:,3]: RootSparseList (0.0) [1:3]
│ ├─[1]: 20.0
│ ├─[3]: 40.0

```
"""
struct RootSparseListLevel{Ti, Idx, Lvl} <: AbstractLevel
    lvl::Lvl
    shape::Ti
    idx::Idx
end
const RootSparseList = RootSparseListLevel
RootSparseListLevel(lvl) = RootSparseListLevel{Int}(lvl)
RootSparseListLevel(lvl, shape::Ti) where {Ti} = RootSparseListLevel{Ti}(lvl, shape)
RootSparseListLevel{Ti}(lvl) where {Ti} = RootSparseListLevel{Ti}(lvl, zero(Ti))
RootSparseListLevel{Ti}(lvl, shape) where {Ti} = RootSparseListLevel{Ti}(lvl, shape, Ti[])

RootSparseListLevel{Ti}(lvl::Lvl, shape, idx::Idx) where {Ti, Lvl, Idx} =
    RootSparseListLevel{Ti, Idx, Lvl}(lvl, shape, idx)
    
Base.summary(lvl::RootSparseListLevel) = "RootSparseList($(summary(lvl.lvl)))"
similar_level(lvl::RootSparseListLevel) = RootSparseList(similar_level(lvl.lvl))
similar_level(lvl::RootSparseListLevel, dim, tail...) = RootSparseList(similar_level(lvl.lvl, tail...), dim)

function postype(::Type{RootSparseListLevel{Ti, Idx, Lvl}}) where {Ti, Idx, Lvl}
    return postype(Lvl)
end

function moveto(lvl::RootSparseListLevel{Ti, Idx, Lvl}, Tm) where {Ti, Idx, Lvl}
    lvl_2 = moveto(lvl.lvl, Tm)
    idx_2 = moveto(lvl.idx, Tm)
    return RootSparseListLevel{Ti}(lvl_2, lvl.shape, idx_2)
end

function countstored_level(lvl::RootSparseListLevel, pos)
    countstored_level(lvl.lvl, length(lvl.idx))
end

pattern!(lvl::RootSparseListLevel{Ti}) where {Ti} = 
    RootSparseListLevel{Ti}(pattern!(lvl.lvl), lvl.shape, lvl.idx)

redefault!(lvl::RootSparseListLevel{Ti}, init) where {Ti} = 
    RootSparseListLevel{Ti}(redefault!(lvl.lvl, init), lvl.shape, lvl.idx)

function Base.show(io::IO, lvl::RootSparseListLevel{Ti, Idx, Lvl}) where {Ti, Lvl, Idx}
    if get(io, :compact, false)
        print(io, "RootSparseList(")
    else
        print(io, "RootSparseList{$Ti}(")
    end
    show(io, lvl.lvl)
    print(io, ", ")
    show(IOContext(io, :typeinfo=>Ti), lvl.shape)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(io, lvl.idx)
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:RootSparseListLevel}, depth)
    @assert fbr.pos == 1
    crds = fbr.lvl.idx

    print_coord(io, crd) = show(io, crd)
    get_fbr(crd) = fbr(crd)

    print(io, "RootSparseList (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", fbr.lvl.shape, "]")
    display_fiber_data(io, mime, fbr, depth, 1, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:RootSparseListLevel{Ti, Idx, Lvl}}) where {Ti, Idx, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::RootSparseListLevel) = (level_size(lvl.lvl)..., lvl.shape)
@inline level_axes(lvl::RootSparseListLevel) = (level_axes(lvl.lvl)..., Base.OneTo(lvl.shape))
@inline level_eltype(::Type{<:RootSparseListLevel{Ti, Idx, Lvl}}) where {Ti, Idx, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:RootSparseListLevel{Ti, Idx, Lvl}}) where {Ti, Idx, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:RootSparseListLevel{Ti, Idx, Lvl}}) where {Ti, Idx, Lvl} = SparseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:RootSparseListLevel})() = fbr
function (fbr::SubFiber{<:RootSparseListLevel{Ti}})(idxs...) where {Ti}
    isempty(idxs) && return fbr
    @assert fbr.pos == 1
    lvl = fbr.lvl
    r = searchsorted(lvl.idx, idxs[end])
    q = first(r)
    fbr_2 = SubFiber(lvl.lvl, q)
    length(r) == 0 ? default(fbr_2) : fbr_2(idxs[1:end-1]...)
end

mutable struct VirtualRootSparseListLevel <: AbstractVirtualLevel
    lvl
    ex
    Ti
    idx
    shape
    qos_fill
    qos_stop
end
  
is_level_injective(lvl::VirtualRootSparseListLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., false]
is_level_atomic(lvl::VirtualRootSparseListLevel, ctx) = false

function virtualize(ex, ::Type{RootSparseListLevel{Ti, Idx, Lvl}}, ctx, tag=:lvl) where {Ti, Idx, Lvl}
    sym = freshen(ctx, tag)
    idx = freshen(ctx, tag, :_idx)
    push!(ctx.preamble, quote
        $sym = $ex
        $idx = $sym.idx
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    shape = value(:($sym.shape), Int)
    qos_fill = freshen(ctx, sym, :_qos_fill)
    qos_stop = freshen(ctx, sym, :_qos_stop)
    VirtualRootSparseListLevel(lvl_2, sym, Ti, idx, shape, qos_fill, qos_stop)
end
function lower(lvl::VirtualRootSparseListLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $RootSparseListLevel{$(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
            $(lvl.idx),
        )
    end
end

Base.summary(lvl::VirtualRootSparseListLevel) = "RootSparseList($(summary(lvl.lvl)))"

function virtual_level_size(lvl::VirtualRootSparseListLevel, ctx)
    ext = make_extent(lvl.Ti, literal(lvl.Ti(1)), lvl.shape)
    (virtual_level_size(lvl.lvl, ctx)..., ext)
end

function virtual_level_resize!(lvl::VirtualRootSparseListLevel, ctx, dims...)
    lvl.shape = getstop(dims[end])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end-1]...)
    lvl
end

virtual_level_eltype(lvl::VirtualRootSparseListLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualRootSparseListLevel) = virtual_level_default(lvl.lvl)

postype(lvl::VirtualRootSparseListLevel) = postype(lvl.lvl)

function declare_level!(lvl::VirtualRootSparseListLevel, ctx::AbstractCompiler, pos, init)
    #TODO check that init == default
    Ti = lvl.Ti
    Tp = postype(lvl)
    @assert pos == literal(0) || pos == literal(1)
    qos = lvl.qos_fill
    push!(ctx.code.preamble, quote
        $(qos) = $(Tp(1))
        $(lvl.qos_stop) = $Tp(length($(lvl.idx)))
    end)
    lvl.lvl = declare_level!(lvl.lvl, ctx, literal(0), init)
    return lvl
end

function thaw_level!(lvl::VirtualRootSparseListLevel, ctx::AbstractCompiler, pos)
    Ti = lvl.Ti
    Tp = postype(lvl)
    @assert pos == literal(1)
    qos = lvl.qos_fill
    push!(ctx.code.preamble, quote
        $(lvl.qos_stop) = $Tp(length($(lvl.idx)))
        $qos = $(lvl.qos_stop) + 1
    end)
    lvl.lvl = thaw_level!(lvl.lvl, ctx, qos)
    return lvl
end

function trim_level!(lvl::VirtualRootSparseListLevel, ctx::AbstractCompiler, pos)
    @assert pos == literal(1)
    qos = freshen(ctx.code, :qos)
    Tp = postype(lvl)
    push!(ctx.code.preamble, quote
        $qos = $Tp(length($(lvl.idx)))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos, Tp))
    return lvl
end

function assemble_level!(lvl::VirtualRootSparseListLevel, ctx, pos_start, pos_stop)
    return quote end
end

function freeze_level!(lvl::VirtualRootSparseListLevel, ctx::AbstractCompiler, pos_stop)
    @assert pos_stop == literal(1)
    p = freshen(ctx.code, :p)
    Tp = postype(lvl)
    qos_stop = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        $qos_stop = $Tp(length($(lvl.idx))) 
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

function virtual_moveto_level(lvl::VirtualRootSparseListLevel, ctx::AbstractCompiler, arch)
    idx_2 = freshen(ctx.code, lvl.idx)
    push!(ctx.code.preamble, quote
        $idx_2 = $(lvl.idx)
        $(lvl.idx) = $moveto($(lvl.idx), $(ctx(arch)))
    end)
    push!(ctx.code.epilogue, quote
        $(lvl.idx) = $idx_2
    end)
    virtual_moveto_level(lvl.lvl, ctx, arch)
end

function instantiate(fbr::VirtualSubFiber{VirtualRootSparseListLevel}, ctx, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    @assert pos == literal(1)
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

                $my_q = $(Tp(1))
                $my_q_stop = $Tp(length($(lvl.idx))) + $(Tp(1))
                if !isempty($(lvl.idx))
                    $my_i = $(lvl.idx)[1]
                    $my_i1 = $(lvl.idx)[end]
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
                            body = Fill(virtual_level_default(lvl)),
                            tail = Simplify(instantiate(VirtualSubFiber(lvl.lvl, value(my_q, Ti)), ctx, mode, subprotos))
                        ),
                        next = (ctx, ext) -> :($my_q += $(Tp(1))) 
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    )
end

function instantiate(fbr::VirtualSubFiber{VirtualRootSparseListLevel}, ctx, mode::Reader, subprotos, ::typeof(gallop))
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    Ti = lvl.Ti
    my_i = freshen(ctx.code, tag, :_i)
    my_q = freshen(ctx.code, tag, :_q)
    my_q_stop = freshen(ctx.code, tag, :_q_stop)
    my_i1 = freshen(ctx.code, tag, :_i1)
    my_i2 = freshen(ctx.code, tag, :_i2)
    my_i3 = freshen(ctx.code, tag, :_i3)
    my_i4 = freshen(ctx.code, tag, :_i4)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_q = $(Tp(1))
                $my_q_stop = $Tp(length(lvl.idx)) + $(Tp(1))
                if !isempty($(lvl.idx))
                    $my_i = $(lvl.idx)[1]
                    $my_i1 = $(lvl.idx)[end]
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
                            body = Fill(virtual_level_default(lvl)),
                            tail = instantiate(VirtualSubFiber(lvl.lvl, value(my_q, Ti)), ctx, mode, subprotos),
                        ),
                        next = (ctx, ext) -> :($my_q += $(Tp(1))),
                    )  
                ),
                Phase(
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    )
end

instantiate(fbr::VirtualSubFiber{VirtualRootSparseListLevel}, ctx, mode::Updater, protos) = begin
    instantiate(VirtualHollowSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, mode, protos)
end
function instantiate(fbr::VirtualHollowSubFiber{VirtualRootSparseListLevel}, ctx, mode::Updater, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    qos = lvl.qos_fill
    qos_stop = lvl.qos_stop
    dirty = freshen(ctx.code, tag, :dirty)

    Furlable(
        body = (ctx, ext) -> Lookup(
            body = (ctx, idx) -> Thunk(
                preamble = quote
                    if $qos > $qos_stop
                        $qos_stop = max($qos_stop << 1, 1)
                        Finch.resize_if_smaller!($(lvl.idx), $qos_stop)
                        $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, Tp), value(qos_stop, Tp)), ctx))
                    end
                    $(if issafe(ctx.mode)
                        quote
                            @assert $qos == 1 || $(ctx(idx)) > $(lvl.idx)[$qos - 1]
                        end
                    end)
                    $dirty = false
                end,
                body = (ctx) -> instantiate(VirtualHollowSubFiber(lvl.lvl, value(qos, Tp), dirty), ctx, mode, subprotos),
                epilogue = quote
                    if $dirty
                        $(fbr.dirty) = true
                        $(lvl.idx)[$qos] = $(ctx(idx))
                        $qos += $(Tp(1))
                    end
                end
            )
        )
    )
end
