struct SparseBandLevel{Ti, Lvl}
    I::Ti
    pos::Vector{Ti}
    idx::Vector{Ti}
    lvl::Lvl
end
const SparseBand = SparseBandLevel
SparseBandLevel(lvl) = SparseBandLevel(0, lvl)
SparseBandLevel{Ti}(lvl) where {Ti} = SparseBandLevel(zero(Ti), lvl)
SparseBandLevel(I::Ti, lvl::Lvl) where {Ti, Lvl} = SparseBandLevel{Ti, Lvl}(I, lvl)
SparseBandLevel{Ti}(I::Ti, lvl::Lvl) where {Ti, Lvl} = SparseBandLevel{Ti, Lvl}(I, lvl)
SparseBandLevel{Ti}(I::Ti, pos, idx, lvl::Lvl) where {Ti, Lvl} = SparseBandLevel{Ti, Lvl}(I, pos, idx, lvl)
SparseBandLevel{Ti, Lvl}(I::Ti, lvl::Lvl) where {Ti, Lvl} = SparseBandLevel{Ti, Lvl}(I, Ti[1, fill(0, 16)...], Vector{Ti}(undef, 16), lvl)

"""
`f_code(l)` = [SparseBandLevel](@ref).
"""
f_code(::Val{:sl}) = SparseBand
summary_f_code(lvl::SparseBandLevel) = "sl($(summary_f_code(lvl.lvl)))"
similar_level(lvl::SparseBandLevel) = SparseBand(similar_level(lvl.lvl))
similar_level(lvl::SparseBandLevel, dim, tail...) = SparseBand(dim, similar_level(lvl.lvl, tail...))

(fbr::Fiber{<:SparseBandLevel})() = fbr
function (fbr::Fiber{<:SparseBandLevel{Ti}})(i, tail...) where {D, Tv, Ti, N, R}
    lvl = fbr.lvl
    p = envposition(fbr.env)
    start = idx[p]
    stop = idx[p] + pos[p + 1] - pos[p]
    q = lvl.pos[p] + i - pos[p]
    fbr_2 = Fiber(lvl.lvl, Environment(position=q, index=i, parent=fbr.env))
    start < i <= stop ? fbr_2(tail...) : default(fbr_2)
end

pattern!(lvl::SparseBandLevel{Ti}) where {Ti} = 
    SparseBandLevel{Ti}(lvl.I, lvl.pos, lvl.idx, pattern!(lvl.lvl))

function Base.show(io::IO, lvl::SparseBandLevel)
    print(io, "SparseBand(")
    print(io, lvl.I)
    print(io, ", ")
    if get(io, :compact, true)
        print(io, "…")
    else
        show_region(io, lvl.pos)
        print(io, ", ")
        show_region(io, lvl.idx)
    end
    print(io, ", ")
    show(io, lvl.lvl)
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:SparseBandLevel})
    p = envposition(fbr.env)
    crds = @view((fbr.lvl.idx[fbr.lvl.pos[p]] + 1) : (fbr.lvl.idx[fbr.lvl.pos[p]] + fbr.lvl.pos[p + 1] - fbr.lvl.pos[p]))
    depth = envdepth(fbr.env)

    print_coord(io, crd) = (print(io, "["); show(io, crd); print(io, "]"))
    get_coord(crd) = crd

    print(io, "│ " ^ depth); print(io, "SparseBand ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]")
    display_fiber_data(io, mime, fbr, 1, crds, print_coord, get_coord)
end

