struct SparseBytemapLevel{Ti, Tp, Lvl}
    I::Ti
    pos::Vector{Tp}
    tbl::Vector{Bool}
    srt::Vector{Tuple{Tp, Ti}}
    srt_stop::Ref{Tp} #TODO remove this after trimming levels
    lvl::Lvl
end
const SparseBytemap = SparseBytemapLevel

SparseBytemapLevel(lvl) = SparseBytemapLevel(0, lvl)
SparseBytemapLevel{Ti}(lvl) where {Ti} = SparseBytemapLevel{Ti}(zero(Ti), lvl)
SparseBytemapLevel{Ti, Tp}(lvl) where {Ti, Tp} = SparseBytemapLevel{Ti, Tp}(zero(Ti), lvl)

SparseBytemapLevel(I::Ti, lvl) where {Ti} = SparseBytemapLevel{Ti}(I, lvl)
SparseBytemapLevel{Ti}(I, lvl) where {Ti} = SparseBytemapLevel{Ti, Int}(Ti(I), lvl)
SparseBytemapLevel{Ti, Tp}(I, lvl) where {Ti, Tp} =
    SparseBytemapLevel{Ti, Tp}(Ti(I), Tp[1, 1], fill(false, I), Tuple{Tp, Ti}[], Ref(Tp(0)), lvl)

SparseBytemapLevel(I::Ti, pos::Vector{Tp}, tbl, srt, srt_stop, lvl::Lvl) where {Ti, Tp, Lvl} =
    SparseBytemapLevel{Ti, Tp, Lvl}(I, pos, tbl, srt, srt_stop, lvl)
SparseBytemapLevel{Ti}(I, pos::Vector{Tp}, tbl, srt, srt_stop, lvl::Lvl) where {Ti, Tp, Lvl} =
    SparseBytemapLevel{Ti, Tp, Lvl}(Ti(I), pos, tbl, srt, srt_stop, lvl)
SparseBytemapLevel{Ti, Tp}(I, pos, tbl, srt, srt_stop, lvl::Lvl) where {Ti, Tp, Lvl} =
    SparseBytemapLevel{Ti, Tp, Lvl}(Ti(I), pos, tbl, srt, srt_stop, lvl)

pattern!(lvl::SparseBytemapLevel{Ti, Tp}) where {Ti, Tp} = 
    SparseBytemapLevel{Ti, Tp}(lvl.I, lvl.pos, lvl.tbl, lvl.srt, lvl.srt_stop, pattern!(lvl.lvl))

"""
`f_code(sm)` = [SparseBytemapLevel](@ref).
"""
f_code(::Val{:sm}) = SparseBytemap
summary_f_code(lvl::SparseBytemapLevel) = "sm($(summary_f_code(lvl.lvl)))"
similar_level(lvl::SparseBytemapLevel) = SparseBytemap(similar_level(lvl.lvl))
similar_level(lvl::SparseBytemapLevel, dim, tail...) = SparseBytemap(dim, similar_level(lvl.lvl, tail...))

function Base.show(io::IO, lvl::SparseBytemapLevel{Ti}) where {Ti}
    if get(io, :compact, false)
        print(io, "SparseBytemap(")
    else
        print(io, "SparseBytemap{$Ti}(")
    end
    show(io, lvl.I)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(io, lvl.pos)
        print(io, ", ")
        show(io, lvl.tbl)
        print(io, ", ")
        show(io, lvl.srt)
        print(io, ", ")
        print(io, lvl.srt_stop)
    end
    print(io, ", ")
    show(io, lvl.lvl)
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:SparseBytemapLevel})
    p = envposition(fbr.env)
    crds = @view(fbr.lvl.srt[1:length(fbr.lvl.srt_stop[])])
    depth = envdepth(fbr.env)

    print_coord(io, (p, i)) = (print(io, "["); show(io, i); print(io, "]"))
    get_coord((p, i),) = i

    print(io, "│ " ^ depth); print(io, "SparseBytemap ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]")
    display_fiber_data(io, mime, fbr, 1, crds, print_coord, get_coord)
end


