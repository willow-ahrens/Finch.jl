"""
    SparseCOOLevel{[N], [Ti=Tuple{Int...}], [Tp=Int]}(lvl, [dims])

A subfiber of a sparse level does not need to represent slices which are
entirely [`default`](@ref). Instead, only potentially non-default slices are
stored as subfibers in `lvl`. The sparse coo level corresponds to `N` indices in
the subfiber, so fibers in the sublevel are the slices `A[:, ..., :, i_1, ...,
i_n]`.  A set of `N` lists (one for each index) are used to record which slices
are stored. The coordinates (sets of `N` indices) are sorted in column major
order.  Optionally, `dims` are the sizes of the last dimensions.

`Ti` is the type of the last `N` fiber indices, and `Tp` is the type used for
positions in the level.

In the [`Fiber!`](@ref) constructor, `sh` is an alias for `SparseCOOLevel`.

```jldoctest
julia> Fiber!(Dense(SparseCOO{1}(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
Dense [:,1:3]
├─[:,1]: SparseCOO (0.0) [1:3]
│ ├─[1]: 10.0
│ ├─[2]: 30.0
├─[:,2]: SparseCOO (0.0) [1:3]
├─[:,3]: SparseCOO (0.0) [1:3]
│ ├─[1]: 20.0
│ ├─[3]: 40.0

julia> Fiber!(SparseCOO{2}(Element(0.0)), [10 0 20; 30 0 0; 0 0 40])
SparseCOO (0.0) [1:3,1:3]
├─├─[1, 1]: 10.0
├─├─[2, 1]: 30.0
├─├─[1, 3]: 20.0
├─├─[3, 3]: 40.0
```
"""
struct SparseCOOLevel{N, Ti<:Tuple, Tp, Tbl, Lvl}
    lvl::Lvl
    shape::Ti
    tbl::Tbl
    ptr::Vector{Tp}
end
const SparseCOO = SparseCOOLevel

SparseCOOLevel(lvl) = throw(ArgumentError("You must specify the number of dimensions in a SparseCOOLevel, e.g. Fiber!(SparseCOO{2}(Element(0.0)))"))
SparseCOOLevel(lvl, shape, args...) = SparseCOOLevel{length(shape)}(lvl, shape, args...)
SparseCOOLevel{N}(lvl) where {N} = SparseCOOLevel{N, NTuple{N, Int}}(lvl)
SparseCOOLevel{N}(lvl, shape, args...) where {N} = SparseCOOLevel{N, typeof(shape)}(lvl, shape, args...)

SparseCOOLevel{N, Ti}(lvl, args...) where {N, Ti} = SparseCOOLevel{N, Ti, Int}(lvl, args...)
SparseCOOLevel{N, Ti, Tp}(lvl::Lvl, args...) where {N, Ti, Tp, Lvl} =
    SparseCOOLevel{N, Ti, Tp, Tuple{(Vector{ti} for ti in Ti.parameters)...}, Lvl}(lvl, args...)

SparseCOOLevel{N, Ti, Tp, Tbl, Lvl}(lvl) where {N, Ti, Tp, Tbl, Lvl} =
    SparseCOOLevel{N, Ti, Tp, Tbl, Lvl}(lvl, ((zero(ti) for ti in Ti.parameters)...,))
SparseCOOLevel{N, Ti, Tp, Tbl, Lvl}(lvl, shape) where {N, Ti, Tp, Tbl, Lvl} =
    SparseCOOLevel{N, Ti, Tp, Tbl, Lvl}(lvl, Ti(shape), ((Vector{ti}() for ti in Ti.parameters)...,), Tp[1])

Base.summary(lvl::SparseCOOLevel{N}) where {N} = "SparseCOO{$N}($(summary(lvl.lvl)))"
similar_level(lvl::SparseCOOLevel{N}) where {N} = SparseCOOLevel{N}(similar_level(lvl.lvl))
similar_level(lvl::SparseCOOLevel{N}, tail...) where {N} = SparseCOOLevel{N}(similar_level(lvl.lvl, tail[1:end-N]...), (tail[end-N+1:end]...,))

pattern!(lvl::SparseCOOLevel{N, Ti, Tp}) where {N, Ti, Tp} = 
    SparseCOOLevel{N, Ti, Tp}(pattern!(lvl.lvl), lvl.shape, lvl.tbl, lvl.ptr)

function countstored_level(lvl::SparseCOOLevel, pos)
    countstored_level(lvl.lvl, lvl.ptr[pos + 1] - 1)
end

redefault!(lvl::SparseCOOLevel{N, Ti, Tp}, init) where {N, Ti, Tp} = 
    SparseCOOLevel{N, Ti, Tp}(redefault!(lvl.lvl, init), lvl.shape, lvl.tbl, lvl.ptr)

