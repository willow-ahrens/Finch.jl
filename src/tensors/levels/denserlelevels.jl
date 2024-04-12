"""
    DenseRLELevel{[Ti=Int], [Ptr, Right]}(lvl, [dim], [merge = true])

The dense RLE level represent runs of equivalent slices `A[:, ..., :, i]`. A
sorted list is used to record the right endpoint of each run. Optionally, `dim`
is the size of the last dimension.

`Ti` is the type of the last tensor index, and `Tp` is the type used for
positions in the level. The types `Ptr` and `Right` are the types of the
arrays used to store positions and endpoints. 

The `merge` keyword argument is used to specify whether the level should merge
duplicate consecutive runs.

```jldoctest
julia> Tensor(Dense(DenseRLELevel(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
Dense [:,1:3]
├─ [:, 1]: DenseRLE (0.0) [1:3]
│  ├─ [1:1]: 10.0
│  ├─ [2:2]: 30.0
│  └─ [3:3]: 0.0
├─ [:, 2]: DenseRLE (0.0) [1:3]
│  └─ [1:3]: 0.0
└─ [:, 3]: DenseRLE (0.0) [1:3]
   ├─ [1:1]: 20.0
   ├─ [2:2]: 0.0
   └─ [3:3]: 40.0
```
"""
struct DenseRLELevel{Ti, Ptr<:AbstractVector, Right<:AbstractVector, merge, Lvl} <: AbstractLevel
    lvl::Lvl
    shape::Ti
    ptr::Ptr
    right::Right
    buf::Lvl
end

const DenseRLE = DenseRLELevel
DenseRLELevel(lvl::Lvl; kwargs...) where {Lvl} = DenseRLELevel{Int}(lvl; kwargs...)
DenseRLELevel(lvl, shape, args...; kwargs...) = DenseRLELevel{typeof(shape)}(lvl, shape, args...; kwargs...)
DenseRLELevel{Ti}(lvl; kwargs...) where {Ti} = DenseRLELevel(lvl, zero(Ti); kwargs...)
DenseRLELevel{Ti}(lvl, shape; kwargs...) where {Ti} = DenseRLELevel{Ti}(lvl, shape, postype(lvl)[1], Ti[], deepcopy(lvl); kwargs...) #TODO if similar_level could return the same type, we could use it here
DenseRLELevel{Ti}(lvl::Lvl, shape, ptr::Ptr, right::Right, buf::Lvl; merge=true) where {Ti, Lvl, Ptr, Right} =
    DenseRLELevel{Ti, Ptr, Right, merge, Lvl}(lvl, Ti(shape), ptr, right, buf)

getmerge(lvl::DenseRLELevel{Ti, Ptr, Right, merge}) where {Ti, Ptr, Right, merge} = merge

Base.summary(lvl::DenseRLELevel) = "DenseRLE($(summary(lvl.lvl)))"
similar_level(lvl::DenseRLELevel, fill_value, eltype::Type, dim, tail...) =
    DenseRLE(similar_level(lvl.lvl, fill_value, eltype, tail...), dim; merge = getmerge(lvl))

function postype(::Type{DenseRLELevel{Ti, Ptr, Right, merge, Lvl}}) where {Ti, Ptr, Right, merge, Lvl}
    return postype(Lvl)
end

function moveto(lvl::DenseRLELevel{Ti}, device) where {Ti}
    lvl_2 = moveto(lvl.lvl, device)
    ptr = moveto(lvl.ptr, device)
    right = moveto(lvl.right, device)
    buf = moveto(lvl.buf, device)
    return DenseRLELevel{Ti}(lvl_2, lvl.shape, lvl.ptr, lvl.right, lvl.buf; merge = getmerge(lvl))
end

pattern!(lvl::DenseRLELevel{Ti}) where {Ti} = 
    DenseRLELevel{Ti}(pattern!(lvl.lvl), lvl.shape, lvl.ptr, lvl.right, pattern!(lvl.buf); merge = getmerge(lvl))

function countstored_level(lvl::DenseRLELevel, pos)
    countstored_level(lvl.lvl, lvl.ptr[pos + 1] - 1)
end

redefault!(lvl::DenseRLELevel{Ti}, init) where {Ti} = 
    DenseRLELevel{Ti}(redefault!(lvl.lvl, init), lvl.shape, lvl.ptr, lvl.right, redefault!(lvl.buf, init); merge = getmerge(lvl))

Base.resize!(lvl::DenseRLELevel{Ti}, dims...) where {Ti} = 
    DenseRLELevel{Ti}(resize!(lvl.lvl, dims[1:end-1]...), dims[end], lvl.ptr, lvl.right, resize!(lvl.buf, dims[1:end-1]...); merge = getmerge(lvl))

