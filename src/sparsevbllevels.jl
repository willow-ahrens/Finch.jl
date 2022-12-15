struct SparseVBLLevel{Ti, Tp, Lvl}
    I::Ti
    pos::Vector{Tp}
    idx::Vector{Ti}
    ofs::Vector{Tp}
    lvl::Lvl
end
const SparseVBL = SparseVBLLevel
SparseVBLLevel(lvl) = SparseVBLLevel(0, lvl)
SparseVBLLevel{Ti}(lvl) where {Ti} = SparseVBLLevel{Ti}(zero(Ti), lvl)
SparseVBLLevel{Ti, Tp}(lvl) where {Ti, Tp} = SparseVBLLevel{Ti, Tp}(zero(Ti), lvl)

SparseVBLLevel(I::Ti, lvl) where {Ti} = SparseVBLLevel{Ti}(I, lvl)
SparseVBLLevel{Ti}(I, lvl) where {Ti} = SparseVBLLevel{Ti, Int}(Ti(I), lvl)
SparseVBLLevel{Ti, Tp}(I, lvl::Lvl) where {Ti, Tp, Lvl} = SparseVBLLevel{Ti, Tp, Lvl}(Ti(I), Ti[1, 1], Ti[], Ti[1], lvl)

SparseVBLLevel(I::Ti, pos::Vector{Tp}, idx, ofs, lvl::Lvl) where {Ti, Tp, Lvl} = SparseVBLLevel{Ti, Tp, Lvl}(I, pos, idx, ofs, lvl)
SparseVBLLevel{Ti}(I, pos::Vector{Tp}, idx, ofs, lvl::Lvl) where {Ti, Tp, Lvl} = SparseVBLLevel{Ti, Tp, Lvl}(Ti(I), pos, idx, ofs, lvl)
SparseVBLLevel{Ti, Tp}(I, pos, idx, ofs, lvl::Lvl) where {Ti, Tp, Lvl} = SparseVBLLevel{Ti, Tp, Lvl}(Ti(I), pos, idx, ofs, lvl)

"""
`f_code(sv)` = [SparseVBLLevel](@ref).
"""
f_code(::Val{:sv}) = SparseVBL
summary_f_code(lvl::SparseVBLLevel) = "sv($(summary_f_code(lvl.lvl)))"
similar_level(lvl::SparseVBLLevel) = SparseVBL(similar_level(lvl.lvl))
similar_level(lvl::SparseVBLLevel, dim, tail...) = SparseVBL(dim, similar_level(lvl.lvl, tail...))

pattern!(lvl::SparseVBLLevel{Ti}) where {Ti} = 
    SparseVBLLevel{Ti}(lvl.I, lvl.pos, lvl.idx, lvl.ofs, pattern!(lvl.lvl))

function Base.show(io::IO, lvl::SparseVBLLevel{Ti}) where {Ti}
    if get(io, :compact, false)
        print(io, "SparseVBL(")
    else
        print(io, "SparseVBL{$Ti}(")
    end
    show(io, lvl.I)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(io, lvl.pos)
        print(io, ", ")
        show(io, lvl.idx)
        print(io, ", ")
        show(io, lvl.ofs)
    end
    print(io, ", ")
    show(io, lvl.lvl)
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:SparseVBLLevel})
    p = envposition(fbr.env)
    crds = []
    for r in fbr.lvl.pos[p]:fbr.lvl.pos[p + 1] - 1
        i = fbr.lvl.idx[r]
        l = fbr.lvl.ofs[r + 1] - fbr.lvl.ofs[r]
        append!(crds, (i - l + 1):i)
    end

    depth = envdepth(fbr.env)

    print_coord(io, crd) = (print(io, "["); show(io, crd); print(io, "]"))
    get_coord(crd) = crd

    print(io, "│ " ^ depth); print(io, "SparseVBL ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]")
    display_fiber_data(io, mime, fbr, 1, crds, print_coord, get_coord)
end

