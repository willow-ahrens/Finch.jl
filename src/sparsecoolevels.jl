struct SparseCooLevel{N, Ti<:Tuple, Tp, Tbl, Lvl}
    I::Ti
    tbl::Tbl
    pos::Vector{Tp}
    lvl::Lvl
end
const SparseCoo = SparseCooLevel
SparseCooLevel{N}(lvl) where {N} = SparseCooLevel{N}(((0 for _ in 1:N)..., ), lvl)
SparseCooLevel{N, Ti}(lvl) where {N, Ti} = SparseCooLevel{N, Ti}((map(zero, Ti.parameters)..., ), lvl)
SparseCooLevel{N, Ti, Tp}(lvl) where {N, Ti, Tp} = SparseCooLevel{N, Ti, Tp}((map(zero, Ti.parameters)..., ), lvl)

SparseCooLevel{N}(I::Ti, lvl) where {N, Ti} = SparseCooLevel{N, Ti}(I, lvl)
SparseCooLevel{N, Ti}(I, lvl) where {N, Ti} = SparseCooLevel{N, Ti, Int}(Ti(I), lvl)
SparseCooLevel{N, Ti, Tp}(I, lvl) where {N, Ti, Tp} =
    SparseCooLevel{N, Ti, Tp}(Ti(I), ((T[] for T in Ti.parameters)...,), Tp[1, 1], lvl)

SparseCooLevel{N}(I::Ti, tbl::Tbl, pos::Vector{Tp}, lvl::Lvl) where {N, Ti, Tp, Tbl, Lvl} =
    SparseCooLevel{N, Ti, Tp, Tbl, Lvl}(I, tbl, pos, lvl)
SparseCooLevel{N, Ti}(I, tbl::Tbl, pos::Vector{Tp}, lvl::Lvl) where {N, Ti, Tp, Tbl, Lvl} =
    SparseCooLevel{N, Ti, Tp, Tbl, Lvl}(Ti(I), tbl, pos, lvl)
SparseCooLevel{N, Ti, Tp}(I, tbl::Tbl, pos, lvl::Lvl) where {N, Ti, Tp, Tbl, Lvl} =
    SparseCooLevel{N, Ti, Tp, Tbl, Lvl}(Ti(I), tbl, pos, lvl)

"""
`f_code(sc)` = [SparseCooLevel](@ref).
"""
f_code(::Val{:sc}) = SparseCoo
summary_f_code(lvl::SparseCooLevel{N}) where {N} = "sc{$N}($(summary_f_code(lvl.lvl)))"
similar_level(lvl::SparseCooLevel{N}) where {N} = SparseCooLevel{N}(similar_level(lvl.lvl))
similar_level(lvl::SparseCooLevel{N}, tail...) where {N} = SparseCooLevel{N}(ntuple(n->tail[n], N), similar_level(lvl.lvl, tail[N + 1:end]...))

pattern!(lvl::SparseCooLevel{N, Ti, Tp}) where {N, Ti, Tp} = 
    SparseCooLevel{N, Ti, Tp}(lvl.I, lvl.tbl, lvl.pos, pattern!(lvl.lvl))

function Base.show(io::IO, lvl::SparseCooLevel{N, Ti}) where {N, Ti}
    if get(io, :compact, false)
        print(io, "SparseCoo{$N}(")
    else
        print(io, "SparseCoo{$N, $Ti}(")
    end
    show(io, lvl.I)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        print(io, "(")
        for n = 1:N
            show(io, lvl.tbl[n])
            print(io, ", ")
        end
        print(io, "), ")
        show(io, lvl.pos)
    end
    print(io, ", ")
    show(io, lvl.lvl)
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:SparseCooLevel{N}}) where {N}
    p = envposition(fbr.env)
    crds = fbr.lvl.pos[p]:fbr.lvl.pos[p + 1] - 1
    depth = envdepth(fbr.env)

    print_coord(io, q) = (print(io, "["); foreach(n -> (show(io, fbr.lvl.tbl[n][q]); print(io, ", ")), 1:N-1); show(io, fbr.lvl.tbl[N][q]); print(io, "]"))
    get_coord(q) = map(n -> fbr.lvl.tbl[n][q], 1:N)

    dims = size(fbr)
    print(io, "│ " ^ depth); print(io, "SparseCoo ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); foreach(dim -> (print(io, "1:"); show(io, dim); print(io, "×")), dims[1:N-1]); print(io, "1:"); show(io, dims[end]); println(io, "]")
    display_fiber_data(io, mime, fbr, N, crds, print_coord, get_coord)