function Base.show(io::IO, lvl::DenseRLELevel{Ti, Ptr, Right, merge, Lvl}) where {Ti, Ptr, Right, merge, Lvl}
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
        print(io, "; merge = ")
        show(io, merge) 
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

@inline level_ndims(::Type{<:DenseRLELevel{Ti, Ptr, Right, merge, Lvl}}) where {Ti, Ptr, Right, merge, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::DenseRLELevel) = (level_size(lvl.lvl)..., lvl.shape)
@inline level_axes(lvl::DenseRLELevel) = (level_axes(lvl.lvl)..., Base.OneTo(lvl.shape))
@inline level_eltype(::Type{<:DenseRLELevel{Ti, Ptr, Right, merge, Lvl}}) where {Ti, Ptr, Right, merge, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:DenseRLELevel{Ti, Ptr, Right, merge, Lvl}}) where {Ti, Ptr, Right, merge, Lvl}= level_default(Lvl)
data_rep_level(::Type{<:DenseRLELevel{Ti, Ptr, Right, merge, Lvl}}) where {Ti, Ptr, Right, merge, Lvl} = DenseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:DenseRLELevel})() = fbr
function (fbr::SubFiber{<:DenseRLELevel})(idxs...)
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    r2 = searchsortedfirst(@view(lvl.right[lvl.ptr[p]:lvl.ptr[p + 1] - 1]), idxs[end])
    q = lvl.ptr[p] + r2 - 1
    fbr_2 = SubFiber(lvl.lvl, q)
    fbr_2(idxs[1:end-1]...)
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
    merge
end

is_level_injective(lvl::VirtualDenseRLELevel, ctx) = [false, is_level_injective(lvl.lvl, ctx)...]
is_level_concurrent(lvl::VirtualDenseRLELevel, ctx) = [false, is_level_concurrent(lvl.lvl, ctx)...]
is_level_atomic(lvl::VirtualDenseRLELevel, ctx) = false

postype(lvl::VirtualDenseRLELevel) = postype(lvl.lvl)

function virtualize(ctx, ex, ::Type{DenseRLELevel{Ti, Ptr, Right, merge, Lvl}}, tag=:lvl) where {Ti, Ptr, Right, merge, Lvl}
    #Invariants of the level (Read Mode):
    # 1. right[ptr[p]:ptr[p + 1] - 1] is the sorted list of right endpoints of the runs
    #
    #Invariants of the level (Write Mode):
    # 1. prevpos is the last position written (initially 0)
    # 2. i_prev is the last index written (initially shape)
    # 3. for all p in 1:prevpos-1, ptr[p] is the number of runs in that position
    # 4. qos_fill is the position of the last index written

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
    lvl_2 = virtualize(ctx, :($sym.lvl), Lvl, sym)
    buf = virtualize(ctx, :($sym.buf), Lvl, sym)
    VirtualDenseRLELevel(lvl_2, sym, Ti, shape, qos_fill, qos_stop, ptr, right, buf, prev_pos, i_prev, merge)
end