@inline Base.ndims(fbr::Fiber{<:SparseVBLLevel}) = 1 + ndims(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline Base.size(fbr::Fiber{<:SparseVBLLevel}) = (fbr.lvl.I, size(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline Base.axes(fbr::Fiber{<:SparseVBLLevel}) = (1:fbr.lvl.I, axes(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline Base.eltype(fbr::Fiber{<:SparseVBLLevel}) = eltype(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline default(fbr::Fiber{<:SparseVBLLevel}) = default(Fiber(fbr.lvl.lvl, Environment(fbr.env)))

(fbr::Fiber{<:SparseVBLLevel})() = fbr
function (fbr::Fiber{<:SparseVBLLevel})(i, tail...)
    lvl = fbr.lvl
    p = envposition(fbr.env)
    r = lvl.pos[p] + searchsortedfirst(@view(lvl.idx[lvl.pos[p]:lvl.pos[p + 1] - 1]), i) - 1
    r < lvl.pos[p + 1] || return default(fbr)
    q = lvl.ofs[r + 1] - 1 - lvl.idx[r] + i
    q >= lvl.ofs[r] || return default(fbr)
    fbr_2 = Fiber(lvl.lvl, Environment(position=q, index=i, parent=fbr.env))
    return fbr_2(tail...)
end

mutable struct VirtualSparseVBLLevel
    ex
    Ti
    Tp
    I
    pos_alloc
    idx_alloc
    ofs_alloc
    lvl
end
function virtualize(ex, ::Type{SparseVBLLevel{Ti, Tp, Lvl}}, ctx, tag=:lvl) where {Ti, Tp, Lvl}
    sym = ctx.freshen(tag)
    I = value(:($sym.I), Int)
    pos_alloc = ctx.freshen(sym, :_pos_alloc)
    idx_alloc = ctx.freshen(sym, :_idx_alloc)
    ofs_alloc = ctx.freshen(sym, :_ofs_alloc)
    push!(ctx.preamble, quote
        $sym = $ex
        $pos_alloc = length($sym.pos)
        $idx_alloc = length($sym.idx)
        $ofs_alloc = length($sym.ofs)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseVBLLevel(sym, Ti, Tp, I, pos_alloc, idx_alloc, ofs_alloc, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualSparseVBLLevel)
    quote
        $SparseVBLLevel{$(lvl.Ti)}(
            $(ctx(lvl.I)),
            $(lvl.ex).pos,
            $(lvl.ex).idx,
            $(lvl.ex).ofs,
            $(ctx(lvl.lvl)),
        )
    end
end

summary_f_code(lvl::VirtualSparseVBLLevel) = "sv($(summary_f_code(lvl.lvl)))"

getsites(fbr::VirtualFiber{VirtualSparseVBLLevel}) =
    [envdepth(fbr.env) + 1, getsites(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))...]

function getsize(fbr::VirtualFiber{VirtualSparseVBLLevel}, ctx, mode)
    ext = Extent(literal(1), fbr.lvl.I)
    if mode.kind !== reader
        ext = suggest(ext)
    end
    (ext, getsize(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)...)
end

function setsize!(fbr::VirtualFiber{VirtualSparseVBLLevel}, ctx, mode, dim, dims...)
    fbr.lvl.I = getstop(dim)
    fbr.lvl.lvl = setsize!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode, dims...).lvl
    fbr
end

@inline default(fbr::VirtualFiber{<:VirtualSparseVBLLevel}) = default(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))
Base.eltype(fbr::VirtualFiber{VirtualSparseVBLLevel}) = eltype(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualSparseVBLLevel}, ctx::LowerJulia, mode)
    lvl = fbr.lvl
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = length($(lvl.ex).pos)
        $(lvl.ex).pos[1] = 1
        $(lvl.ex).pos[2] = 1
        $(lvl.ofs_alloc) = length($(lvl.ex).ofs)
        $(lvl.ex).ofs[1] = 1
        $(lvl.idx_alloc) = length($(lvl.ex).idx)
    end)
    lvl.lvl = initialize_level!(VirtualFiber(fbr.lvl.lvl, Environment(fbr.env)), ctx, mode)
    return lvl
end

function trim_level!(lvl::VirtualSparseVBLLevel, ctx::LowerJulia, pos)
    qos = ctx.freshen(:qos)
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = $(ctx(pos)) + 1
        resize!($(lvl.ex).pos, $(lvl.pos_alloc))
        $(lvl.ofs_alloc) = $(lvl.ex).pos[$(lvl.pos_alloc)]
        resize!($(lvl.ex).ofs, $(lvl.ofs_alloc))
        $(lvl.idx_alloc) = $(lvl.ex).ofs[$(lvl.ofs_alloc)] - 1
        resize!($(lvl.ex).idx, $(lvl.idx_alloc))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, lvl.idx_alloc)
    return lvl
end

interval_assembly_depth(lvl::VirtualSparseVBLLevel) = Inf

#This function is quite simple, since SparseVBLLevels don't support reassembly.
function assemble!(fbr::VirtualFiber{VirtualSparseVBLLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), getstop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) < ($p_stop + 1) && ($(lvl.pos_alloc) = $Finch.regrow!($(lvl.ex).pos, $(lvl.pos_alloc), $p_stop + 1))
    end)