@inline arity(fbr::Fiber{<:SparseBandLevel}) = 1 + arity(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline Base.size(fbr::Fiber{<:SparseBandLevel}) = (fbr.lvl.I, size(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline domain(fbr::Fiber{<:SparseBandLevel}) = (1:fbr.lvl.I, domain(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline image(fbr::Fiber{<:SparseBandLevel}) = image(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline default(fbr::Fiber{<:SparseBandLevel}) = default(Fiber(fbr.lvl.lvl, Environment(fbr.env)))


mutable struct VirtualSparseBandLevel
    ex
    Ti
    I
    pos_alloc
    idx_alloc
    lvl
end
function virtualize(ex, ::Type{SparseBandLevel{Ti, Lvl}}, ctx, tag=:lvl) where {Ti, Lvl}
    sym = ctx.freshen(tag)
    I = Virtual{Int}(:($sym.I))
    pos_alloc = ctx.freshen(sym, :_pos_alloc)
    idx_alloc = ctx.freshen(sym, :_idx_alloc)
    push!(ctx.preamble, quote
        $sym = $ex
        $pos_alloc = length($sym.pos)
        $idx_alloc = length($sym.idx)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseBandLevel(sym, Ti, I, pos_alloc, idx_alloc, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualSparseBandLevel)
    quote
        $SparseBandLevel{$(lvl.Ti)}(
            $(ctx(lvl.I)),
            $(lvl.ex).pos,
            $(lvl.ex).idx,
            $(ctx(lvl.lvl)),
        )
    end
end

summary_f_str(lvl::VirtualSparseBandLevel) = "l$(summary_f_str(lvl.lvl))"
summary_f_str_args(lvl::VirtualSparseBandLevel) = summary_f_str_args(lvl.lvl)

getsites(fbr::VirtualFiber{VirtualSparseBandLevel}) =
    [envdepth(fbr.env) + 1, getsites(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))...]

function getdims(fbr::VirtualFiber{VirtualSparseBandLevel}, ctx, mode)
    ext = Extent(1, fbr.lvl.I)
    if mode != Read()
        ext = suggest(ext)
    end
    (ext, getdims(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)...)
end

function setdims!(fbr::VirtualFiber{VirtualSparseBandLevel}, ctx, mode, dim, dims...)
    fbr.lvl.I = getstop(dim)
    fbr.lvl.lvl = setdims!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode, dims...).lvl
    fbr
end

@inline default(fbr::VirtualFiber{<:VirtualSparseBandLevel}) = default(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))
@inline image(fbr::VirtualFiber{VirtualSparseBandLevel}) = image(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualSparseBandLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    lvl = fbr.lvl
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = length($(lvl.ex).pos)
        $(lvl.ex).pos[1] = 1
        $(lvl.ex).pos[2] = 1
        $(lvl.idx_alloc) = length($(lvl.ex).idx)
    end)
    lvl.lvl = initialize_level!(VirtualFiber(fbr.lvl.lvl, Environment(fbr.env)), ctx, mode)
    return lvl
end

interval_assembly_depth(lvl::VirtualSparseBandLevel) = Inf

#This function is quite simple, since SparseBandLevels don't support reassembly.
function assemble!(fbr::VirtualFiber{VirtualSparseBandLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), getstop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) < ($p_stop + 1) && ($(lvl.pos_alloc) = $Finch.regrow!($(lvl.ex).pos, $(lvl.pos_alloc), $p_stop + 1))
    end)
end

function finalize_level!(fbr::VirtualFiber{VirtualSparseBandLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    fbr.lvl.lvl = finalize_level!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)
    return fbr.lvl
end

unfurl(fbr::VirtualFiber{VirtualSparseBandLevel}, ctx, mode::Read, idx, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, walk), idxs...)

function unfurl(fbr::VirtualFiber{VirtualSparseBandLevel}, ctx, mode::Read, idx::Protocol{<:Any, Walk}, idxs...)
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
                stride = (ctx, idx, ext) -> my_i1,
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
                            stride = (ctx, idx, ext) -> my_i,
                            chunk = Spike(
                                body = Simplify(default(fbr)),
                                tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                            ),
                            next = (ctx, idx, ext) -> quote
                                $my_q += 1
                            end
                        )
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(default(fbr)))
            )
        ])
    )

    exfurl(body, ctx, mode, idx.idx)
end

function unfurl(fbr::VirtualFiber{VirtualSparseBandLevel}, ctx, mode::Read, idx::Protocol{<:Any, Gallop}, idxs...)
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
                stride = (ctx, idx, ext) -> my_i1,
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
                            stride = (ctx, ext) -> my_i,
                            body = (ctx, ext, ext_2) -> Switch([
                                :($(ctx(getstop(ext_2))) == $my_i) => Thunk(
                                    body = Spike(
                                        body = Simplify(default(fbr)),
                                        tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                                    ),
                                    epilogue = quote
                                        $my_q += 1
                                    end
                                ),
                                true => Stepper(
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
                                            stride = (ctx, idx, ext) -> my_i,
                                            chunk = Spike(
                                                body = Simplify(default(fbr)),
                                                tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
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
                body = (start, step) -> Run(Simplify(default(fbr)))
            )
        ])
    )

    exfurl(body, ctx, mode, idx.idx)
end

unfurl(fbr::VirtualFiber{VirtualSparseBandLevel}, ctx, mode::Union{Write, Update}, idx, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, extrude), idxs...)

function unfurl(fbr::VirtualFiber{VirtualSparseBandLevel}, ctx, mode::Union{Write, Update}, idx::Protocol{<:Any, Extrude}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)
    my_guard = if hasdefaultcheck(lvl.lvl)
        ctx.freshen(tag, :_isdefault)
    end

    push!(ctx.preamble, quote
        $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
    end)

    body = AcceptSpike(
        val = default(fbr),
        tail = (ctx, idx) -> Thunk(
            preamble = quote
                $(begin
                    assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=my_q, parent=fbr.env)), ctx, mode)
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
            body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=idx, guard=my_guard, parent=fbr.env)), ctx, mode, idxs...),
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
    end)

    exfurl(body, ctx, mode, idx.idx)
end