end

@inline Base.ndims(fbr::Fiber{<:SparseCooLevel{N}}) where {N} = N + ndims(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))
@inline Base.size(fbr::Fiber{<:SparseCooLevel{N}}) where {N} = (fbr.lvl.I..., size(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))...)
@inline Base.axes(fbr::Fiber{<:SparseCooLevel{N}}) where {N} = (map(Base.OneTo, fbr.lvl.I)..., axes(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))...)
@inline Base.eltype(fbr::Fiber{<:SparseCooLevel{N}}) where {N} = eltype(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))
@inline default(fbr::Fiber{<:SparseCooLevel{N}}) where {N} = default(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))

(fbr::Fiber{<:SparseCooLevel})() = fbr
function (fbr::Fiber{<:SparseCooLevel{N, Ti}})(i, tail...) where {N, Ti}
    lvl = fbr.lvl
    R = length(envdeferred(fbr.env)) + 1
    if R == 1
        p = envposition(fbr.env)
        start = lvl.pos[p]
        stop = lvl.pos[p + 1]
    else
        start = fbr.env.start
        stop = fbr.env.stop
    end
    r = searchsorted(@view(lvl.tbl[R][start:stop - 1]), i)
    q = start + first(r) - 1
    q_2 = start + last(r)
    if R == N
        fbr_2 = Fiber(lvl.lvl, Environment(position=q, index=i, parent=fbr.env))
        length(r) == 0 ? default(fbr_2) : fbr_2(tail...)
    else
        fbr_2 = Fiber(lvl, Environment(start=q, stop=q_2, index=i, parent=fbr.env, internal=true))
        length(r) == 0 ? default(fbr_2) : fbr_2(tail...)
    end
end



mutable struct VirtualSparseCooLevel
    ex
    N
    Ti
    Tp
    Tbl
    I
    pos_alloc
    idx_alloc
    lvl
end
function virtualize(ex, ::Type{SparseCooLevel{N, Ti, Tp, Tbl, Lvl}}, ctx, tag=:lvl) where {N, Ti, Tp, Tbl, Lvl}   
    sym = ctx.freshen(tag)
    I = map(n->value(:($sym.I[$n]), Int), 1:N)
    pos_alloc = ctx.freshen(sym, :_pos_alloc)
    idx_alloc = ctx.freshen(sym, :_idx_alloc)
    push!(ctx.preamble, quote
        $sym = $ex
        $pos_alloc = length($sym.pos)
        $idx_alloc = length($sym.tbl)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseCooLevel(sym, N, Ti, Tp, Tbl, I, pos_alloc, idx_alloc, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualSparseCooLevel)
    quote
        $SparseCooLevel{$(lvl.N), $(lvl.Ti), $(lvl.Tp)}(
            ($(map(ctx, lvl.I)...),),
            $(lvl.ex).tbl,
            $(lvl.ex).pos,
            $(ctx(lvl.lvl)),
        )
    end
end

summary_f_code(lvl::VirtualSparseCooLevel) = "sc{$(lvl.N)}($(summary_f_code(lvl.lvl)))"

function getsites(fbr::VirtualFiber{VirtualSparseCooLevel})
    d = envdepth(fbr.env)
    return [(d + 1:d + fbr.lvl.N)..., getsites(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^fbr.lvl.N)(fbr.env)))...]
end

function getsize(fbr::VirtualFiber{VirtualSparseCooLevel}, ctx::LowerJulia, mode)
    ext = map(stop->Extent(literal(1), stop), fbr.lvl.I)
    if mode.kind !== reader
        ext = map(suggest, ext)
    end
    (ext..., getsize(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^fbr.lvl.N)(fbr.env)), ctx, mode)...)