@inline Base.ndims(fbr::Fiber{<:SparseBytemapLevel}) = 1 + ndims(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline Base.size(fbr::Fiber{<:SparseBytemapLevel}) = (fbr.lvl.I, size(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline Base.axes(fbr::Fiber{<:SparseBytemapLevel}) = (1:fbr.lvl.I, axes(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline Base.eltype(fbr::Fiber{<:SparseBytemapLevel}) = eltype(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline default(fbr::Fiber{<:SparseBytemapLevel}) = default(Fiber(fbr.lvl.lvl, Environment(fbr.env)))

(fbr::Fiber{<:SparseBytemapLevel})() = fbr
function (fbr::Fiber{<:SparseBytemapLevel{Ti}})(i, tail...) where {Ti}
    lvl = fbr.lvl
    p = envposition(fbr.env)
    q = (p - 1) * lvl.I + i
    if lvl.tbl[q]
        fbr_2 = Fiber(lvl.lvl, Environment(position=q, index=i, parent=fbr.env))
        fbr_2(tail...)
    else
        default(fbr_2)
    end
end

mutable struct VirtualSparseBytemapLevel
    ex
    Ti
    Tp
    I
    pos_alloc
    tbl_alloc
    srt_alloc
    srt_stop
    lvl
end
function virtualize(ex, ::Type{SparseBytemapLevel{Ti, Tp, Lvl}}, ctx, tag=:lvl) where {Ti, Tp, Lvl}   
    sym = ctx.freshen(tag)
    I = value(:($sym.I))
    pos_alloc = ctx.freshen(sym, :_pos_alloc)
    tbl_alloc = ctx.freshen(sym, :_tbl_alloc)
    srt_stop = ctx.freshen(sym, :_srt_stop)
    srt_alloc = ctx.freshen(sym, :_srt_alloc)
    push!(ctx.preamble, quote
        $sym = $ex
        $pos_alloc = length($sym.pos)
        $tbl_alloc = length($sym.tbl)
        $srt_alloc = length($sym.srt)
        $srt_stop = $sym.srt_stop[]
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseBytemapLevel(sym, Ti, Tp, I, pos_alloc, tbl_alloc, srt_alloc, srt_stop, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualSparseBytemapLevel)
    quote
        $SparseBytemapLevel{$(lvl.Ti), $(lvl.Tp)}(
            $(ctx(lvl.I)),
            $(lvl.ex).pos,
            $(lvl.ex).tbl,
            $(lvl.ex).srt,
            $(lvl.ex).srt_stop,
            $(ctx(lvl.lvl)),
        )
    end
end

summary_f_code(lvl::VirtualSparseBytemapLevel) = "sm($(summary_f_code(lvl.lvl)))"

getsites(fbr::VirtualFiber{VirtualSparseBytemapLevel}) =
    [envdepth(fbr.env) + 1, getsites(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))...]

function getsize(fbr::VirtualFiber{VirtualSparseBytemapLevel}, ctx, mode)
    ext = Extent(literal(1), fbr.lvl.I)
    if mode.kind !== reader
        ext = suggest(ext)
    end
    (ext, getsize(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)...)
end

function setsize!(fbr::VirtualFiber{VirtualSparseBytemapLevel}, ctx, mode, dim, dims...)
    fbr.lvl.I = getstop(dim)
    fbr.lvl.lvl = setsize!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode, dims...).lvl
    fbr
end

@inline default(fbr::VirtualFiber{VirtualSparseBytemapLevel}) = default(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))
Base.eltype(fbr::VirtualFiber{VirtualSparseBytemapLevel}) = eltype(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualSparseBytemapLevel}, ctx::LowerJulia, mode)
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    r = ctx.freshen(lvl.ex, :_r)
    p = ctx.freshen(lvl.ex, :_p)
    q = ctx.freshen(lvl.ex, :_q)
    i = ctx.freshen(lvl.ex, :_i)
    p_prev = ctx.freshen(lvl.ex, :_p_prev)
    if mode.kind === updater && mode.mode.kind === create
        push!(ctx.preamble, quote
            # fill!($(lvl.ex).tbl, 0)
            # empty!($(lvl.ex).srt)
            $(lvl.ex).pos[1] = 1
            $p_prev = 0
            for $r = 1:$(lvl.srt_stop)
                $p = first($(lvl.ex).srt[$r])
                if $p != $p_prev
                    $(lvl.ex).pos[$p] = 0
                    $(lvl.ex).pos[$p + 1] = 0
                end
                $p_prev = $p
            end
            for $r = 1:$(lvl.srt_stop)
                $(lvl.ex).tbl[$r] = false
                $(if reinitializeable(lvl.lvl)
                    push!(ctx.preamble, quote
                        $p = first($(lvl.ex).srt[$r])
                        $i = last($(lvl.ex).srt[$r])
                        $q = ($p - 1) * $(ctx(lvl.I)) + $i
                    end)
                    reinitialize(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env, position = value(q, Ti), index = value(i, Ti))))
                else
                    quote end
                end)
            end
            $(lvl.ex).srt_stop[] = $(lvl.srt_stop) = 0
        end)
    end
    lvl.lvl = initialize_level!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env, reinitialized = reinitializeable(lvl.lvl))), ctx, mode)
    return lvl
