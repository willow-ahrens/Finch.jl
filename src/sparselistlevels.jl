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
    get_coord(crd) = crd

    print(io, "│ " ^ depth); print(io, "SparseList ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]")
    display_fiber_data(io, mime, fbr, 1, crds, print_coord, get_coord)
end


@inline Base.ndims(fbr::Fiber{<:SparseListLevel}) = 1 + ndims(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline Base.size(fbr::Fiber{<:SparseListLevel}) = (fbr.lvl.I, size(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline Base.axes(fbr::Fiber{<:SparseListLevel}) = (1:fbr.lvl.I, axes(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline Base.eltype(fbr::Fiber{<:SparseListLevel}) = eltype(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline default(fbr::Fiber{<:SparseListLevel}) = default(Fiber(fbr.lvl.lvl, Environment(fbr.env)))

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
    pos_fill
    pos_stop
    pos_alloc
    idx_alloc
    lvl
end
function virtualize(ex, ::Type{SparseListLevel{Ti, Tp, Lvl}}, ctx, tag=:lvl) where {Ti, Tp, Lvl}
    sym = ctx.freshen(tag)
    I = value(:($sym.I), Int)
    pos_fill = ctx.freshen(sym, :_pos_fill)
    pos_stop = ctx.freshen(sym, :_pos_stop)
    pos_alloc = ctx.freshen(sym, :_pos_alloc)
    idx_alloc = ctx.freshen(sym, :_idx_alloc)
    push!(ctx.preamble, quote
        $sym = $ex
        $pos_alloc = length($sym.pos)
        $idx_alloc = length($sym.idx)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseListLevel(sym, Ti, Tp, I, pos_fill, pos_stop, pos_alloc, idx_alloc, lvl_2)
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

getsites(fbr::VirtualFiber{VirtualSparseListLevel}) =
    [envdepth(fbr.env) + 1, getsites(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))...]

function getsize(fbr::VirtualFiber{VirtualSparseListLevel}, ctx, mode)
    ext = Extent(literal(1), fbr.lvl.I)
    if mode.kind !== reader
        ext = suggest(ext)
    end
    (ext, getsize(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)...)
end

function setsize!(fbr::VirtualFiber{VirtualSparseListLevel}, ctx, mode, dim, dims...)
    fbr.lvl.I = getstop(dim)
    fbr.lvl.lvl = setsize!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode, dims...).lvl
    fbr
end

@inline default(fbr::VirtualFiber{<:VirtualSparseListLevel}) = default(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))
Base.eltype(fbr::VirtualFiber{VirtualSparseListLevel}) = eltype(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualSparseListLevel}, ctx::LowerJulia, mode)
    lvl = fbr.lvl
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = length($(lvl.ex).pos)
        $(lvl.pos_fill) = 1
        $(lvl.pos_stop) = 2
        $(lvl.ex).pos[1] = 1
        $(lvl.ex).pos[2] = 1
        $(lvl.idx_alloc) = length($(lvl.ex).idx)
    end)
    lvl.lvl = initialize_level!(VirtualFiber(fbr.lvl.lvl, Environment(fbr.env)), ctx, mode)
    return lvl
end

function trim_level!(lvl::VirtualSparseListLevel, ctx::LowerJulia, pos)
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = $(ctx(pos)) + 1
        resize!($(lvl.ex).pos, $(lvl.pos_alloc))
        $(lvl.idx_alloc) = $(lvl.ex).pos[$(lvl.pos_alloc)] - 1
        resize!($(lvl.ex).idx, $(lvl.idx_alloc))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, lvl.idx_alloc)
    return lvl
end

interval_assembly_depth(lvl::VirtualSparseListLevel) = Inf

#This function is quite simple, since SparseListLevels don't support reassembly.
function assemble!(fbr::VirtualFiber{VirtualSparseListLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), getstop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) < ($p_stop + 1) && ($(lvl.pos_alloc) = $Finch.refill!($(lvl.ex).pos, 0, $(lvl.pos_alloc), $p_stop + 1))
        $(lvl.pos_stop) = $p_stop + 1
    end)
end

function finalize_level!(fbr::VirtualFiber{VirtualSparseListLevel}, ctx::LowerJulia, mode)
    lvl = fbr.lvl
    my_p = ctx.freshen(:p)
    my_q = ctx.freshen(:q)
    push!(ctx.preamble, quote
        $my_q = $(lvl.ex).pos[$(lvl.pos_fill)]
        for $my_p = $(lvl.pos_fill):$(lvl.pos_stop)
            $(lvl.ex).pos[$(my_p)] = $my_q
        end
    end)
    fbr.lvl.lvl = finalize_level!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)
    return fbr.lvl
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
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)

    body = Thunk(
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_q_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_q < $my_q_stop
                $my_i = $(lvl.ex).idx[$my_q]
                $my_i1 = $(lvl.ex).idx[$my_q_stop - 1]
            else
                $my_i = 1
                $my_i1 = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (ctx, idx, ext) -> value(my_i1),
                body = (start, step) -> Stepper(
                    seek = (ctx, ext) -> quote
                        #$my_q = searchsortedfirst($(lvl.ex).idx, $start, $my_q, $my_q_stop, Base.Forward)
                        while $my_q < $my_q_stop && $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                            $my_q += 1
                        end
                    end,
                    body = Thunk(
                        preamble = :(
                            $my_i = $(lvl.ex).idx[$my_q]
                        ),
                        body = Step(
                            stride = (ctx, idx, ext) -> value(my_i),
                            chunk = Spike(
                                body = Simplify(Fill(default(fbr))),
                                tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=value(my_i, lvl.Ti), parent=fbr.env)), ctx, mode),
                            ),
                            next = (ctx, idx, ext) -> quote
                                $my_q += 1
                            end
                        )
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(Fill(default(fbr))))
            )
        ])
    )

    exfurl(body, ctx, mode, idx)
