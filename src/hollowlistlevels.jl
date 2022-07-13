struct HollowListLevel{Ti, Lvl}
    I::Ti
    pos::Vector{Ti}
    idx::Vector{Ti}
    lvl::Lvl
end
const HollowList = HollowListLevel
HollowListLevel(lvl) = HollowListLevel(0, lvl)
HollowListLevel{Ti}(lvl) where {Ti} = HollowListLevel(zero(Ti), lvl)
HollowListLevel(I::Ti, lvl::Lvl) where {Ti, Lvl} = HollowListLevel{Ti, Lvl}(I, lvl)
HollowListLevel{Ti}(I::Ti, lvl::Lvl) where {Ti, Lvl} = HollowListLevel{Ti, Lvl}(I, lvl)
HollowListLevel{Ti}(I::Ti, pos, idx, lvl::Lvl) where {Ti, Lvl} = HollowListLevel{Ti, Lvl}(I, pos, idx, lvl)
HollowListLevel{Ti, Lvl}(I::Ti, lvl::Lvl) where {Ti, Lvl} = HollowListLevel{Ti, Lvl}(I, Ti[1, fill(0, 16)...], Vector{Ti}(undef, 16), lvl)

function Base.show(io::IO, lvl::HollowListLevel)
    print(io, "HollowList(")
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

function Base.show(io::IO, mime::MIME"text/plain", fbr::Fiber{<:HollowListLevel})
    (height, width) = get(io, :displaysize, (40, 80))
    indent = get(io, :indent, 0)
    p = envposition(fbr.env)
    crds = @view(fbr.lvl.idx[fbr.lvl.pos[p]:fbr.lvl.pos[p + 1] - 1])

    print_coord(io, crd) = (print(io, "["); show(io, crd); print(io, "]"))
    print(io, "HollowList ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]:")
    if arity(fbr) == 1
        print_elem(io, crd) = show(IOContext(io, :compact=>true), fbr(crd))
        calc_pad(crd) = max(textwidth(sprint(print_coord, crd)), textwidth(sprint(print_elem, crd)))
        print_coord_pad(io, crd) = (print_coord(io, crd); print(io, " "^(calc_pad(crd) - textwidth(sprint(print_coord, crd)))))
        print_elem_pad(io, crd) = (print_elem(io, crd); print(io, " "^(calc_pad(crd) - textwidth(sprint(print_elem, crd)))))
        print_coords(io, crds) = (foreach(crd -> (print_coord_pad(io, crd); print(io, " ")), crds[1:end-1]); if !isempty(crds) print_coord_pad(io, crds[end]) end)
        print_elems(io, crds) = (foreach(crd -> (print_elem_pad(io, crd); print(io, " ")), crds[1:end-1]); if !isempty(crds) print_elem_pad(io, crds[end]) end)
        width -= indent
        if length(crds) < width && textwidth(sprint(print_coords, crds)) < width
            print(io, " " ^ indent); print_coords(io, crds); println(io)
            print(io, " " ^ indent); print_elems(io, crds); println(io)
        else
            leftwidth = cld(width - 1, 2)
            leftsize = searchsortedlast(cumsum(map(calc_pad, crds[1:min(end, leftwidth)]) .+ 1), leftwidth)
            leftpad = " " ^ (leftwidth - textwidth(sprint(print_coords, crds[1:leftsize])))
            rightwidth = width - leftwidth - 1
            rightsize = searchsortedlast(cumsum(map(calc_pad, reverse(crds[max(end - rightwidth, 1):end])) .+ 1), rightwidth)
            rightpad = " " ^ (rightwidth - textwidth(sprint(print_coords, crds[end-rightsize + 1:end])))
            print(io, " " ^ indent); print_coords(io, crds[1:leftsize]); print(io, leftpad, " ", rightpad); print_coords(io, crds[end-rightsize + 1:end]); println(io)
            print(io, " " ^ indent); print_elems(io, crds[1:leftsize]); print(io, leftpad, "…", rightpad); print_elems(io, crds[end-rightsize + 1:end]); println(io)
        end
    else
        N = 2
        indent = maximum(crd -> textwidth(sprint(print_coord, crd)), crds[[1:N ; end-N:end]]) + 1
        print_slice_pad(io, crd) = (print(io, " "^(indent - 1 - textwidth(sprint(print_coord, crd)))); print_coord(io, crd); print(io, " "))
        print_fibers(io, crds) = foreach((crd -> (print_slice_pad(io, crd); show(IOContext(io, :indent => indent), mime, fbr(crd)))), crds)
        if length(crds) > 2N + 1
            print_fibers(io, crds[1:N])
            println(io)
            println(io, " " ^ indent, "⋮")
            println(io)
            print_fibers(io, crds[end - N + 1:end])
        else
            print_fibers(io, crds)
        end
    end
