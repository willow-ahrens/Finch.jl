"""
    DenseRLELevel{[Ti=Int], [Ptr, Right]}(lvl, [dim])

The dense RLE level represent runs of equivalent slices `A[:, ..., :, i]`. A
sorted list is used to record the right endpoint of each run. Optionally, `dim`
is the size of the last dimension.

`Ti` is the type of the last tensor index, and `Tp` is the type used for
positions in the level. The types `Ptr` and `Right` are the types of the
arrays used to store positions and endpoints. 

```jldoctest
julia> Tensor(Dense(DenseRLELevel(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
Dense [:,1:3]
├─ [:, 1]: DenseRLE (0.0) [1:3]
│  ├─ [1:1]: 10.0
│  └─ [2:2]: 30.0
├─ [:, 2]: DenseRLE (0.0) [1:3]
└─ [:, 3]: DenseRLE (0.0) [1:3]
   ├─ [1:1]: 20.0
   └─ [3:3]: 40.0
```
"""
struct DenseRLELevel{Ti, Ptr<:AbstractVector, Right<:AbstractVector, Lvl} <: AbstractLevel
    lvl::Lvl
    shape::Ti
    ptr::Ptr
    right::Right
    buf::Lvl
end

const DenseRLE = DenseRLELevel
DenseRLELevel(lvl::Lvl) where {Lvl} = DenseRLELevel{Int}(lvl)
DenseRLELevel(lvl, shape, args...) = DenseRLELevel{typeof(shape)}(lvl, shape, args...)
DenseRLELevel{Ti}(lvl) where {Ti} = DenseRLELevel(lvl, zero(Ti))
DenseRLELevel{Ti}(lvl, shape) where {Ti} = DenseRLELevel{Ti}(lvl, shape, postype(lvl)[1], Ti[], similar_level(lvl))
DenseRLELevel{Ti}(lvl::Lvl, shape, ptr::Ptr, right::Right, buf::Lvl) where {Ti, Lvl, Ptr, Right} =
    DenseRLELevel{Ti, Ptr, Right, Lvl}(lvl, Ti(shape), ptr, right, buf)

Base.summary(lvl::DenseRLELevel) = "DenseRLE($(summary(lvl.lvl)))"
similar_level(lvl::DenseRLELevel) = DenseRLE(similar_level(lvl.lvl))
similar_level(lvl::DenseRLELevel, dim, tail...) = DenseRLE(similar_level(lvl.lvl, tail...), dim)

function postype(::Type{DenseRLELevel{Ti, Ptr, Right, Lvl}}) where {Ti, Ptr, Right, Lvl}
    return postype(Lvl)
end

function moveto(lvl::DenseRLELevel{Ti}, device) where {Ti}
    lvl_2 = moveto(lvl.lvl, device)
    ptr = moveto(lvl.ptr, device)
    right = moveto(lvl.right, device)
    buf = moveto(lvl.buf, device)
    return DenseRLELevel{Ti}(lvl_2, lvl.shape, lvl.ptr, lvl.right, lvl.buf)
end

pattern!(lvl::DenseRLELevel{Ti}) where {Ti} = 
    DenseRLELevel{Ti}(pattern!(lvl.lvl), lvl.shape, lvl.ptr, lvl.right, pattern!(lvl.buf))

function countstored_level(lvl::DenseRLELevel, pos)
    countstored_level(lvl.lvl, lvl.ptr[pos + 1] - 1)
end

redefault!(lvl::DenseRLELevel{Ti}, init) where {Ti} = 
    DenseRLELevel{Ti}(redefault!(lvl.lvl, init), lvl.shape, lvl.ptr, lvl.right, redefault!(lvl.buf, init))

Base.resize!(lvl::DenseRLELevel{Ti}, dims...) where {Ti} = 
    DenseRLELevel{Ti}(resize!(lvl.lvl, dims[1:end-1]...), dims[end], lvl.ptr, lvl.right, resize!(lvl.buf, dims[1:end-1]...))

function Base.show(io::IO, lvl::DenseRLELevel{Ti, Ptr, Right, Lvl}) where {Ti, Ptr, Right, Lvl}
    if get(io, :compact, false)
        print(io, "DenseRLE(")
    else
        print(io, "DenseRLE{$Ti}(")
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
        show(io, lvl.right)
        print(io, ", ")
        show(io, lvl.buf)
    end
    print(io, ")")
end