end

function unfurl(fbr::VirtualFiber{VirtualSparseListLevel}, ctx, mode, ::FastWalk, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)

    body = Thunk(
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_q_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_q < $my_q_stop
                $my_i = $(lvl.ex).idx[$my_q]
                $my_i1 = $(lvl.ex).idx[$my_q_stop - 1]
            else
                $my_i = 1
                $my_i1 = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (ctx, idx, ext) -> value(my_i1),
                body = (start, step) -> Stepper(
                    seek = (ctx, ext) -> quote
                        $my_q = searchsortedfirst($(lvl.ex).idx, $(ctx(getstart(ext))), $my_q, $my_q_stop, Base.Forward)
                        #while $my_q < $my_q_stop && $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                        #    $my_q += 1
                        #end
                    end,
                    body = Thunk(
                        preamble = :(
                            $my_i = $(lvl.ex).idx[$my_q]
                        ),
                        body = Step(
                            stride = (ctx, idx, ext) -> value(my_i),
                            chunk = Spike(
                                body = Simplify(Fill(default(fbr))),
                                tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=value(my_i, lvl.Ti), parent=fbr.env)), ctx, mode),
                            ),
                            next = (ctx, idx, ext) -> quote
                                $my_q += 1
                            end
                        )
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(Fill(default(fbr))))
            )
        ])
    )

    exfurl(body, ctx, mode, idx)
end

function unfurl(fbr::VirtualFiber{VirtualSparseListLevel}, ctx, mode, ::Gallop, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)

    body = Thunk(
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_q_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_q < $my_q_stop
                $my_i = $(lvl.ex).idx[$my_q]
                $my_i1 = $(lvl.ex).idx[$my_q_stop - 1]
            else
                $my_i = 1
                $my_i1 = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (ctx, idx, ext) -> value(my_i1),
                body = (start, step) -> Jumper(
                    body = Thunk(
                        body = Jump(
                            seek = (ctx, ext) -> quote
                                #$my_q = searchsortedfirst($(lvl.ex).idx, $start, $my_q, $my_q_stop, Base.Forward)
                                while $my_q < $my_q_stop && $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                                    $my_q += 1
                                end
                                $my_i = $(lvl.ex).idx[$my_q]
                            end,
                            stride = (ctx, ext) -> value(my_i),
                            body = (ctx, ext, ext_2) -> Switch([
                                value(:($(ctx(getstop(ext_2))) == $my_i)) => Thunk(
                                    body = Spike(
                                        body = Simplify(Fill(default(fbr))),
                                        tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=value(my_i, lvl.Ti), parent=fbr.env)), ctx, mode),
                                    ),
                                    epilogue = quote
                                        $my_q += 1
                                    end
                                ),
                                literal(true) => Stepper(
                                    seek = (ctx, ext) -> quote
                                        #$my_q = searchsortedfirst($(lvl.ex).idx, $start, $my_q, $my_q_stop, Base.Forward)
                                        while $my_q < $my_q_stop && $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                                            $my_q += 1
                                        end
                                    end,
                                    body = Thunk(
                                        preamble = :(
                                            $my_i = $(lvl.ex).idx[$my_q]
                                        ),
                                        body = Step(
                                            stride = (ctx, idx, ext) -> value(my_i),
                                            chunk = Spike(
                                                body = Simplify(Fill(default(fbr))),
                                                tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=value(my_i, lvl.Ti), parent=fbr.env)), ctx, mode),
                                            ),
                                            next = (ctx, idx, ext) -> quote
                                                $my_q += 1
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
                body = (start, step) -> Run(Simplify(Fill(default(fbr))))
            )
        ])
    )

    exfurl(body, ctx, mode, idx)
end

function unfurl(fbr::VirtualFiber{VirtualSparseListLevel}, ctx, mode, ::Extrude, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)
    my_guard = if hasdefaultcheck(lvl.lvl)
        ctx.freshen(tag, :_isdefault)
    end

    my_p = ctx.freshen(tag, :_p)


    push!(ctx.preamble, quote
        $my_q = $(lvl.ex).pos[$(lvl.pos_fill)]
        for $my_p = $(lvl.pos_fill):$(ctx(envposition(fbr.env)))
            $(lvl.ex).pos[$(my_p)] = $my_q
        end
    end)

    body = AcceptSpike(
        val = default(fbr),
        tail = (ctx, idx) -> Thunk(
            preamble = quote
                $(begin
                    assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), parent=fbr.env)), ctx, mode)
                    quote end
                end)
                $(
                    if hasdefaultcheck(lvl.lvl)
                        :($my_guard = true)
                    else
                        quote end
                    end
                )
            end,
            body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=idx, guard=my_guard, parent=fbr.env)), ctx, mode),
            epilogue = begin
                #We should be careful here. Presumably, we haven't modified the subfiber because it is still default. Is this always true? Should strict assembly happen every time?
                body = quote
                    $(lvl.idx_alloc) < $my_q && ($(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).idx, $(lvl.idx_alloc), $my_q))
                    $(lvl.ex).idx[$my_q] = $(ctx(idx))
                    $my_q += 1
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
        $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1] = $my_q
        $(lvl.pos_fill) = $(ctx(envposition(fbr.env))) + 1
    end)

    exfurl(body, ctx, mode, idx)
end