end

function trim_level!(lvl::VirtualSparseBytemapLevel, ctx::LowerJulia, pos)
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = $(ctx(pos)) + 1
        resize!($(lvl.ex).pos, $(lvl.pos_alloc))
        $(lvl.tbl_alloc) = ($(lvl.pos_alloc) - 1) * $(ctx(lvl.I))
        resize!($(lvl.ex).tbl, $(lvl.tbl_alloc))
        $(lvl.srt_alloc) = $(lvl.ex).pos[$(lvl.pos_alloc)] - 1
        resize!($(lvl.ex).srt, $(lvl.srt_alloc))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, lvl.srt_alloc)
    return lvl
end

interval_assembly_depth(lvl::VirtualSparseBytemapLevel) = min(Inf, interval_assembly_depth(lvl.lvl) - 1)

#TODO does this actually support reassembly? I think it needs to filter out indices with unset table entries during finalization
function assemble!(fbr::VirtualFiber{VirtualSparseBytemapLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = cache!(ctx, ctx.freshen(lvl.ex, :_p), getstop(envposition(fbr.env)))
    if extent(envposition(fbr.env)) == 1
        p_start = p_stop
    else
        p_start = cache!(ctx, ctx.freshen(lvl.ex, :_p), getstart(envposition(fbr.env)))
    end
    q_start = ctx.freshen(lvl.ex, :q_start)
    q_stop = ctx.freshen(lvl.ex, :q_stop)
    q = ctx.freshen(lvl.ex, :q)

    push!(ctx.preamble, quote
        $q_start = ($(ctx(p_start)) - 1) * $(ctx(lvl.I)) + 1
        $q_stop = $(ctx(p_stop)) * $(ctx(lvl.I))
        $(lvl.pos_alloc) < ($(ctx(p_stop)) + 1) && ($(lvl.pos_alloc) = Finch.refill!($(lvl.ex).pos, $(zero(lvl.Ti)), $(lvl.pos_alloc), $(ctx(p_stop)) + 1))
        $(lvl.tbl_alloc) < $q_stop && ($(lvl.tbl_alloc) = Finch.refill!($(lvl.ex).tbl, false, $(lvl.tbl_alloc), $q_stop))
    end)

    if interval_assembly_depth(lvl.lvl) >= 1
        assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Extent(value(q_start), value(q_stop)), index = Extent(literal(1), lvl.I), parent=fbr.env)), ctx, mode)
    else
        i = ctx.freshen(lvl.ex, :_i)
        push!(ctx.preamble, quote
            for $q = $q_start:$q_stop
                for $i = 1:$(ctx(lvl.I))
                    $q = ($q - 1) * $(ctx(lvl.I)) + $i
                    assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(q), index=value(i), parent=fbr.env)), ctx, mode)
                end
            end
        end)
    end
end

