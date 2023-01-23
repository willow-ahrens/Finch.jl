struct SparseListLevel{Ti, Tp, Lvl}
    I::Ti
    pos::Vector{Tp}
    idx::Vector{Ti}
    lvl::Lvl
end
const SparseList = SparseListLevel
SparseListLevel(lvl) = SparseListLevel(0, lvl)
SparseListLevel{Ti}(lvl) where {Ti} = SparseListLevel{Ti}(zero(Ti), lvl)
SparseListLevel{Ti, Tp}(lvl) where {Ti, Tp} = SparseListLevel{Ti, Tp}(zero(Ti), lvl)

SparseListLevel(I::Ti, lvl) where {Ti} = SparseListLevel{Ti}(I, lvl)
SparseListLevel{Ti}(I, lvl) where {Ti} = SparseListLevel{Ti, Int}(Ti(I), lvl)
SparseListLevel{Ti, Tp}(I, lvl::Lvl) where {Ti, Tp, Lvl} = SparseListLevel{Ti, Tp, Lvl}(Ti(I), Tp[1, 1], Ti[], lvl)

SparseListLevel(I::Ti, pos::Vector{Tp}, idx, lvl) where {Ti, Tp} = SparseListLevel{Ti}(I, pos, idx, lvl)
SparseListLevel{Ti}(I, pos::Vector{Tp}, idx, lvl::Lvl) where {Ti, Tp, Lvl} = SparseListLevel{Ti, Tp, Lvl}(Ti(I), pos, idx, lvl)
SparseListLevel{Ti, Tp}(I, pos, idx, lvl::Lvl) where {Ti, Tp, Lvl} = SparseListLevel{Ti, Tp, Lvl}(Ti(I), pos, idx, lvl)

"""
`f_code(l)` = [SparseListLevel](@ref).
"""
f_code(::Val{:sl}) = SparseList
summary_f_code(lvl::SparseListLevel) = "sl($(summary_f_code(lvl.lvl)))"
similar_level(lvl::SparseListLevel) = SparseList(similar_level(lvl.lvl))
similar_level(lvl::SparseListLevel, dim, tail...) = SparseList(dim, similar_level(lvl.lvl, tail...))

pattern!(lvl::SparseListLevel{Ti}) where {Ti} = 
    SparseListLevel{Ti}(lvl.I, lvl.pos, lvl.idx, pattern!(lvl.lvl))

function Base.show(io::IO, lvl::SparseListLevel{Ti, Tp}) where {Ti, Tp}
    if get(io, :compact, false)
        print(io, "SparseList(")
    else
        print(io, "SparseList{$Ti, $Tp}(")
    end
    show(IOContext(io, :typeinfo=>Ti), lvl.I)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>Vector{Tp}), lvl.pos)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Ti}), lvl.idx)
    end
    print(io, ", ")
    show(io, lvl.lvl)
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:SparseListLevel})
    p = envposition(fbr.env)
    crds = @view(fbr.lvl.idx[fbr.lvl.pos[p]:fbr.lvl.pos[p + 1] - 1])
    depth = envdepth(fbr.env)

    print_coord(io, crd) = (print(io, "["); show(io, crd); print(io, "]"))
    get_fbr(crd) = fbr(crd)

    print(io, "│ " ^ depth); print(io, "SparseList ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]")
    display_fiber_data(io, mime, fbr, 1, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:SparseListLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SparseListLevel) = (lvl.I, level_size(lvl.lvl)...)