function Base.show(io::IO, lvl::SparseCOOLevel{N, Ti, Tp}) where {N, Ti, Tp}
    if get(io, :compact, false)
        print(io, "SparseCOO{$N}(")
    else
        print(io, "SparseCOO{$N, $Ti, $Tp}(")
    end
    show(io, lvl.lvl)
    print(io, ", ")
    show(IOContext(io, :typeinfo=>Ti), lvl.shape)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        print(io, "(")
        for (n, ti) = enumerate(Ti.parameters)
            print(io, ti) #TODO we have to do something about this.
            show(IOContext(io, :typeinfo=>Vector{ti}), lvl.tbl[n])
            print(io, ", ")
        end
        print(io, "), ")
        show(IOContext(io, :typeinfo=>Vector{Tp}), lvl.ptr)
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:SparseCOOLevel{N}}, depth) where {N}
    p = fbr.pos
    crds = fbr.lvl.ptr[p]:fbr.lvl.ptr[p + 1] - 1

    print_coord(io, q) = join(io, map(n -> fbr.lvl.tbl[n][q], 1:N), ", ")
    get_fbr(q) = fbr(map(n -> fbr.lvl.tbl[n][q], 1:N)...)

    print(io, "SparseCOO (", default(fbr), ") [", ":,"^(ndims(fbr) - N), "1:")
    join(io, fbr.lvl.shape, ",1:") 
    print(io, "]")
    display_fiber_data(io, mime, fbr, depth, N, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:SparseCOOLevel{N, Ti, Tp, Tbl, Lvl}}) where {N, Ti, Tp, Tbl, Lvl} = N + level_ndims(Lvl)
@inline level_size(lvl::SparseCOOLevel) = (level_size(lvl.lvl)..., lvl.shape...)
@inline level_axes(lvl::SparseCOOLevel) = (level_axes(lvl.lvl)..., map(Base.OneTo, lvl.shape)...)
@inline level_eltype(::Type{<:SparseCOOLevel{N, Ti, Tp, Tbl, Lvl}}) where {N, Ti, Tp, Tbl, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseCOOLevel{N, Ti, Tp, Tbl, Lvl}}) where {N, Ti, Tp, Tbl, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:SparseCOOLevel{N, Ti, Tp, Tbl, Lvl}}) where {N, Ti, Tp, Tbl, Lvl} = (SparseData^N)(data_rep_level(Lvl))

(fbr::AbstractFiber{<:SparseCOOLevel})() = fbr
(fbr::SubFiber{<:SparseCOOLevel})() = fbr
function (fbr::SubFiber{<:SparseCOOLevel{N, Ti}})(idxs...) where {N, Ti}
    isempty(idxs) && return fbr
    idx = idxs[end-N + 1:end]
    lvl = fbr.lvl
    target = lvl.ptr[fbr.pos]:lvl.ptr[fbr.pos + 1] - 1
    for n = N:-1:1
        target = searchsorted(view(lvl.tbl[n], target), idx[n]) .+ (first(target) - 1)
    end
    isempty(target) ? default(fbr) : SubFiber(lvl.lvl, first(target))(idxs[1:end-N]...)
end

mutable struct VirtualSparseCOOLevel <: AbstractVirtualLevel
    lvl
    ex
    N
    Ti
    Tp
    Tbl
    shape
    qos_fill
    qos_stop
    prev_pos
end

is_level_injective(lvl::VirtualSparseCOOLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., (true for _ in 1:lvl.N)...]
is_level_concurrent(lvl::VirtualSparseCOOLevel, ctx) = [is_level_concurrent(lvl.lvl, ctx)..., (true for _ in 1:lvl.N)...]
is_level_atomic(lvl::VirtualSparseCOOLevel, ctx) = false

function virtualize(ex, ::Type{SparseCOOLevel{N, Ti, Tp, Tbl, Lvl}}, ctx, tag=:lvl) where {N, Ti, Tp, Tbl, Lvl}   
    sym = freshen(ctx, tag)
    shape = map(n->value(:($sym.shape[$n]), Int), 1:N)
    qos_fill = freshen(ctx, sym, :_qos_fill)
    qos_stop = freshen(ctx, sym, :_qos_stop)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    prev_pos = freshen(ctx, sym, :_prev_pos)
    prev_coord = map(n->freshen(ctx, sym, :_prev_coord_, n), 1:N)
    VirtualSparseCOOLevel(lvl_2, sym, N, Ti, Tp, Tbl, shape, qos_fill, qos_stop, prev_pos)