end

function finalize_level!(fbr::VirtualFiber{VirtualSparseVBLLevel}, ctx::LowerJulia, mode)
    fbr.lvl.lvl = finalize_level!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)
    return fbr.lvl
end

function unfurl(fbr::VirtualFiber{VirtualSparseVBLLevel}, ctx, mode, ::Nothing, idx, idxs...)
    if idx.kind === protocol
        @assert idx.mode.kind === literal
        unfurl(fbr, ctx, mode, idx.mode.val, idx.idx, idxs...)
    elseif mode.kind === reader
        unfurl(fbr, ctx, mode, walk, idx, idxs...)
    else
        unfurl(fbr, ctx, mode, extrude, idx, idxs...)
    end
end

function unfurl(fbr::VirtualFiber{VirtualSparseVBLLevel}, ctx, mode, ::Walk, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_i_start = ctx.freshen(tag, :_i)
    my_r = ctx.freshen(tag, :_r)
    my_r_stop = ctx.freshen(tag, :_r_stop)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_q_ofs = ctx.freshen(tag, :_q_ofs)
    my_i1 = ctx.freshen(tag, :_i1)

    body = Thunk(
        preamble = quote
            $my_r = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_r_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_r < $my_r_stop
                $my_i = $(lvl.ex).idx[$my_r]
                $my_i1 = $(lvl.ex).idx[$my_r_stop - 1]
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
                        #$my_r = searchsortedfirst($(lvl.ex).idx, $start, $my_r, $my_r_stop, Base.Forward)
                        while $my_r < $my_r_stop && $(lvl.ex).idx[$my_r] < $(ctx(getstart(ext)))
                            $my_r += 1
                        end
                    end,
                    body = Thunk(
                        preamble = quote
                            $my_i = $(lvl.ex).idx[$my_r]
                            $my_q_stop = $(lvl.ex).ofs[$my_r + 1]
                            $my_i_start = $my_i - ($my_q_stop - $(lvl.ex).ofs[$my_r])
                            $my_q_ofs = $my_q_stop - $my_i - 1
                        end,
                        body = Step(
                            stride = (ctx, idx, ext) -> value(my_i),
                            body = (ctx, idx, ext, ext_2) -> Thunk(
                                body = Pipeline([
                                    Phase(
                                        stride = (ctx, idx, ext) -> value(my_i_start),
                                        body = (start, step) -> Run(Simplify(literal(default(fbr)))),
                                    ),
                                    Phase(
                                        body = (start, step) -> Lookup(
                                            body = (i) -> Thunk(
                                                preamble = quote
                                                    $my_q = $my_q_ofs + $(ctx(i))
                                                end,
                                                body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=i, parent=fbr.env)), ctx, mode, idxs...),
                                            )
                                        )
                                    )
                                ]),
                                epilogue = quote
                                    $my_r += ($(ctx(getstop(ext_2))) == $my_i)
                                end
                            )
                        )
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(literal(default(fbr))))
            )
        ])
    )

    exfurl(body, ctx, mode, idx)
end