@inline level_axes(lvl::SparseListLevel) = (Base.OneTo(lvl.I), level_axes(lvl.lvl)...)
@inline level_eltype(::Type{<:SparseListLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseListLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = level_default(Lvl)
(fbr::Fiber{<:SparseListLevel})() = fbr
function (fbr::Fiber{<:SparseListLevel{Ti}})(i, tail...) where {Ti}
    lvl = fbr.lvl
    p = envposition(fbr.env)
    r = searchsorted(@view(lvl.idx[lvl.pos[p]:lvl.pos[p + 1] - 1]), i)
    q = lvl.pos[p] + first(r) - 1
    fbr_2 = Fiber(lvl.lvl, Environment(position=q, index=i, parent=fbr.env))
    length(r) == 0 ? default(fbr_2) : fbr_2(tail...)
end

mutable struct VirtualSparseListLevel
    ex
    Ti
    Tp
    I
    qos_fill
    qos_stop
    lvl
end
function virtualize(ex, ::Type{SparseListLevel{Ti, Tp, Lvl}}, ctx, tag=:lvl) where {Ti, Tp, Lvl}
    sym = ctx.freshen(tag)
    I = value(:($sym.I), Int)
    qos_fill = ctx.freshen(sym, :_qos_fill)
    qos_stop = ctx.freshen(sym, :_qos_stop)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseListLevel(sym, Ti, Tp, I, qos_fill, qos_stop, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualSparseListLevel)
    quote
        $SparseListLevel{$(lvl.Ti)}(
            $(ctx(lvl.I)),
            $(lvl.ex).pos,
            $(lvl.ex).idx,
            $(ctx(lvl.lvl)),
        )
    end
end

summary_f_code(lvl::VirtualSparseListLevel) = "sl($(summary_f_code(lvl.lvl)))"

hasdefaultcheck(lvl::VirtualSparseListLevel) = true

function virtual_level_size(lvl::VirtualSparseListLevel, ctx)
    ext = Extent(literal(lvl.Ti(1)), lvl.I)
    (ext, virtual_level_size(lvl.lvl, ctx)...)
end

function virtual_level_resize!(lvl::VirtualSparseListLevel, ctx, dim, dims...)
    lvl.I = getstop(dim)
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseListLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseListLevel) = virtual_level_default(lvl.lvl)

function initialize_level!(lvl::VirtualSparseListLevel, ctx::LowerJulia, mode)
    Ti = lvl.Ti
    Tp = lvl.Tp
    push!(ctx.preamble, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
    end)
    lvl.lvl = initialize_level!(lvl.lvl, ctx, mode)
    return lvl
end

function trim_level!(lvl::VirtualSparseListLevel, ctx::LowerJulia, pos)
    qos = ctx.freshen(:qos)
    push!(ctx.preamble, quote
        resize!($(lvl.ex).pos, $(ctx(pos)) + 1)
        $qos = $(lvl.ex).pos[end] - $(lvl.Tp(1))
        resize!($(lvl.ex).idx, $qos)
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos, lvl.Tp))
    return lvl
end

function assemble_level!(lvl::VirtualSparseListLevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        $resize_if_smaller!($(lvl.ex).pos, $pos_stop + 1)
        $fill_range!($(lvl.ex).pos, 0, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(lvl::VirtualSparseListLevel, ctx::LowerJulia, pos_stop)
    p = ctx.freshen(:p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = ctx.freshen(:qos_stop)
    push!(ctx.preamble, quote
        $(lvl.ex).pos[1] = 1
        for $p = 2:($pos_stop + 1)
            $(lvl.ex).pos[$p] += $(lvl.ex).pos[$p - 1]
        end
        $qos_stop = $(lvl.ex).pos[$pos_stop + 1] - 1
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

function unfurl(fbr::VirtualFiber{VirtualSparseListLevel}, ctx, mode, ::Nothing, idx, idxs...)
    if idx.kind === protocol
        @assert idx.mode.kind === literal
        unfurl(fbr, ctx, mode, idx.mode.val, idx.idx, idxs...)
    elseif mode.kind === reader
        unfurl(fbr, ctx, mode, walk, idx, idxs...)
    else
        unfurl(fbr, ctx, mode, extrude, idx, idxs...)
    end
end

function unfurl(fbr::VirtualFiber{VirtualSparseListLevel}, ctx, mode, ::Walk, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)

    body = Thunk(
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_q_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + $(Tp(1))]
            $my_i = $my_q < $my_q_stop ? $(lvl.ex).idx[$my_q] : $(Ti(1))
            $my_i1 = $my_q < $my_q_stop ? $(lvl.ex).idx[$my_q_stop - $(Tp(1))] : $(Ti(0))
        end,
        body = Pipeline([
            Phase(
                stride = (ctx, idx, ext) -> value(my_i1),
                body = (start, step) -> Stepper(
                    seek = (ctx, ext) -> quote
                        while $my_q + $(Tp(1)) < $my_q_stop && $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                            $my_q += $(Tp(1))
                        end
                    end,
                    body = Thunk(
                        preamble = :(
                            $my_i = $(lvl.ex).idx[$my_q]
                        ),
                        body = Step(
                            stride = (ctx, idx, ext) -> value(my_i),
                            chunk = Spike(
                                body = Simplify(Fill(virtual_default(fbr))),
                                tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, Ti), index=value(my_i, Ti), parent=fbr.env)), ctx, mode),
                            ),
                            next = (ctx, idx, ext) -> quote
                                $my_q += $(Tp(1))
                            end
                        )
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(Fill(virtual_default(fbr))))
            )
        ])
    )

    exfurl(body, ctx, mode, idx)
end