labelled_show(io::IO, fbr::SubFiber{<:DenseRLELevel}) =
    print(io, "DenseRLE (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", size(fbr)[end], "]")

function labelled_children(fbr::SubFiber{<:DenseRLELevel})
    lvl = fbr.lvl
    pos = fbr.pos
    pos + 1 > length(lvl.ptr) && return []
    map(lvl.ptr[pos]:lvl.ptr[pos + 1] - 1) do qos
        left = qos == lvl.ptr[pos] ? 1 : lvl.right[qos - 1] + 1
        LabelledTree(cartesian_label([range_label() for _ = 1:ndims(fbr) - 1]..., range_label(left, lvl.right[qos])), SubFiber(lvl.lvl, qos))
    end
end

@inline level_ndims(::Type{<:DenseRLELevel{Ti, Ptr, Right, Lvl}}) where {Ti, Ptr, Right, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::DenseRLELevel) = (level_size(lvl.lvl)..., lvl.shape)
@inline level_axes(lvl::DenseRLELevel) = (level_axes(lvl.lvl)..., Base.OneTo(lvl.shape))
@inline level_eltype(::Type{<:DenseRLELevel{Ti, Ptr, Right, Lvl}}) where {Ti, Ptr, Right, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:DenseRLELevel{Ti, Ptr, Right, Lvl}}) where {Ti, Ptr, Right, Lvl}= level_default(Lvl)
data_rep_level(::Type{<:DenseRLELevel{Ti, Ptr, Right, Lvl}}) where {Ti, Ptr, Right, Lvl} = SparseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:DenseRLELevel})() = fbr
function (fbr::SubFiber{<:DenseRLELevel})(idxs...)
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    r1 = something(searchsortedlast(@view(lvl.right[lvl.ptr[p]:lvl.ptr[p + 1] - 1]), idxs[end] + 1), 0) - 1
    r2 = searchsortedfirst(@view(lvl.right[lvl.ptr[p]:lvl.ptr[p + 1] - 1]), idxs[end])
    q = lvl.ptr[p] + first(r1) - 1
    fbr_2 = SubFiber(lvl.lvl, q)
    r1 != r2 ? default(fbr_2) : fbr_2(idxs[1:end-1]...)
end

mutable struct VirtualDenseRLELevel <: AbstractVirtualLevel
    lvl
    ex
    Ti
    shape
    qos_fill
    qos_stop
    ptr
    right
    buf
    prev_pos
    i_prev
end

is_level_injective(lvl::VirtualDenseRLELevel, ctx) = [false, is_level_injective(lvl.lvl, ctx)...]
is_level_concurrent(lvl::VirtualDenseRLELevel, ctx) = [false, is_level_concurrent(lvl.lvl, ctx)...]
is_level_atomic(lvl::VirtualDenseRLELevel, ctx) = false

postype(lvl::VirtualDenseRLELevel) = postype(lvl.lvl)

function virtualize(ex, ::Type{DenseRLELevel{Ti, Ptr, Right, Lvl}}, ctx, tag=:lvl) where {Ti, Ptr, Right, Lvl}
    sym = freshen(ctx, tag)
    shape = value(:($sym.shape), Int)
    qos_fill = freshen(ctx, sym, :_qos_fill)
    qos_stop = freshen(ctx, sym, :_qos_stop)
    dirty = freshen(ctx, sym, :_dirty)
    ptr = freshen(ctx, tag, :_ptr)
    right = freshen(ctx, tag, :_right)
    buf = freshen(ctx, tag, :_buf)
    push!(ctx.preamble, quote
        $sym = $ex
        $ptr = $sym.ptr
        $right = $sym.right
        $buf = $sym.buf
    end)
    i_prev = freshen(ctx, tag, :_i_prev)
    prev_pos = freshen(ctx, sym, :_prev_pos)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    buf = virtualize(:($sym.buf), Lvl, ctx, sym)
    VirtualDenseRLELevel(lvl_2, sym, Ti, shape, qos_fill, qos_stop, ptr, right, buf, prev_pos, i_prev)
end
function lower(lvl::VirtualDenseRLELevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $DenseRLELevel{$(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
            $(lvl.ptr),
            $(lvl.right),
            $(ctx(lvl.buf)),
        )
    end
end

Base.summary(lvl::VirtualDenseRLELevel) = "DenseRLE($(summary(lvl.lvl)))"

function virtual_level_size(lvl::VirtualDenseRLELevel, ctx)
    ext = make_extent(lvl.Ti, literal(lvl.Ti(1.0)), lvl.shape)
    (virtual_level_size(lvl.lvl, ctx)..., ext)
end

function virtual_level_resize!(lvl::VirtualDenseRLELevel, ctx, dims...)
    lvl.shape = getstop(dims[end])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end-1]...)
    lvl.buf = virtual_level_resize!(lvl.buf, ctx, dims[1:end-1]...)
    lvl
