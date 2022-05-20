struct HollowCooLevel{N, Ti<:Tuple, Tq, Tbl, Lvl}
    I::Ti
    tbl::Tbl
    pos::Vector{Tq}
    lvl::Lvl
end
const HollowCoo = HollowCooLevel
HollowCooLevel{N}(lvl) where {N} = HollowCooLevel{N}((0 for _ in 1:N...), lvl)
HollowCooLevel{N, Ti}(lvl) where {N, Ti} = HollowCooLevel{N, Ti}((map(zero, Ti.parameters)..., ), lvl)
HollowCooLevel{N}(I::Ti, lvl) where {N, Ti} = HollowCooLevel{N, Ti}(I, lvl)
HollowCooLevel{N, Ti}(I::Ti, lvl) where {N, Ti} = HollowCooLevel{N, Ti, Int}(I, lvl)
HollowCooLevel{N, Ti, Tq}(I::Ti, lvl) where {N, Ti, Tq} = HollowCooLevel{N, Ti, Tq}(I, ((Vector{T}(undef, 16) for T in Ti.parameters)...,), Tq[1, 1, 3:17...], lvl)
HollowCooLevel{N, Ti, Tq}(I::Ti, tbl::Tbl, pos, lvl) where {N, Ti, Tq, Tbl} =
    HollowCooLevel{N, Ti, Tq, Tbl}(I, tbl, pos, lvl)
HollowCooLevel{N, Ti, Tq, Tbl}(I::Ti, tbl::Tbl, pos, lvl::Lvl) where {N, Ti, Tq, Tbl, Lvl} =
    HollowCooLevel{N, Ti, Tq, Tbl, Lvl}(I, tbl, pos, lvl)

@inline arity(fbr::Fiber{<:HollowCooLevel{N}}) where {N} = N + arity(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))
@inline shape(fbr::Fiber{<:HollowCooLevel{N}}) where {N} = (fbr.lvl.I..., shape(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))...)
@inline domain(fbr::Fiber{<:HollowCooLevel{N}}) where {N} = (map(Base.OneTo, fbr.lvl.I)..., domain(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))...)
@inline image(fbr::Fiber{<:HollowCooLevel{N}}) where {N} = image(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))
@inline default(fbr::Fiber{<:HollowCooLevel{N}}) where {N} = default(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))

function (fbr::Fiber{<:HollowCooLevel{N, Ti}})(i, tail...) where {N, Ti}
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



mutable struct VirtualHollowCooLevel
    ex
    N
    Ti
    Tq
    Tbl
    I
    pos_alloc
    idx_alloc
    lvl
end
function virtualize(ex, ::Type{HollowCooLevel{N, Ti, Tq, Tbl, Lvl}}, ctx, tag=:lvl) where {N, Ti, Tq, Tbl, Lvl}   
    sym = ctx.freshen(tag)
    I = ctx.freshen(sym, :_I)
    pos_alloc = ctx.freshen(sym, :_pos_alloc)
    idx_alloc = ctx.freshen(sym, :_idx_alloc)
    push!(ctx.preamble, quote
        $sym = $ex
        $I = $sym.I
        $pos_alloc = length($sym.pos)
        $idx_alloc = length($sym.tbl)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualHollowCooLevel(sym, N, Ti, Tq, Tbl, I, pos_alloc, idx_alloc, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualHollowCooLevel)
    quote
        $HollowCooLevel{$(lvl.N), $(lvl.Ti), $(lvl.Tq), $(lvl.Tbl)}(
            $(ctx(lvl.I)),
            $(lvl.ex).tbl,
            $(lvl.ex).pos,
            $(ctx(lvl.lvl)),
        )
    end
end

function getdims(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode)
    ext = map(n->Extent(1, Virtual{Int}(:($(fbr.lvl.I)[$n]))), 1:fbr.lvl.N)
    (ext..., getdims(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^fbr.lvl.N)(fbr.env)), ctx, mode)...)
end

function setdims!(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode, dims...)
    push!(ctx.preamble, :($(fbr.lvl.I) = ($(map(dim->ctx(stop(dim)), dims[1:fbr.lvl.N])...),)))
    setdims!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode, dims[fbr.lvl.N + 1:end]...)
end

@inline default(fbr::VirtualFiber{VirtualHollowCooLevel}) = default(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^fbr.lvl.N)(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx::LowerJulia, mode::Union{Write, Update})
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

interval_assembly_depth(lvl::VirtualHollowCooLevel) = Inf