function lower(lvl::VirtualDenseRLELevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $DenseRLELevel{$(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
            $(lvl.ptr),
            $(lvl.right),
            $(ctx(lvl.buf));
            merge = $(lvl.merge)
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
        $(lvl.i_prev) = $(Ti(1)) - $unit
        $(lvl.prev_pos) = $(Tp(1))
    end)
    lvl.buf = declare_level!(lvl.buf, ctx, qos, init)
    return lvl
end

function assemble_level!(lvl::VirtualDenseRLELevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        Finch.resize_if_smaller!($(lvl.ptr), $pos_stop + 1)
        Finch.fill_range!($(lvl.ptr), 1, $pos_start + 1, $pos_stop + 1)
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
    Ti = lvl.Ti
    pos_2 = freshen(ctx.code, tag, :_pos)
    qos_stop = lvl.qos_stop
    qos_fill = lvl.qos_fill
    qos = freshen(ctx.code, :qos)
    unit = ctx(get_smallest_measure(virtual_level_size(lvl, ctx)[end]))
    push!(ctx.code.preamble, quote
        $qos = $(lvl.qos_fill)
        #if we did not write something to finish out the last run, we need to fill that in
        $qos += $(lvl.i_prev) < $(ctx(lvl.shape))
        #and all the runs after that
        $qos += $(pos_stop) - $(lvl.prev_pos)
        if $qos > $qos_stop
            $qos_stop = $qos
            Finch.resize_if_smaller!($(lvl.right), $qos_stop)
            Finch.fill_range!($(lvl.right), $(ctx(lvl.shape)), $qos_fill + 1, $qos_stop)
            $(contain(ctx_2->assemble_level!(lvl.buf, ctx_2, call(+, value(qos_fill, Tp), Tp(1)), value(qos_stop, Tp)), ctx))
        end
        resize!($(lvl.ptr), $pos_stop + 1)
        for $p = 1:$pos_stop
            $(lvl.ptr)[$p + 1] += $(lvl.ptr)[$p]
        end
        $qos_stop = $(lvl.ptr)[$pos_stop + 1] - 1
    end)
    if lvl.merge
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
                            prgm = instantiate!(ctx_2, prgm)
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
                        prgm = instantiate!(ctx_2, prgm)
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
    else
        push!(ctx.code.preamble, quote
            resize!($(lvl.right), $qos_stop)
        end)
        (lvl.buf, lvl.lvl) = (lvl.lvl, lvl.buf)
        lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
        return lvl
    end
end

function thaw_level!(lvl::VirtualDenseRLELevel, ctx::AbstractCompiler, pos_stop)
    error("Thaw is not yet implemented for DenseRLE level. To implement, we need to cache the last written qos as a Ref{Int}, then reconstruct prev_pos and i_prev from the ptr and right arrays")
    #=
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
    =#
end

function instantiate(fbr::VirtualSubFiber{VirtualDenseRLELevel}, ctx, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(walk)})
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

#Invariants of the level (Write Mode):
# 1. prevpos is the last position written (initially 0)
# 2. i_prev is the last index written (initially shape)
# 3. for all p in 1:prevpos-1, ptr[p] is the number of runs in that position
# 4. qos_fill is the position of the last index written

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
    qos_set = freshen(ctx.code, tag, :_qos_set)
    qos_3 = freshen(ctx.code, tag, :_qos_3)
    local_i_prev = freshen(ctx.code, tag, :_i_prev)
    
    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $qos = $qos_fill + 1
                $(if issafe(ctx.mode)
                    quote
                        $(lvl.prev_pos) <= $(ctx(pos)) || throw(FinchProtocolError("DenseRLELevels cannot be updated multiple times"))
                    end
                end)
                $local_i_prev = $(lvl.i_prev)
                #if the previous position is not the same as the current position, we will eventually need to fill in the gap
                if $(lvl.prev_pos) < $(ctx(pos))
                    $qos += $(ctx(pos)) - $(lvl.prev_pos) - 1
                    #only if we did not write something to finish out the last run do we eventually need to fill that in too
                    $qos += $(lvl.i_prev) < $(ctx(lvl.shape))
                    $local_i_prev = $(Ti(1)) - $unit 
                end
                $qos_set = $qos
            end,

            body = (ctx) -> AcceptRun(
                body = (ctx, ext) -> Thunk(
                    preamble = quote
                        $qos_3 = $qos + ($(local_i_prev) < ($(ctx(getstart(ext))) - $unit))
                        if $qos_3 > $qos_stop
                            $qos_2 = $qos_stop + 1
                            while $qos_3 > $qos_stop
                                $qos_stop = max($qos_stop << 1, 1)
                            end
                            Finch.resize_if_smaller!($(lvl.right), $qos_stop)
                            Finch.fill_range!($(lvl.right), $(ctx(lvl.shape)), $qos_2, $qos_stop)
                            $(contain(ctx_2->assemble_level!(lvl.buf, ctx_2, value(qos_2, Tp), value(qos_stop, Tp)), ctx))
                        end
                        $dirty = false
                    end,
                    body = (ctx) -> instantiate(VirtualHollowSubFiber(lvl.buf, value(qos_3, Tp), dirty), ctx, mode, subprotos),
                    epilogue = quote
                        if $dirty
                            $(lvl.right)[$qos] = $(ctx(getstart(ext))) - $unit
                            $(lvl.right)[$qos_3] = $(ctx(getstop(ext)))
                            $(qos) = $qos_3 + $(Tp(1))
                            $(local_i_prev) = $(ctx(getstop(ext)))
                        end
                    end
                )
            ),
            epilogue = quote
                if $qos - $qos_set > 0
                    $(fbr.dirty) = true
                    $(lvl.ptr)[$(ctx(pos)) + 1] += $qos - $qos_set - ($(local_i_prev) == $(ctx(lvl.shape))) #the last run is accounted for already because ptr starts out at 1
                    $(lvl.prev_pos) = $(ctx(pos))
                    $(lvl.i_prev) = $(local_i_prev)
                    $qos_fill = $qos - 1
                end
            end
        )
    )
end