function unfurl(fbr::VirtualFiber{VirtualSparseVBLLevel}, ctx, mode, ::Gallop, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_i_start = ctx.freshen(tag, :_i)
    my_r = ctx.freshen(tag, :_r)
    my_r_stop = ctx.freshen(tag, :_r_stop)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_q_ofs = ctx.freshen(tag, :_q_ofs)
    my_i1 = ctx.freshen(tag, :_i1)

    body = Thunk(
        preamble = quote
            $my_r = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_r_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_r < $my_r_stop
                $my_i = $(lvl.ex).idx[$my_r]
                $my_i1 = $(lvl.ex).idx[$my_r_stop - 1]
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
                        preamble = quote
                            $my_i = $(lvl.ex).idx[$my_r]
                        end,
                        body = Jump(
                            seek = (ctx, ext) -> quote
                                #$my_r = searchsortedfirst($(lvl.ex).idx, $start, $my_r, $my_r_stop, Base.Forward)
                                while $my_r < $my_r_stop && $(lvl.ex).idx[$my_r] < $(ctx(getstart(ext)))
                                    $my_r += 1
                                end
                                $my_i = $(lvl.ex).idx[$my_r]
                            end,
                            stride = (ctx, ext) -> value(my_i),
                            body = (ctx, ext, ext_2) -> Switch([
                                value(:($(ctx(getstop(ext_2))) == $my_i)) => Thunk(
                                    preamble=quote
                                        $my_q_stop = $(lvl.ex).ofs[$my_r + 1]
                                        $my_i_start = $my_i - ($my_q_stop - $(lvl.ex).ofs[$my_r])
                                        $my_q_ofs = $my_q_stop - $my_i - 1
                                    end,
                                    body = Pipeline([
                                        Phase(
                                            stride = (ctx, idx, ext) -> value(my_i_start),
                                            body = (start, step) -> Run(Simplify(literal(default(fbr)))),
                                        ),
                                        Phase(
                                            body = (start, step) -> Lookup(
                                                body = (i) -> Thunk(
                                                    preamble = quote
                                                        $my_q = $my_q_ofs + $(ctx(i))
                                                    end,
                                                    body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=i, parent=fbr.env)), ctx, mode, idxs...),
                                                )
                                            )
                                        )
                                    ]),
                                    epilogue = quote
                                        $my_r += 1
                                    end
                                ),
                                literal(true) => Stepper(
                                    seek = (ctx, ext) -> quote
                                        #$my_r = searchsortedfirst($(lvl.ex).idx, $start, $my_r, $my_r_stop, Base.Forward)
                                        while $my_r < $my_r_stop && $(lvl.ex).idx[$my_r] < $(ctx(getstart(ext_2)))
                                            $my_r += 1
                                        end
                                    end,
                                    body = Thunk(
                                        preamble = quote
                                            $my_i = $(lvl.ex).idx[$my_r]
                                            $my_q_stop = $(lvl.ex).ofs[$my_r + 1]
                                            $my_i_start = $my_i - ($my_q_stop - $(lvl.ex).ofs[$my_r])
                                            $my_q_ofs = $my_q_stop - $my_i - 1
                                        end,
                                        body = Step(
                                            stride = (ctx, idx, ext) -> value(my_i),
                                            body = (ctx, idx, ext, ext_2) -> Thunk(
                                                body = Pipeline([
                                                    Phase(
                                                        stride = (ctx, idx, ext) -> value(my_i_start),
                                                        body = (start, step) -> Run(Simplify(literal(default(fbr)))),
                                                    ),
                                                    Phase(
                                                        body = (start, step) -> Lookup(
                                                            body = (i) -> Thunk(
                                                                preamble = quote
                                                                    $my_q = $my_q_ofs + $(ctx(i))
                                                                end,
                                                                body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=i, parent=fbr.env)), ctx, mode, idxs...),
                                                            )
                                                        )
                                                    )
                                                ]),
                                                epilogue = quote
                                                    $my_r += ($(ctx(getstop(ext_2))) == $my_i)
                                                end
                                            )
                                        )
                                    )
                                )
                            ])
                        )
                    ),
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(literal(default(fbr))))
            )
        ])
    )

    exfurl(body, ctx, mode, idx)
end

function unfurl(fbr::VirtualFiber{VirtualSparseVBLLevel}, ctx, mode, ::Extrude, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_q = ctx.freshen(tag, :_q)
    my_i_prev = ctx.freshen(tag, :_i_prev)
    my_r = ctx.freshen(tag, :_r)
    my_guard = if hasdefaultcheck(lvl.lvl)
        ctx.freshen(tag, :_isdefault)
    end

    push!(ctx.preamble, quote
        $my_r = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
        $my_q = $(lvl.ex).ofs[$my_r]
        $my_i_prev = -1
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
            body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=idx, guard=my_guard, parent=fbr.env)), ctx, mode, idxs...),
            epilogue = begin
                #We should be careful here. Presumably, we haven't modified the subfiber because it is still default. Is this always true? Should strict assembly happen every time?
                body = quote
                    if $(ctx(idx)) > $my_i_prev + 1
                        $(lvl.idx_alloc) < $my_r && ($(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).idx, $(lvl.idx_alloc), $my_r))
                        $(lvl.ofs_alloc) < $my_r + 1 && ($(lvl.ofs_alloc) = $Finch.regrow!($(lvl.ex).ofs, $(lvl.ofs_alloc), $my_r + 1))
                        $my_r += 1
                    end
                    $(lvl.ex).idx[$my_r - 1] = $my_i_prev = $(ctx(idx))
                    $(my_q) += 1
                    $(lvl.ex).ofs[$my_r] = $my_q
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
        $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1] = $my_r
    end)

    exfurl(body, ctx, mode, idx)
end