end

function virtual_moveto_level(lvl::VirtualDenseRLELevel, ctx::AbstractCompiler, arch)
    ptr_2 = freshen(ctx.code, lvl.ptr)
    right_2 = freshen(ctx.code, lvl.right)
    push!(ctx.code.preamble, quote
        $ptr_2 = $(lvl.ptr)
        $right_2 = $(lvl.right)
        $(lvl.ptr) = $moveto($(lvl.ptr), $(ctx(arch)))
        $(lvl.right) = $moveto($(lvl.right), $(ctx(arch)))
    end)
    push!(ctx.code.epilogue, quote
        $(lvl.ptr) = $ptr_2
        $(lvl.right) = $right_2
    end)
    virtual_moveto_level(lvl.lvl, ctx, arch)
    virtual_moveto_level(lvl.buf, ctx, arch)
end

virtual_level_eltype(lvl::VirtualDenseRLELevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualDenseRLELevel) = virtual_level_default(lvl.lvl)

function declare_level!(lvl::VirtualDenseRLELevel, ctx::AbstractCompiler, pos, init)
    Tp = postype(lvl)
    Ti = lvl.Ti
    qos = call(-, call(getindex, :($(lvl.ptr)), call(+, pos, 1)), 1)
    unit = ctx(get_smallest_measure(virtual_level_size(lvl, ctx)[end]))
    push!(ctx.code.preamble, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
        $(lvl.i_prev) = $(ctx(lvl.shape))
        $(lvl.prev_pos) = $(Tp(0))
    end)
    lvl.buf = declare_level!(lvl.buf, ctx, qos, init)
    return lvl
end