end

function setsize!(fbr::VirtualFiber{VirtualSparseCooLevel}, ctx::LowerJulia, mode, dims...)
    fbr.lvl.I = map(getstop, dims[1:fbr.lvl.N])
    fbr.lvl.lvl = setsize!(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^fbr.lvl.N)(fbr.env)), ctx, mode, dims[fbr.lvl.N + 1:end]...).lvl
    fbr
end

@inline default(fbr::VirtualFiber{<:VirtualSparseCooLevel}) = default(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^fbr.lvl.N)(fbr.env)))
Base.eltype(fbr::VirtualFiber{<:VirtualSparseCooLevel}) = eltype(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualSparseCooLevel}, ctx::LowerJulia, mode)
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    my_p = ctx.freshen(lvl.ex, :_p)
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = length($(lvl.ex).pos) - 1
        $(lvl.ex).pos[1] = 1
        $(lvl.idx_alloc) = length($(lvl.ex).tbl[1])
    end)

    lvl.lvl = initialize_level!(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^lvl.N)(fbr.env)), ctx, mode)
    return lvl
end

function trim_level!(lvl::VirtualSparseCooLevel, ctx::LowerJulia, pos)
    idx = ctx.freshen(:idx)
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = $(ctx(pos)) + 1
        resize!($(lvl.ex).pos, $(lvl.pos_alloc))
        $(lvl.idx_alloc) = $(lvl.ex).pos[$(lvl.pos_alloc)] - 1
        for $idx in $(lvl.ex).tbl
            resize!($idx, $(lvl.idx_alloc))
        end
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, lvl.idx_alloc)
    return lvl
end

interval_assembly_depth(lvl::VirtualSparseCooLevel) = Inf

#This function is quite simple, since SparseCooLevels don't support reassembly.
function assemble!(fbr::VirtualFiber{VirtualSparseCooLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), getstop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) < ($p_stop + 1) && ($(lvl.pos_alloc) = $Finch.regrow!($(lvl.ex).pos, $(lvl.pos_alloc), $p_stop + 1))
    end)
end

function finalize_level!(fbr::VirtualFiber{VirtualSparseCooLevel}, ctx::LowerJulia, mode)
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl

    lvl.lvl = finalize_level!(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^lvl.N)(fbr.env)), ctx, mode)
    return lvl
end

function unfurl(fbr::VirtualFiber{VirtualSparseCooLevel}, ctx, mode, ::Nothing, idx, idxs...)
    if idx.kind === protocol
        @assert idx.mode.kind === literal
        unfurl(fbr, ctx, mode, idx.mode.val, idx.idx, idxs...)
    elseif mode.kind === reader
        unfurl(fbr, ctx, mode, walk, idx, idxs...)
    else
        unfurl(fbr, ctx, mode, extrude, idx, idxs...)
    end
end

