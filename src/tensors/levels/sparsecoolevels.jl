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

In the [`@fiber`](@ref) constructor, `sh` is an alias for `SparseCOOLevel`.

```jldoctest
julia> @fiber(d(sc{1}(e(0.0))), [10 0 20; 30 0 0; 0 0 40])
Dense [:,1:3]
├─[:,1]: SparseCOO (0.0) [1:3]
│ ├─[1]: 10.0
│ ├─[2]: 30.0
├─[:,2]: SparseCOO (0.0) [1:3]
├─[:,3]: SparseCOO (0.0) [1:3]
│ ├─[1]: 20.0
│ ├─[3]: 40.0

julia> @fiber(sc{2}(e(0.0)), [10 0 20; 30 0 0; 0 0 40])
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

SparseCOOLevel(lvl) = throw(ArgumentError("You must specify the number of dimensions in a SparseCOOLevel, e.g. @fiber(sc{2}(e(0.0)))"))
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

"""
`fiber_abbrev(sc)` = [`SparseCOOLevel`](@ref).
"""
fiber_abbrev(::Val{:sc}) = SparseCOO
summary_fiber_abbrev(lvl::SparseCOOLevel{N}) where {N} = "sc{$N}($(summary_fiber_abbrev(lvl.lvl)))"
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

mutable struct VirtualSparseCOOLevel
    lvl
    ex
    N
    Ti
    Tp
    Tbl
    shape
    qos_fill
    qos_stop
end
function virtualize(ex, ::Type{SparseCOOLevel{N, Ti, Tp, Tbl, Lvl}}, ctx, tag=:lvl) where {N, Ti, Tp, Tbl, Lvl}   
    sym = ctx.freshen(tag)
    shape = map(n->value(:($sym.shape[$n]), Int), 1:N)
    qos_fill = ctx.freshen(sym, :_qos_fill)
    qos_stop = ctx.freshen(sym, :_qos_stop)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseCOOLevel(lvl_2, sym, N, Ti, Tp, Tbl, shape, qos_fill, qos_stop)
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

summary_fiber_abbrev(lvl::VirtualSparseCOOLevel) = "sc{$(lvl.N)}($(summary_fiber_abbrev(lvl.lvl)))"

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
    push!(ctx.preamble, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
    end)
    lvl.lvl = declare_level!(lvl.lvl, ctx, qos, init)
    return lvl
end

function trim_level!(lvl::VirtualSparseCOOLevel, ctx::AbstractCompiler, pos)
    Tp = lvl.Tp
    qos = ctx.freshen(:qos)

    push!(ctx.preamble, quote
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
        $resize_if_smaller!($(lvl.ex).ptr, $pos_stop + 1)
        $fill_range!($(lvl.ex).ptr, 0, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(lvl::VirtualSparseCOOLevel, ctx::AbstractCompiler, pos_stop)
    p = ctx.freshen(:p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = ctx.freshen(:qos_stop)
    push!(ctx.preamble, quote
        for $p = 2:($pos_stop + 1)
            $(lvl.ex).ptr[$p] += $(lvl.ex).ptr[$p - 1]
        end
        $qos_stop = $(lvl.ex).ptr[$pos_stop + 1] - 1
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

function unfurl_reader(fbr::VirtualSubFiber{VirtualSparseCOOLevel}, ctx, protos...)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    start = value(:($(lvl.ex).ptr[$(ctx(pos))]), lvl.Tp)
    stop = value(:($(lvl.ex).ptr[$(ctx(pos)) + 1]), lvl.Tp)

    unfurl_reader_coo_helper(lvl::VirtualSparseCOOLevel, ctx, lvl.N, start, stop, protos...)
end

function unfurl_reader_coo_helper(lvl::VirtualSparseCOOLevel, ctx, R, start, stop, ::Union{typeof(defaultread), typeof(walk)}, protos...)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_step = ctx.freshen(tag, :_q_step)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)

    Furlable(
        size = virtual_level_size(lvl, ctx)[R:end],
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
            body = (ctx) -> Pipeline([
                Phase(
                    stop = (ctx, ext) -> value(my_i_stop),
                    body = (ctx, ext) -> Stepper(
                        seek = (ctx, ext) -> quote
                            if $(lvl.ex).tbl[$R][$my_q] < $(ctx(getstart(ext)))
                                $my_q = scansearch($(lvl.ex).tbl[$R], $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                            end
                        end,
                        body = if R == 1
                            Thunk(
                                preamble = quote
                                    $my_i = $(lvl.ex).tbl[$R][$my_q]
                                end,
                                body = (ctx) -> Step(
                                    stop =  (ctx, ext) -> value(my_i),
                                    body = Spike(
                                        body = Fill(virtual_level_default(lvl)),
                                        tail = unfurl_reader(VirtualSubFiber(lvl.lvl, my_q), ctx, protos...),
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
                                        $my_q_step = scansearch($(lvl.ex).tbl[$R], $my_i + 1, $my_q_step, $my_q_stop - 1)
                                    end
                                end,
                                body = (ctx) -> Step(
                                    stop = (ctx, ext) -> value(my_i),
                                    body = Spike(
                                        body = Fill(virtual_level_default(lvl)),
                                        tail = unfurl_reader_coo_helper(lvl, ctx, R - 1, value(my_q, lvl.Ti), value(my_q_step, lvl.Ti), protos...),
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

is_laminable_updater(lvl::VirtualSparseCOOLevel, ctx, protos...) = false
unfurl_updater(fbr::VirtualSubFiber{VirtualSparseCOOLevel}, ctx, protos...) =
    unfurl_updater(VirtualTrackedSubFiber(fbr.lvl, fbr.pos, ctx.freshen(:null)), ctx, protos...)
function unfurl_updater(fbr::VirtualTrackedSubFiber{VirtualSparseCOOLevel}, ctx, protos...)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop

    qos = ctx.freshen(tag, :_q)
    Thunk(
        preamble = quote
            $qos = $qos_fill + 1
        end,
        body = (ctx) -> unfurl_updater_coo_helper(lvl, ctx, qos, fbr.dirty, (), protos...),
        epilogue = quote
            $(lvl.ex).ptr[$(ctx(pos)) + 1] = $qos - $qos_fill - 1
            $qos_fill = $qos - 1
        end
    )
end

function unfurl_updater_coo_helper(lvl::VirtualSparseCOOLevel, ctx, qos, fbr_dirty, coords, ::Union{typeof(defaultupdate), typeof(extrude)}, protos...)
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    Furlable(
        tight = lvl,
        size = virtual_level_size(lvl, ctx)[length(coords) + 1:end],
        body = (ctx, ext) -> 
            if length(coords) + 1 < lvl.N
                Lookup(
                    body = (ctx, i) -> unfurl_updater_coo_helper(lvl, ctx, qos, fbr_dirty, (i, coords...), protos...)
                )
            else
                dirty = ctx.freshen(:dirty)
                Lookup(
                    body = (ctx, idx) -> Thunk(
                        preamble = quote
                            if $qos > $qos_stop
                                $qos_stop = max($qos_stop << 1, 1)
                                $(Expr(:block, map(1:lvl.N) do n
                                    :(resize_if_smaller!($(lvl.ex).tbl[$n], $qos_stop))
                                end...))
                                $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, lvl.Tp), value(qos_stop, lvl.Tp)), ctx))
                            end
                            $dirty = false
                        end,
                        body = (ctx) -> unfurl_updater(VirtualTrackedSubFiber(lvl.lvl, qos, dirty), ctx, protos...),
                        epilogue = quote
                            if $dirty
                                $(fbr_dirty) = true
                                $(Expr(:block, map(enumerate((idx, coords...))) do (n, i)
                                    :($(lvl.ex).tbl[$n][$qos] = $(ctx(i)))
                                end...))
                                $qos += $(Tp(1))
                            end
                        end
                    )
                )
            end
    )
end