function unfurl(fbr::VirtualFiber{VirtualSparseListLevel}, ctx, mode, ::FastWalk, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)

    body = Thunk(
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_q_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + $(Tp(1))]
            $my_i = $my_q < $my_q_stop ? $(lvl.ex).idx[$my_q] : $(Ti(1))
            $my_i1 = $my_q < $my_q_stop ? $(lvl.ex).idx[$my_q_stop - $(Tp(1))] : $(Ti(0))
        end,
        body = Pipeline([
            Phase(
                stride = (ctx, idx, ext) -> value(my_i1),
                body = (start, step) -> Stepper(
                    seek = (ctx, ext) -> quote
                        $my_q = $Tp(searchsortedfirst($(lvl.ex).idx, Int($(ctx(getstart(ext)))), Int($my_q), Int($my_q_stop - 1), Base.Forward))
                    end,
                    body = Thunk(
                        preamble = :(
                            $my_i = $(lvl.ex).idx[$my_q]
                        ),
                        body = Step(
                            stride = (ctx, idx, ext) -> value(my_i),
                            chunk = Spike(
                                body = Simplify(Fill(virtual_default(fbr))),
                                tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, Ti), index=value(my_i, Ti), parent=fbr.env)), ctx, mode),
                            ),
                            next = (ctx, idx, ext) -> quote
                                $my_q += $(Tp(1))
                            end
                        )
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(Fill(virtual_default(fbr))))
            )
        ])
    )

    exfurl(body, ctx, mode, idx)
end

function unfurl(fbr::VirtualFiber{VirtualSparseListLevel}, ctx, mode, ::Gallop, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)

    body = Thunk(
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_q_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            $my_i = $my_q < $my_q_stop ? $(lvl.ex).idx[$my_q] : $(Ti(1))
            $my_i1 = $my_q < $my_q_stop ? $(lvl.ex).idx[$my_q_stop - $(Tp(1))] : $(Ti(0))
        end,
        body = Pipeline([
            Phase(
                stride = (ctx, idx, ext) -> value(my_i1),
                body = (start, step) -> Jumper(
                    body = Thunk(
                        body = Jump(
                            seek = (ctx, ext) -> quote
                                while $my_q + $(Tp(1)) < $my_q_stop && $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                                    $my_q += $(Tp(1))
                                end
                                $my_i = $(lvl.ex).idx[$my_q]
                            end,
                            stride = (ctx, ext) -> value(my_i),
                            body = (ctx, ext, ext_2) -> Switch([
                                value(:($(ctx(getstop(ext_2))) == $my_i)) => Thunk(
                                    body = Spike(
                                        body = Simplify(Fill(virtual_default(fbr))),
                                        tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=value(my_i, lvl.Ti), parent=fbr.env)), ctx, mode),
                                    ),
                                    epilogue = quote
                                        $my_q += $(Tp(1))
                                    end
                                ),
                                literal(true) => Stepper(
                                    seek = (ctx, ext) -> quote
                                        while $my_q + $(Tp(1)) < $my_q_stop && $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                                            $my_q += $(Tp(1))
                                        end
                                    end,
                                    body = Thunk(
                                        preamble = :(
                                            $my_i = $(lvl.ex).idx[$my_q]
                                        ),
                                        body = Step(
                                            stride = (ctx, idx, ext) -> value(my_i),
                                            chunk = Spike(
                                                body = Simplify(Fill(virtual_default(fbr))),
                                                tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, Ti), index=value(my_i, Ti), parent=fbr.env)), ctx, mode),
                                            ),
                                            next = (ctx, idx, ext) -> quote
                                                $my_q += $(Tp(1))
                                            end
                                        )
                                    )
                                ),
                            ])
                        )
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(Fill(virtual_default(fbr))))
            )
        ])
    )

    exfurl(body, ctx, mode, idx)
end

function unfurl(fbr::VirtualFiber{VirtualSparseListLevel}, ctx, mode, ::Extrude, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_i = ctx.freshen(tag, :_i)
    qos = ctx.freshen(tag, :_qos)
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    my_i1 = ctx.freshen(tag, :_i1)
    my_guard = if hasdefaultcheck(lvl.lvl)
        ctx.freshen(tag, :_isdefault)
    end

    my_p = ctx.freshen(tag, :_p)

    push!(ctx.preamble, quote
        $qos = $qos_fill + 1
    end)
    body = AcceptSpike(
        val = virtual_default(fbr),
        tail = (ctx, idx) -> Thunk(
            preamble = quote
                if $qos > $qos_stop
                    $qos_stop = max($qos_stop << 1, 1)
                    $resize_if_smaller!($(lvl.ex).idx, $qos_stop)
                    $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, lvl.Tp), value(qos_stop, lvl.Tp)), ctx))
                end
                $(hasdefaultcheck(lvl.lvl) ? :($my_guard = true) : quote end)
            end,
            body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(qos, lvl.Ti), index=idx, guard=my_guard, parent=fbr.env)), ctx, mode),
            epilogue = begin
                body = quote
                    $(lvl.ex).idx[$qos] = $(ctx(idx))
                    $qos += $(Tp(1))
                end
                if envdefaultcheck(fbr.env) !== nothing
                    body = quote
                        $body
                        $(envdefaultcheck(fbr.env)) = false
                    end
                end
                if hasdefaultcheck(lvl.lvl)
                    body = quote
                        if !$(my_guard)
                            $body
                        end
                    end
                end
                body
            end
        )
    )

    push!(ctx.epilogue, quote
        $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1] = $qos - $qos_fill - 1
        $qos_fill = $qos - 1
    end)

    exfurl(body, ctx, mode, idx)
end