end

@inline arity(fbr::Fiber{<:HollowListLevel}) = 1 + arity(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline shape(fbr::Fiber{<:HollowListLevel}) = (fbr.lvl.I, shape(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline domain(fbr::Fiber{<:HollowListLevel}) = (1:fbr.lvl.I, domain(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline image(fbr::Fiber{<:HollowListLevel}) = image(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline default(fbr::Fiber{<:HollowListLevel}) = default(Fiber(fbr.lvl.lvl, Environment(fbr.env)))

(fbr::Fiber{<:HollowListLevel})() = fbr
function (fbr::Fiber{<:HollowListLevel{Ti}})(i, tail...) where {D, Tv, Ti, N, R}
    lvl = fbr.lvl
    p = envposition(fbr.env)
    r = searchsorted(@view(lvl.idx[lvl.pos[p]:lvl.pos[p + 1] - 1]), i)
    q = lvl.pos[p] + first(r) - 1
    fbr_2 = Fiber(lvl.lvl, Environment(position=q, index=i, parent=fbr.env))
    length(r) == 0 ? default(fbr_2) : fbr_2(tail...)
end

mutable struct VirtualHollowListLevel
    ex
    Ti
    I
    pos_alloc
    idx_alloc
    lvl
end
function virtualize(ex, ::Type{HollowListLevel{Ti, Lvl}}, ctx, tag=:lvl) where {Ti, Lvl}
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
    VirtualHollowListLevel(sym, Ti, I, pos_alloc, idx_alloc, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualHollowListLevel)
    quote
        $HollowListLevel{$(lvl.Ti)}(
            $(ctx(lvl.I)),
            $(lvl.ex).pos,
            $(lvl.ex).idx,
            $(ctx(lvl.lvl)),
        )
    end
end

getsites(fbr::VirtualFiber{VirtualHollowListLevel}) =
    [envdepth(fbr.env) + 1, getsites(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))...]

function getdims(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode)
    ext = Extent(1, fbr.lvl.I)
    if mode != Read()
        ext = suggest(ext)
    end
    (ext, getdims(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)...)
end

function setdims!(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode, dim, dims...)
    fbr.lvl.I = getstop(dim)
    fbr.lvl.lvl = setdims!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode, dims...).lvl
    fbr
end

@inline default(fbr::VirtualFiber{<:VirtualHollowListLevel}) = default(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualHollowListLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    lvl = fbr.lvl
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = length($(lvl.ex).pos)
        $(lvl.ex).pos[1] = 1
        $(lvl.idx_alloc) = length($(lvl.ex).idx)
    end)
    lvl.lvl = initialize_level!(VirtualFiber(fbr.lvl.lvl, Environment(fbr.env)), ctx, mode)
    return lvl
end

interval_assembly_depth(lvl::VirtualHollowListLevel) = Inf

#This function is quite simple, since HollowListLevels don't support reassembly.
function assemble!(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), getstop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) < ($p_stop + 1) && ($(lvl.pos_alloc) = $Finch.regrow!($(lvl.ex).pos, $(lvl.pos_alloc), $p_stop + 1))
    end)
end

function finalize_level!(fbr::VirtualFiber{VirtualHollowListLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    fbr.lvl.lvl = finalize_level!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)
    return fbr.lvl
end

unfurl(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode::Read, idx, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, walk))

function unfurl(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode::Read, idx::Protocol{<:Any, Walk}, idxs...)
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

function unfurl(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode::Read, idx::Protocol{<:Any, Gallop}, idxs...)
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
                            body = (ctx, ext, ext_2) -> Cases([
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

unfurl(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode::Union{Write, Update}, idx, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, extrude), idxs...)

function unfurl(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode::Union{Write, Update}, idx::Protocol{<:Any, Extrude}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)
    my_guard = if hasdefaultcheck(lvl.lvl)
        ctx.freshen(tag, :_isdefault)
    end

    body = Thunk(
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
        end,
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
        ),
        epilogue = quote
            $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1] = $my_q
        end
    )

    exfurl(body, ctx, mode, idx.idx)
end