#This function is quite simple, since HollowCooLevels don't support reassembly.
function assemble!(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), stop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) < ($p_stop + 1) && ($(lvl.pos_alloc) = $Finch.regrow!($(lvl.ex).pos, $(lvl.pos_alloc), $p_stop + 1))
    end)
end

function finalize_level!(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl

    lvl.lvl = finalize_level!(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^lvl.N)(fbr.env)), ctx, mode)
    return lvl
end

unfurl(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode::Read, idx::Name, idxs...) =
    unfurl(fbr, ctx, mode, walk(idx))

function unfurl(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode::Read, idx::Walk, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_step = ctx.freshen(tag, :_q_step)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)
    R = length(envdeferred(fbr.env)) + 1
    if R == 1
        q_start = Virtual{lvl.Tq}(:($(lvl.ex).pos[$(ctx(envposition(fbr.env)))]))
        q_stop = Virtual{lvl.Tq}(:($(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]))
    else
        q_start = fbr.env.start
        q_stop = fbr.env.stop
    end

    Thunk(
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
                stride = (start) -> my_i_stop,
                body = (start, step) -> Stepper(
                    body = Thunk(
                        preamble = quote
                            $my_i = $(lvl.ex).tbl[$R][$my_q]
                        end,
                        body = Phase(
                            guard = (start) -> :($my_q < $my_q_stop),
                            stride = (start) -> my_i,
                            body = (start, step) -> Thunk(
                                body = Cases([
                                    :($step == $my_i) => if R == lvl.N
                                        Thunk(
                                            body = Spike(
                                                body = Simplify(default(fbr)),
                                                tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Tq}(:($my_q)), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                                            ),
                                            epilogue = quote
                                                $my_q += 1
                                            end
                                        )
                                    else
                                        Thunk(
                                            preamble = quote
                                                $my_q_step = $my_q + 1
                                                while $my_q_step < $my_q_stop && $(lvl.ex).tbl[$R][$my_q_step] == $my_i
                                                    $my_q_step += 1
                                                end
                                            end,
                                            body = Spike(
                                                body = Simplify(default(fbr)),
                                                tail = refurl(VirtualFiber(lvl, VirtualEnvironment(start=Virtual{lvl.Ti}(my_q), stop=Virtual{lvl.Ti}(my_q_step), index=Virtual{lvl.Ti}(my_i), parent=fbr.env, internal=true)), ctx, mode, idxs...),
                                            ),
                                            epilogue = quote
                                                $my_q = $my_q_step
                                            end
                                        )
                                    end,
                                    true => Run(
                                        body = default(fbr),
                                    ),
                                ])
                            )
                        )
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(default(fbr)))
            )
        ])
    )
end

hasdefaultcheck(lvl::VirtualHollowCooLevel) = true

function unfurl(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode::Union{Write, Update}, idx::Union{Name, Extrude}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    R = length(envdeferred(fbr.env)) + 1
    my_key = ctx.freshen(tag, :_key)
    my_q = ctx.freshen(tag, :_q)
    my_guard = ctx.freshen(tag, :_guard)

    if R == lvl.N
        Thunk(
            preamble = quote
                $my_q = $(lvl.ex).pos[$(ctx(envposition(envexternal(fbr.env))))]
            end,
            body = AcceptSpike(
                val = default(fbr),
                tail = (ctx, idx) -> Thunk(
                    preamble = quote
                        $my_guard = true
                        $(contain(ctx) do ctx_2 
                            assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=my_q, parent=fbr.env)), ctx_2, mode)
                            quote end
                        end)
                    end,
                    body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=idx, guard=my_guard, parent=fbr.env)), ctx, mode, idxs...),
                    epilogue = begin
                        resize_body = quote end
                        write_body = quote end
                        idxs = map(ctx, (envdeferred(fbr.env)..., idx))
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
                            write_body = quote
                                $write_body
                                $(lvl.ex).tbl[$n][$my_q] = $(idxs[n])
                            end
                        end
                        body = quote
                            if $(lvl.idx_alloc) < $my_q
                                $resize_body
                            end
                            $write_body
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
            ),
            epilogue = quote
                $(lvl.ex).pos[$(ctx(envposition(envexternal(fbr.env)))) + 1] = $my_q
            end
        )
    else
        Leaf(
            body = (i) -> refurl(VirtualFiber(lvl, VirtualEnvironment(index=i, parent=fbr.env, internal=true)), ctx, mode, idxs...)
        )
    end
end