function finalize_level!(fbr::VirtualFiber{VirtualSparseBytemapLevel}, ctx::LowerJulia, mode)
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    r = ctx.freshen(lvl.ex, :_r)
    p = ctx.freshen(lvl.ex, :_p)
    p_prev = ctx.freshen(lvl.ex, :_p_prev)
    push!(ctx.preamble, quote
        sort!(@view $(lvl.ex).srt[1:$(lvl.srt_stop)])
        $p_prev = 0
        for $r = 1:$(lvl.srt_stop)
            $p = first($(lvl.ex).srt[$r])
            if $p != $p_prev
                $(lvl.ex).pos[$p_prev + 1] = $r
                $(lvl.ex).pos[$p] = $r
            end
            $p_prev = $p
        end
        $(lvl.ex).pos[$p_prev + 1] = $(lvl.srt_stop) + 1
        $(lvl.ex).srt_stop[] = $(lvl.srt_stop)
    end)
    lvl.lvl = finalize_level!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)
    return lvl
end

function unfurl(fbr::VirtualFiber{VirtualSparseBytemapLevel}, ctx, mode, ::Nothing, idx, idxs...)
    if idx.kind === protocol
        @assert idx.mode.kind === literal
        unfurl(fbr, ctx, mode, idx.mode.val, idx.idx, idxs...)
    elseif mode.kind === reader
        unfurl(fbr, ctx, mode, walk, idx, idxs...)
    else
        unfurl(fbr, ctx, mode, laminate, idx, idxs...)
    end
end

function unfurl(fbr::VirtualFiber{VirtualSparseBytemapLevel}, ctx, mode, ::Walk, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_r = ctx.freshen(tag, :_r)
    my_r_stop = ctx.freshen(tag, :_r_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)


    body = Thunk(
        preamble = quote
            $my_r = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_r_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_r != 0 && $my_r < $my_r_stop
                $my_i = last($(lvl.ex).srt[$my_r])
                $my_i_stop = last($(lvl.ex).srt[$my_r_stop - 1])
            else
                $my_i = 1
                $my_i_stop = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (ctx, idx, ext) -> value(my_i_stop),
                body = (start, step) -> Stepper(
                    seek = (ctx, ext) -> quote
                        #$my_r = searchsortedfirst($(lvl.ex).idx, $start, $my_r, $my_r_stop, Base.Forward)
                        while $my_r < $my_r_stop && last($(lvl.ex).srt[$my_r]) < $(ctx(getstart(ext)))
                            $my_r += 1
                        end
                    end,
                    body = Thunk(
                        preamble = :(
                            $my_i = last($(lvl.ex).srt[$my_r])
                        ),
                        body = Step(
                            stride = (ctx, idx, ext) -> value(my_i),
                            chunk = Spike(
                                body = Simplify(literal(default(fbr))),
                                tail = Thunk(
                                    preamble = quote
                                        $my_q = ($(ctx(envposition(fbr.env))) - 1) * $(ctx(lvl.I)) + $my_i
                                    end,
                                    body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=value(my_i, lvl.Ti), parent=fbr.env)), ctx, mode, idxs...),
                                ),
                            ),
                            next = (ctx, idx, ext) -> quote
                                $my_r += 1
                            end
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

function unfurl(fbr::VirtualFiber{VirtualSparseBytemapLevel}, ctx, mode, ::Gallop, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_r = ctx.freshen(tag, :_r)
    my_r_stop = ctx.freshen(tag, :_r_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)

    body = Thunk(
        preamble = quote
            $my_r = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_r_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_r != 0 && $my_r < $my_r_stop
                $my_i = last($(lvl.ex).srt[$my_r])
                $my_i_stop = last($(lvl.ex).srt[$my_r_stop - 1])
            else
                $my_i = 1
                $my_i_stop = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (ctx, idx, ext) -> value(my_i_stop),
                body = (start, step) -> Jumper(
                    body = Thunk(
                        body = Jump(
                            seek = (ctx, ext) -> quote
                                #$my_r = searchsortedfirst($(lvl.ex).idx, $start, $my_r, $my_r_stop, Base.Forward)
                                while $my_r < $my_r_stop && last($(lvl.ex).srt[$my_r]) < $(ctx(getstart(ext_2)))
                                    $my_r += 1
                                end
                                $my_i = last($(lvl.ex).srt[$my_r])
                            end,
                            stride = (ctx, ext) -> value(my_i),
                            body = (ctx, ext, ext_2) -> Switch([
                                value(:($(ctx(getstop(ext_2))) == $my_i)) => Thunk(
                                    body = Spike(
                                        body = Simplify(literal(default(fbr))),
                                        tail = Thunk(
                                            preamble = quote
                                                $my_q = ($(ctx(envposition(fbr.env))) - 1) * $(ctx(lvl.I)) + $my_i
                                            end,
                                            body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=value(my_i, lvl.Ti), parent=fbr.env)), ctx, mode, idxs...),
                                        ),
                                    ),
                                    epilogue = quote
                                        $my_r += 1
                                    end
                                ),
                                literal(true) => Stepper(
                                    seek = (ctx, ext) -> quote
                                        #$my_r = searchsortedfirst($(lvl.ex).idx, $start, $my_r, $my_r_stop, Base.Forward)
                                        while $my_r < $my_r_stop && last($(lvl.ex).srt[$my_r]) < $(ctx(getstart(ext)))
                                            $my_r += 1
                                        end
                                    end,
                                    body = Thunk(
                                        preamble = :(
                                            $my_i = last($(lvl.ex).srt[$my_r])
                                        ),
                                        body = Step(
                                            stride = (ctx, idx, ext) -> value(my_i),
                                            chunk = Spike(
                                                body = Simplify(literal(default(fbr))),
                                                tail = Thunk(
                                                    preamble = quote
                                                        $my_q = ($(ctx(envposition(fbr.env))) - 1) * $(ctx(lvl.I)) + $my_i
                                                    end,
                                                    body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=value(my_i, lvl.Ti), parent=fbr.env)), ctx, mode, idxs...),
                                                ),
                                            ),
                                            next = (ctx, idx, ext) -> quote
                                                $my_r += 1
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
                body = (start, step) -> Run(Simplify(literal(default(fbr))))
            )
        ])
    )

    exfurl(body, ctx, mode, idx)
end

function unfurl(fbr::VirtualFiber{VirtualSparseBytemapLevel}, ctx, mode, ::Follow, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    R = length(envdeferred(fbr.env)) + 1
    my_key = cgx.freshen(tag, :_key)
    my_q = cgx.freshen(tag, :_q)
    q = envposition(fbr.env)

    body = Lookup(
        body = (i) -> Thunk(
            preamble = quote
                $my_q = $(ctx(q)) * $(ctx(lvl.I)) + $(ctx(i))
            end,
            body = Switch([
                value(:($tbl[$my_q])) => refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Tp), index=i, parent=fbr.env)), ctx, mode, idxs...),
                literal(true) => Simplify(literal(default(fbr)))
            ])
        )
    )

    exfurl(body, ctx, mode, idx)