function unfurl(fbr::VirtualFiber{VirtualSparseCooLevel}, ctx, mode, ::Walk, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_step = ctx.freshen(tag, :_q_step)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)
    R = length(envdeferred(fbr.env)) + 1
    if R == 1
        q_start = value(:($(lvl.ex).pos[$(ctx(envposition(fbr.env)))]), lvl.Tp)
        q_stop = value(:($(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]), lvl.Tp)
    else
        q_start = fbr.env.start
        q_stop = fbr.env.stop
    end

    body = Thunk(
        preamble = quote
            $my_q = $(ctx(q_start))
            $my_q_stop = $(ctx(q_stop))
            if $my_q < $my_q_stop
                $my_i = $(lvl.ex).tbl[$R][$my_q]
                $my_i_stop = $(lvl.ex).tbl[$R][$my_q_stop - 1]
            else
                $my_i = 1
                $my_i_stop = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (ctx, idx, ext) -> value(my_i_stop),
                body = (start, stop) -> Stepper(
                    seek = (ctx, ext) -> quote
                        while $my_q < $my_q_stop && $(lvl.ex).tbl[$R][$my_q] < $(ctx(getstart(ext)))
                            $my_q += 1
                        end
                    end,
                    body = if R == lvl.N
                        Thunk(
                            preamble = quote
                                $my_i = $(lvl.ex).tbl[$R][$my_q]
                            end,
                            body = Step(
                                stride =  (ctx, idx, ext) -> value(my_i),
                                chunk = Spike(
                                    body = Simplify(literal(default(fbr))),
                                    tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Tp), index=value(my_i, lvl.Ti), parent=fbr.env)), ctx, mode, idxs...),
                                ),
                                next = (ctx, idx, ext) -> quote
                                    $my_q += 1
                                end
                            )
                        )
                    else
                        Thunk(
                            preamble = quote
                                $my_i = $(lvl.ex).tbl[$R][$my_q]
                                $my_q_step = $my_q
                                while $my_q_step < $my_q_stop && $(lvl.ex).tbl[$R][$my_q_step] == $my_i
                                    $my_q_step += 1
                                end
                            end,
                            body = Step(
                                stride = (ctx, idx, ext) -> value(my_i),
                                chunk = Spike(
                                    body = Simplify(literal(default(fbr))),
                                    tail = refurl(VirtualFiber(lvl, VirtualEnvironment(start=value(my_q, lvl.Ti), stop=value(my_q_step, lvl.Ti), index=value(my_i, lvl.Ti), parent=fbr.env, internal=true)), ctx, mode, idxs...),
                                ),
                                next = (ctx, idx, ext) -> quote
                                    $my_q = $my_q_step
                                end
                            )
                        )
                    end
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(literal(default(fbr))))
            )
        ])
    )

    exfurl(body, ctx, mode, idx)
end

hasdefaultcheck(lvl::VirtualSparseCooLevel) = true

function unfurl(fbr::VirtualFiber{VirtualSparseCooLevel}, ctx, mode, ::Extrude, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    R = length(envdeferred(fbr.env)) + 1

    if R == 1
        my_q = ctx.freshen(tag, :_q)
        push!(ctx.preamble, quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(envexternal(fbr.env))))]
        end)
    else
        my_q = fbr.env.my_q
    end

    if R == lvl.N
        my_guard = ctx.freshen(tag, :_guard)
        body = AcceptSpike(
            val = default(fbr),
            tail = (ctx, idx) -> Thunk(
                preamble = quote
                    $my_guard = true
                    $(contain(ctx) do ctx_2 
                        assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), parent=fbr.env)), ctx_2, mode)
                        quote end
                    end)
                end,
                body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=idx, guard=my_guard, parent=fbr.env)), ctx, mode, idxs...),
                epilogue = begin
                    resize_body = quote end
                    writer_body = quote end
                    my_idxs = map(ctx, (envdeferred(fbr.env)..., idx))
                    for n = 1:lvl.N
                        if n == lvl.N
                            resize_body = quote
                                $resize_body
                                $(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).tbl[$n], $(lvl.idx_alloc), $my_q)
                            end
                        else
                            resize_body = quote
                                $resize_body
                                $Finch.regrow!($(lvl.ex).tbl[$n], $(lvl.idx_alloc), $my_q)
                            end
                        end
                        writer_body = quote
                            $writer_body
                            $(lvl.ex).tbl[$n][$my_q] = $(my_idxs[n])
                        end
                    end
                    body = quote
                        if $(lvl.idx_alloc) < $my_q
                            $resize_body
                        end
                        $writer_body
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
    else
        body = Lookup(
            val = default(fbr),
            body = (i) -> refurl(VirtualFiber(lvl, VirtualEnvironment(index=i, my_q=my_q, parent=fbr.env, internal=true)), ctx, mode, idxs...)
        )
    end
    if R == 1
        push!(ctx.epilogue, quote
            $(lvl.ex).pos[$(ctx(envposition(envexternal(fbr.env)))) + 1] = $my_q
        end)
    end

    exfurl(body, ctx, mode, idx)
end