end
function lower(lvl::VirtualSparseCOOLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $SparseCOOLevel{$(lvl.N), $(lvl.Ti), $(lvl.Tp)}(
            $(ctx(lvl.lvl)),
            ($(map(ctx, lvl.shape)...),),
            $(lvl.ex).tbl,
            $(lvl.ex).ptr,
        )
    end
end

Base.summary(lvl::VirtualSparseCOOLevel) = "SparseCOO{$(lvl.N)}($(summary(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSparseCOOLevel, ctx::AbstractCompiler)
    ext = map((ti, stop)->Extent(literal(ti(1)), stop), lvl.Ti.parameters, lvl.shape)
    (virtual_level_size(lvl.lvl, ctx)..., ext...)
end

function virtual_level_resize!(lvl::VirtualSparseCOOLevel, ctx::AbstractCompiler, dims...)
    lvl.shape = map(getstop, dims[end - lvl.N + 1:end])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end - lvl.N]...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseCOOLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseCOOLevel) = virtual_level_default(lvl.lvl)

function declare_level!(lvl::VirtualSparseCOOLevel, ctx::AbstractCompiler, pos, init)
    Ti = lvl.Ti
    Tp = lvl.Tp

    qos = call(-, call(getindex, :($(lvl.ex).ptr), call(+, pos, 1)), 1)
    push!(ctx.code.preamble, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
    end)
    if issafe(ctx.mode)
        push!(ctx.code.preamble, quote
            $(lvl.prev_pos) = $(Tp(0))
        end)
    end
    lvl.lvl = declare_level!(lvl.lvl, ctx, qos, init)
    return lvl
end

function trim_level!(lvl::VirtualSparseCOOLevel, ctx::AbstractCompiler, pos)
    Tp = lvl.Tp
    qos = freshen(ctx.code, :qos)

    push!(ctx.code.preamble, quote
        resize!($(lvl.ex).ptr, $(ctx(pos)) + 1)
        $qos = $(lvl.ex).ptr[end] - $(Tp(1))
        $(Expr(:block, map(1:lvl.N) do n
            :(resize!($(lvl.ex).tbl[$n], $qos))
        end...))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos, Tp))
    return lvl
end