function assemble_level!(lvl::VirtualDenseRLELevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        Finch.resize_if_smaller!($(lvl.ptr), $pos_stop + 1)
        Finch.fill_range!($(lvl.ptr), 0, $pos_start + 1, $pos_stop + 1)
    end
end

#=
function freeze_level!(lvl::VirtualDenseRLELevel, ctx::AbstractCompiler, pos_stop)
    (lvl.buf, lvl.lvl) = (lvl.lvl, lvl.buf)
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        resize!($(lvl.ptr), $pos_stop + 1)
        for $p = 1:$pos_stop
            $(lvl.ptr)[$p + 1] += $(lvl.ptr)[$p]
        end
        $qos_stop = $(lvl.ptr)[$pos_stop + 1] - 1
        resize!($(lvl.right), $qos_stop)
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end
=#

function freeze_level!(lvl::VirtualDenseRLELevel, ctx::AbstractCompiler, pos_stop)
    Tp = postype(lvl)
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    pos_2 = freshen(ctx.code, tag, :_pos)
    qos_stop = lvl.qos_stop
    qos = freshen(ctx.code, :qos)
    unit = ctx(get_smallest_measure(virtual_level_size(lvl, ctx)[end]))
    Ti = lvl.Ti
    push!(ctx.code.preamble, quote
        $qos = $(lvl.qos_fill) + 1
        for $pos_2 = $(lvl.prev_pos):$(pos_stop)
            if $qos > $qos_stop
                $qos_stop = max($qos_stop << 1, 1)
                Finch.resize_if_smaller!($(lvl.right), $qos_stop)
                $(contain(ctx_2->assemble_level!(lvl.buf, ctx_2, call(+, value(qos, Tp), literal(Tp(1))), value(qos_stop, Tp)), ctx))
            end
            if $(lvl.i_prev) < $(ctx(lvl.shape))
                $(lvl.right)[$qos] = $(ctx(lvl.shape))
                $(qos) += $(Tp(1))
                $(lvl.i_prev) = $(Ti(1)) - $unit
            end
        end
        resize!($(lvl.ptr), $pos_stop + 1)
        for $p = 1:$pos_stop
            $(lvl.ptr)[$p + 1] += $(lvl.ptr)[$p]
        end
        $qos_stop = $(lvl.ptr)[$pos_stop + 1] - 1
    end)
    lvl.buf = freeze_level!(lvl.buf, ctx, value(qos_stop))
    lvl.lvl = declare_level!(lvl.lvl, ctx, literal(1), literal(virtual_level_default(lvl.buf)))
    p = freshen(ctx.code, :p)
    q = freshen(ctx.code, :q)
    q_head = freshen(ctx.code, :q_head)
    q_stop = freshen(ctx.code, :q_stop)
    q_2 = freshen(ctx.code, :q_2)
    checkval = freshen(ctx.code, :check)
    push!(ctx.code.preamble, quote
        $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(1, Tp), value(qos_stop, Tp)), ctx))
        $q = 1
        $q_2 = 1
        for $p = 1:$pos_stop
            $q_stop = $(lvl.ptr)[$p + 1]
            while $q < $q_stop
                $q_head = $q
                while $q + 1 < $q_stop && $(lvl.right)[$q] == $(lvl.right)[$q + 1] - $(unit)
                    $checkval = true
                    $(contain(ctx) do ctx_2
                        left = variable(freshen(ctx.code, :left))
                        ctx_2.bindings[left] = virtual(VirtualSubFiber(lvl.buf, value(q_head, Tp)))
                        right = variable(freshen(ctx.code, :right))
                        ctx_2.bindings[right] = virtual(VirtualSubFiber(lvl.buf, call(+, value(q, Tp), Tp(1))))
                        check = VirtualScalar(:UNREACHABLE, Bool, false, :check, checkval)
                        exts = virtual_level_size(lvl.buf, ctx_2)
                        inds = [index(freshen(ctx_2.code, :i, n)) for n = 1:length(exts)]
                        prgm = assign(access(check, updater), and, call(isequal, access(left, reader, inds...), access(right, reader, inds...)))
                        for (ind, ext) in zip(inds, exts)
                            prgm = loop(ind, ext, prgm)
                        end
                        prgm = instantiate!(prgm, ctx_2)
                        ctx_2(prgm)
                    end)
                    if !$checkval
                        break
                    else
                        $q += 1
                    end
                end
                $(lvl.right)[$q_2] = $(lvl.right)[$q]
                $(contain(ctx) do ctx_2
                    src = variable(freshen(ctx.code, :src))
                    ctx_2.bindings[src] = virtual(VirtualSubFiber(lvl.buf, value(q_head, Tp)))
                    dst = variable(freshen(ctx.code, :dst))
                    ctx_2.bindings[dst] = virtual(VirtualSubFiber(lvl.lvl, value(q_2, Tp)))
                    exts = virtual_level_size(lvl.buf, ctx_2)
                    inds = [index(freshen(ctx_2.code, :i, n)) for n = 1:length(exts)]
                    prgm = assign(access(dst, updater, inds...), initwrite(virtual_level_default(lvl.lvl)), access(src, reader, inds...))
                    for (ind, ext) in zip(inds, exts)
                        prgm = loop(ind, ext, prgm)
                    end
                    prgm = instantiate!(prgm, ctx_2)
                    ctx_2(prgm)
                end)
                $q_2 += 1
                $q += 1
            end
            $(lvl.ptr)[$p + 1] = $q_2
        end
        resize!($(lvl.right), $q_2 - 1)
        $qos_stop = $q_2 - 1
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    lvl.buf = declare_level!(lvl.buf, ctx, literal(1), literal(virtual_level_default(lvl.buf)))
    lvl.buf = freeze_level!(lvl.buf, ctx, literal(0))
    return lvl
end

function thaw_level!(lvl::VirtualDenseRLELevel, ctx::AbstractCompiler, pos_stop)
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = freshen(ctx.code, :qos_stop)
    unit = ctx(get_smallest_measure(virtual_level_size(lvl, ctx)[end]))
    push!(ctx.code.preamble, quote
        $(lvl.qos_fill) = $(lvl.ptr)[$pos_stop + 1] - 1
        $(lvl.qos_stop) = $(lvl.qos_fill)
        $(lvl.i_prev) = $(lvl.right)[$(lvl.qos_fill)]
        $qos_stop = $(lvl.qos_fill)
        $(lvl.prev_pos) = Finch.scansearch($(lvl.ptr), $(lvl.qos_stop) + 1, 1, $pos_stop) - 1
        for $p = $pos_stop:-1:1
            $(lvl.ptr)[$p + 1] -= $(lvl.ptr)[$p]
        end
    end)
    (lvl.lvl, lvl.buf) = (lvl.buf, lvl.lvl)
    lvl.buf = thaw_level!(lvl.buf, ctx, value(qos_stop))
    return lvl