end

hasdefaultcheck(lvl::VirtualSparseBytemapLevel) = true

function unfurl(fbr::VirtualFiber{VirtualSparseBytemapLevel}, ctx, mode, ::Union{Extrude, Laminate}, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_key = ctx.freshen(tag, :_key)
    my_q = ctx.freshen(tag, :_q)
    my_guard = ctx.freshen(tag, :_guard)
    my_seen = ctx.freshen(tag, :_seen)

    body = AcceptSpike(
        val = default(fbr),
        tail = (ctx, idx) -> Thunk(
            preamble = quote
                $my_guard = true
                $my_q = ($(ctx(envposition(fbr.env))) - 1) * $(ctx(lvl.I)) + $(ctx(idx))
            end,
            body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=idx, guard=my_guard, parent=fbr.env)), ctx, mode, idxs...),
            epilogue = begin
                body = quote
                    if !$(lvl.ex).tbl[$my_q]
                        $(lvl.ex).tbl[$my_q] = true
                        $(lvl.srt_stop) += 1
                        $(lvl.srt_alloc) < $(lvl.srt_stop) && ($(lvl.srt_alloc) = $Finch.regrow!($(lvl.ex).srt, $(lvl.srt_alloc), $(lvl.srt_stop)))
                        $(lvl.ex).srt[$(lvl.srt_stop)] = ($(ctx(envposition(fbr.env))), $(ctx(idx)))
                    end
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

    exfurl(body, ctx, mode, idx)
end