function assemble_level!(lvl::VirtualSparseCOOLevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        Finch.resize_if_smaller!($(lvl.ex).ptr, $pos_stop + 1)
        Finch.fill_range!($(lvl.ex).ptr, 0, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(lvl::VirtualSparseCOOLevel, ctx::AbstractCompiler, pos_stop)
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        for $p = 2:($pos_stop + 1)
            $(lvl.ex).ptr[$p] += $(lvl.ex).ptr[$p - 1]
        end
        $qos_stop = $(lvl.ex).ptr[$pos_stop + 1] - 1
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

struct SparseCOOWalkTraversal
    lvl
    R
    start
    stop
end

function instantiate_reader(fbr::VirtualSubFiber{VirtualSparseCOOLevel}, ctx, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    start = value(:($(lvl.ex).ptr[$(ctx(pos))]), lvl.Tp)
    stop = value(:($(lvl.ex).ptr[$(ctx(pos)) + 1]), lvl.Tp)

    instantiate_reader(SparseCOOWalkTraversal(lvl, lvl.N, start, stop), ctx, protos)
end

function instantiate_reader(trv::SparseCOOWalkTraversal, ctx, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    (lvl, R, start, stop) = (trv.lvl, trv.R, trv.start, trv.stop)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    my_i = freshen(ctx.code, tag, :_i)
    my_q = freshen(ctx.code, tag, :_q)
    my_q_step = freshen(ctx.code, tag, :_q_step)
    my_q_stop = freshen(ctx.code, tag, :_q_stop)
    my_i_stop = freshen(ctx.code, tag, :_i_stop)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_q = $(ctx(start))
                $my_q_stop = $(ctx(stop))
                if $my_q < $my_q_stop
                    $my_i = $(lvl.ex).tbl[$R][$my_q]
                    $my_i_stop = $(lvl.ex).tbl[$R][$my_q_stop - 1]
                else
                    $my_i = $(Ti.parameters[R](1))
                    $my_i_stop = $(Ti.parameters[R](0))
                end
            end,
            body = (ctx) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> value(my_i_stop),
                    body = (ctx, ext) -> Stepper(
                        seek = (ctx, ext) -> quote
                            if $(lvl.ex).tbl[$R][$my_q] < $(ctx(getstart(ext)))
                                $my_q = Finch.scansearch($(lvl.ex).tbl[$R], $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                            end
                        end,
                        body = if R == 1
                            Thunk(
                                preamble = quote
                                    $my_i = $(lvl.ex).tbl[$R][$my_q]
                                end,
                                body = (ctx) -> Step(
                                    stop =  (ctx, ext) -> value(my_i),
                                    chunk = Spike(
                                        body = Fill(virtual_level_default(lvl)),
                                        tail = instantiate_reader(VirtualSubFiber(lvl.lvl, my_q), ctx, subprotos),
                                    ),
                                    next = (ctx, ext) -> quote
                                        $my_q += $(Tp(1))
                                    end
                                )
                            )
                        else
                            Thunk(
                                preamble = quote
                                    $my_i = $(lvl.ex).tbl[$R][$my_q]
                                    $my_q_step = $my_q
                                    if $(lvl.ex).tbl[$R][$my_q_step] == $my_i
                                        $my_q_step = Finch.scansearch($(lvl.ex).tbl[$R], $my_i + 1, $my_q_step, $my_q_stop - 1)
                                    end
                                end,
                                body = (ctx) -> Step(
                                    stop = (ctx, ext) -> value(my_i),
                                    chunk = Spike(
                                        body = Fill(virtual_level_default(lvl)),
                                        tail = instantiate_reader(SparseCOOWalkTraversal(lvl, R - 1, value(my_q, lvl.Ti), value(my_q_step, lvl.Ti)), ctx, subprotos),
                                    ),
                                    next = (ctx, ext) -> quote
                                        $my_q = $my_q_step
                                    end
                                )
                            )
                        end
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    )
end

struct SparseCOOExtrudeTraversal
    lvl
    qos
    fbr_dirty
    coords
    prev_coord
end

instantiate_updater(fbr::VirtualSubFiber{VirtualSparseCOOLevel}, ctx, protos) =
    instantiate_updater(VirtualTrackedSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, protos)
function instantiate_updater(fbr::VirtualTrackedSubFiber{VirtualSparseCOOLevel}, ctx, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop

    qos = freshen(ctx.code, tag, :_q)
    prev_coord = freshen(ctx.code, tag, :_prev_coord)
    Thunk(
        preamble = quote
            $qos = $qos_fill + 1
            $(if issafe(ctx.mode)
                quote
                    $(lvl.prev_pos) < $(ctx(pos)) || throw(FinchProtocolError("SparseCOOLevels cannot be updated multiple times"))
                    $prev_coord = ()
                end
            end)
        end,
        body = (ctx) -> instantiate_updater(SparseCOOExtrudeTraversal(lvl, qos, fbr.dirty, [], prev_coord), ctx, protos),
        epilogue = quote
            $(lvl.ex).ptr[$(ctx(pos)) + 1] = $qos - $qos_fill - 1
            $(if issafe(ctx.mode)
                quote
                    if $qos - $qos_fill - 1 > 0
                        $(lvl.prev_pos) = $(ctx(pos))
                    end
                end
            end)
            $qos_fill = $qos - 1
        end
    )
end

function instantiate_updater(trv::SparseCOOExtrudeTraversal, ctx, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    (lvl, qos, fbr_dirty, coords) = (trv.lvl, trv.qos, trv.fbr_dirty, trv.coords)
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    Furlable(
        body = (ctx, ext) -> 
            if length(coords) + 1 < lvl.N
                Lookup(
                    body = (ctx, i) -> instantiate_updater(SparseCOOExtrudeTraversal(lvl, qos, fbr_dirty, (i, coords...), trv.prev_coord), ctx, subprotos),
                )
            else
                dirty = freshen(ctx.code, :dirty)
                Lookup(
                    body = (ctx, idx) -> Thunk(
                        preamble = quote
                            if $qos > $qos_stop
                                $qos_stop = max($qos_stop << 1, 1)
                                $(Expr(:block, map(1:lvl.N) do n
                                    :(Finch.resize_if_smaller!($(lvl.ex).tbl[$n], $qos_stop))
                                end...))
                                $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, lvl.Tp), value(qos_stop, lvl.Tp)), ctx))
                            end
                            $dirty = false
                        end,
                        body = (ctx) -> instantiate_updater(VirtualTrackedSubFiber(lvl.lvl, value(qos, lvl.Tp), dirty), ctx, subprotos),
                        epilogue = begin
                            coords_2 = map(ctx, (idx, coords...))
                            quote
                                if $dirty
                                    $(if issafe(ctx.mode)
                                        quote
                                            $(trv.prev_coord) < ($(reverse(coords_2)...),) || begin
                                                throw(FinchProtocolError("SparseCOOLevels cannot be updated multiple times"))
                                            end
                                            $(trv.prev_coord) = ($(reverse(coords_2)...),)
                                        end
                                    end)
                                    $(fbr_dirty) = true
                                    $(Expr(:block, map(enumerate(coords_2)) do (n, i)
                                        :($(lvl.ex).tbl[$n][$qos] = $i)
                                    end...))
                                    $qos += $(Tp(1))
                                end
                            end
                        end
                    )
                )
            end
    )
end