end

function instantiate(fbr::VirtualSubFiber{VirtualDenseRLELevel}, ctx, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(walk)})
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
                    $my_i = $(lvl.right)[$my_q]
                    $my_i1 = $(lvl.right)[$my_q_stop - $(Tp(1))]
                else
                    $my_i = $(Ti(1))
                    $my_i1 = $(Ti(0))
                end
            end),
            body = (ctx) -> Stepper(
                seek = (ctx, ext) -> quote
                    if $(lvl.right)[$my_q] < $(ctx(getstart(ext)))
                        $my_q = Finch.scansearch($(lvl.right), $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                    end
                end,
                preamble = :($my_i = $(lvl.right)[$my_q]),
                stop = (ctx, ext) -> value(my_i),
                chunk = Run(
                    body = Simplify(instantiate(VirtualSubFiber(lvl.lvl, value(my_q)), ctx, mode, subprotos))
                ),
                next = (ctx, ext) -> :($my_q += $(Tp(1)))
            )
        )
    )
end

instantiate(fbr::VirtualSubFiber{VirtualDenseRLELevel}, ctx, mode::Updater, protos) = 
    instantiate(VirtualHollowSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, mode, protos)

function instantiate(fbr::VirtualHollowSubFiber{VirtualDenseRLELevel}, ctx, mode::Updater, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    (lvl, pos) = (fbr.lvl, fbr.pos) 
    tag = lvl.ex
    Tp = postype(lvl)
    Ti = lvl.Ti
    qos = freshen(ctx.code, tag, :_qos)
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    dirty = freshen(ctx.code, tag, :dirty)
    pos_2 = freshen(ctx.code, tag, :_pos)
    unit = ctx(get_smallest_measure(virtual_level_size(lvl, ctx)[end]))
    qos_2 = freshen(ctx.code, tag, :_qos_2)
    
    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $qos = $qos_fill + 1
                $(if issafe(ctx.mode)
                    quote
                        $(lvl.prev_pos) < $(ctx(pos)) || throw(FinchProtocolError("DenseRLELevels cannot be updated multiple times"))
                    end
                end)
                for $pos_2 = $(lvl.prev_pos):$(ctx(pos)) - 1
                    if $qos > $qos_stop #Add one in case we need to write a default level.
                        $qos_stop = max($qos_stop << 1, 1)
                        Finch.resize_if_smaller!($(lvl.right), $qos_stop)
                        $(contain(ctx_2->assemble_level!(lvl.buf, ctx_2, call(+, value(qos, Tp), literal(Tp(1))), value(qos_stop, Tp)), ctx))
                    end
                    if $(lvl.i_prev) < $(ctx(lvl.shape))
                        $(lvl.right)[$qos] = $(ctx(lvl.shape))
                        $(qos) += $(Tp(1))
                        $(lvl.i_prev) = $(Ti(1)) - $unit
                    end
                end
                $(lvl.prev_pos) = $(ctx(pos)) - 1
            end,

            body = (ctx) -> AcceptRun(
                body = (ctx, ext) -> Thunk(
                    preamble = quote
                        $qos_2 = $qos
                        if $(lvl.i_prev) < $(ctx(getstart(ext))) - $unit
                            $qos_2 = $qos + 1
                            $(lvl.right)[$qos] = $(ctx(getstart(ext))) - $unit
                        end
                        if $qos_2 > $qos_stop #Add one in case we need to write a default level.
                            $qos_stop = max($qos_stop << 1, 1)
                            Finch.resize_if_smaller!($(lvl.right), $qos_stop)
                            $(contain(ctx_2->assemble_level!(lvl.buf, ctx_2, call(+, value(qos_2, Tp), literal(Tp(1))), value(qos_stop, Tp)), ctx))
                        end
                        $dirty = false
                    end,
                    body = (ctx) -> instantiate(VirtualHollowSubFiber(lvl.buf, value(qos_2, Tp), dirty), ctx, mode, subprotos),
                    epilogue = quote
                        if $dirty
                            $(fbr.dirty) = true
                            $(lvl.right)[$qos_2] = $(ctx(getstop(ext)))
                            $(qos) = $qos_2 + $(Tp(1))
                            $(lvl.i_prev) = $(ctx(getstop(ext)))
                            $(lvl.prev_pos) = $(ctx(pos))
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