mutable struct SimpleRunLength{Tv, Ti} <: AbstractVector{Tv}
    idx::Vector{Ti}
    val::Vector{Tv}
end

Base.size(vec::SimpleRunLength) = (vec.idx[end], )

function Base.getindex(vec::SimpleRunLength{Tv, Ti}, i) where {Tv, Ti}
    p = findfirst(j->j >= i, vec.idx)
    vec.val[p]
end

mutable struct VirtualSimpleRunLength{Tv, Ti}
    ex
    name
end

function Finch.virtualize(ex, ::Type{SimpleRunLength{Tv, Ti}}, ctx, tag=:tns) where {Tv, Ti}
    sym = ctx.freshen(tag)
    push!(ctx.preamble, :($sym = $ex))
    VirtualSimpleRunLength{Tv, Ti}(sym, tag)
end

(ctx::Finch.LowerJulia)(tns::VirtualSimpleRunLength) = tns.ex

function Finch.initialize!(arr::VirtualSimpleRunLength{Tv}, ctx::Finch.LowerJulia, mode::Union{Write, Update}, idxs...) where {Tv}
    push!(ctx.preamble, quote 
        $(arr.ex).idx = [$(arr.ex).idx[end]]
        $(arr.ex).val = [$(zero(Tv))]
    end)
    access(arr, mode, idxs...)
end 

function Finch.getdims(arr::VirtualSimpleRunLength{Tv, Ti}, ctx::Finch.LowerJulia, mode) where {Tv, Ti}
    ex = Symbol(arr.name, :_stop)
    push!(ctx.preamble, :($ex = $size($(arr.ex))[1]))
    (Extent(1, Virtual{Ti}(ex)),)
end
Finch.setdims!(arr::VirtualSimpleRunLength{Tv, Ti}, ctx::Finch.LowerJulia, mode, dims...) where {Tv, Ti} = arr
Finch.getname(arr::VirtualSimpleRunLength) = arr.name
Finch.setname(arr::VirtualSimpleRunLength, name) = (arr_2 = deepcopy(arr); arr_2.name = name; arr_2)
function (ctx::Finch.Stylize{LowerJulia})(node::Access{<:VirtualSimpleRunLength})
    if ctx.root isa Loop && ctx.root.idx == get_furl_root(node.idxs[1])
        Finch.ChunkStyle()
    else
        mapreduce(ctx, result_style, arguments(node))
    end
end

function (ctx::Finch.ChunkifyVisitor)(node::Access{VirtualSimpleRunLength{Tv, Ti}, Read}, ::Finch.DefaultStyle) where {Tv, Ti}
    vec = node.tns
    my_i′ = ctx.ctx.freshen(getname(vec), :_i1)
    my_p = ctx.ctx.freshen(getname(vec), :_p)
    if getname(ctx.idx) == getname(node.idxs[1])
        tns = Thunk(
            preamble = quote
                $my_p = 1
                $my_i′ = $(vec.ex).idx[$my_p]
            end,
            body = Stepper(
                seek = (ctx, ext) -> quote
                    $my_p = searchsortedfirst($(vec.ex).idx, $(ctx(getstart(ext))), $my_p, length($(vec.ex).idx), Base.Forward)
                    $my_i′ = $(vec.ex).idx[$my_p]
                end,
                body = Step(
                    stride = (ctx, idx, ext) -> my_i′,
                    chunk = Run(
                        body = Simplify(Virtual{Tv}(:($(vec.ex).val[$my_p]))),
                    ),
                    next = (ctx, idx, ext) -> quote
                        if $my_p < length($(vec.ex).idx)
                            $my_p += 1
                            $my_i′ = $(vec.ex).idx[$my_p]
                        end
                    end
                )
            )
        )
        Access(tns, node.mode, node.idxs)
    else
        node
    end
end

function (ctx::Finch.ChunkifyVisitor)(node::Access{<:VirtualSimpleRunLength{Tv, Ti}, <: Union{Write, Update}}, ::Finch.DefaultStyle) where {Tv, Ti}
    vec = node.tns
    my_p = ctx.ctx.freshen(node.tns.name, :_p)
    if getname(ctx.idx) == getname(node.idxs[1])
        tns = Thunk(
            preamble = quote
                $my_p = 0
                $(vec.ex).idx = $Ti[]
                $(vec.ex).val = $Tv[]
            end,
            body = AcceptRun(
                body = (ctx, start, stop) -> Thunk(
                    preamble = quote
                        push!($(vec.ex).val, zero($Tv))
                        $my_p += 1
                    end,
                    body = Virtual{Tv}(:($(vec.ex).val[$my_p])),
                    epilogue = quote
                        push!($(vec.ex).idx, $(ctx(stop)))
                    end
                )
            )
        )
        Access(tns, node.mode, node.idxs)
    else
        node
    end
end

Finch.register()

struct RepeatLevel{Ti, Lvl}
    I::Ti
    pos::Vector{Ti}
    idx::Vector{Ti}
    lvl::Lvl
end
const Repeat = RepeatLevel
RepeatLevel(lvl) = RepeatLevel(0, lvl)
RepeatLevel{Ti}(lvl) where {Ti} = RepeatLevel(zero(Ti), lvl)
RepeatLevel(I::Ti, lvl::Lvl) where {Ti, Lvl} = RepeatLevel{Ti, Lvl}(I, lvl)
RepeatLevel{Ti}(I::Ti, lvl::Lvl) where {Ti, Lvl} = RepeatLevel{Ti, Lvl}(I, lvl)
RepeatLevel{Ti}(I::Ti, pos, idx, lvl::Lvl) where {Ti, Lvl} = RepeatLevel{Ti, Lvl}(I, pos, idx, lvl)
RepeatLevel{Ti, Lvl}(I::Ti, lvl::Lvl) where {Ti, Lvl} = RepeatLevel{Ti, Lvl}(I, Ti[1, fill(0, 16)...], Vector{Ti}(undef, 16), lvl)

parse_level(args, ::Val{:r}, words...) = Repeat(parse_level(args, words...))
summary_f_str(lvl::RepeatLevel) = "r$(summary_f_str(lvl.lvl))"
summary_f_str_args(lvl::RepeatLevel) = summary_f_str_args(lvl.lvl)
similar_level(lvl::RepeatLevel) = Repeat(similar_level(lvl.lvl))
similar_level(lvl::RepeatLevel, dim, tail...) = Repeat(dim, similar_level(lvl.lvl, tail...))

function Base.show(io::IO, lvl::RepeatLevel)
    print(io, "Repeat(")
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

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:RepeatLevel})
    p = envposition(fbr.env)
    crds = fbr.lvl.pos[p]:fbr.lvl.pos[p + 1] - 1
    depth = envdepth(fbr.env)

    print_coord(io, crd) = (print(io, "["); show(io, fbr.lvl.idx[crd]); print(io, "]"); show(io, fbr.lvl.idx[crd + 1] - 1); print(io, "]"))
    get_coord(crd) = crd

    print(io, "│ " ^ depth); print(io, "Repeat ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]")
    display_fiber_data(io, mime, fbr, 1, crds, print_coord, get_coord)
end


@inline arity(fbr::Fiber{<:RepeatLevel}) = 1 + arity(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline shape(fbr::Fiber{<:RepeatLevel}) = (fbr.lvl.I, shape(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline domain(fbr::Fiber{<:RepeatLevel}) = (1:fbr.lvl.I, domain(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline image(fbr::Fiber{<:RepeatLevel}) = image(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline default(fbr::Fiber{<:RepeatLevel}) = default(Fiber(fbr.lvl.lvl, Environment(fbr.env)))

(fbr::Fiber{<:RepeatLevel})() = fbr
function (fbr::Fiber{<:RepeatLevel{Ti}})(i, tail...) where {D, Tv, Ti, N, R}
    lvl = fbr.lvl
    p = envposition(fbr.env)
    r = searchsortedfirst(@view(lvl.idx[lvl.pos[p]:lvl.pos[p + 1] - 1]), i)
    q = lvl.pos[p] + r - 1
    fbr_2 = Fiber(lvl.lvl, Environment(position=q, index=i, parent=fbr.env))
    return r == 0 ? default(fbr_2) : fbr_2(tail...)
end

mutable struct VirtualRepeatLevel
    ex
    Ti
    I
    pos_alloc
    idx_alloc
    lvl
end
function virtualize(ex, ::Type{RepeatLevel{Ti, Lvl}}, ctx, tag=:lvl) where {Ti, Lvl}
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
    VirtualRepeatLevel(sym, Ti, I, pos_alloc, idx_alloc, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualRepeatLevel)
    quote
        $RepeatLevel{$(lvl.Ti)}(
            $(ctx(lvl.I)),
            $(lvl.ex).pos,
            $(lvl.ex).idx,
            $(ctx(lvl.lvl)),
        )
    end
end

summary_f_str(lvl::VirtualRepeatLevel) = "r$(summary_f_str(lvl.lvl))"
summary_f_str_args(lvl::VirtualRepeatLevel) = summary_f_str_args(lvl.lvl)

getsites(fbr::VirtualFiber{VirtualRepeatLevel}) =
    [envdepth(fbr.env) + 1, getsites(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))...]

function getdims(fbr::VirtualFiber{VirtualRepeatLevel}, ctx, mode)
    ext = Extent(1, fbr.lvl.I)
    if mode != Read()
        ext = suggest(ext)
    end
    (ext, getdims(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)...)
end

function setdims!(fbr::VirtualFiber{VirtualRepeatLevel}, ctx, mode, dim, dims...)
    fbr.lvl.I = getstop(dim)
    fbr.lvl.lvl = setdims!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode, dims...).lvl
    fbr
end

@inline default(fbr::VirtualFiber{<:VirtualRepeatLevel}) = default(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualRepeatLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    lvl = fbr.lvl
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = length($(lvl.ex).pos)
        $(lvl.ex).pos[1] = 1
        $(lvl.idx_alloc) = length($(lvl.ex).idx)
    end)
    lvl.lvl = initialize_level!(VirtualFiber(fbr.lvl.lvl, Environment(fbr.env)), ctx, mode)
    return lvl
end

interval_assembly_depth(lvl::VirtualRepeatLevel) = Inf

#This function is quite simple, since RepeatLevels don't support reassembly.
function assemble!(fbr::VirtualFiber{VirtualRepeatLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), getstop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) < ($p_stop + 1) && ($(lvl.pos_alloc) = $Finch.regrow!($(lvl.ex).pos, $(lvl.pos_alloc), $p_stop + 1))
    end)
end

function finalize_level!(fbr::VirtualFiber{VirtualRepeatLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    fbr.lvl.lvl = finalize_level!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)
    return fbr.lvl
end

unfurl(fbr::VirtualFiber{VirtualRepeatLevel}, ctx, mode::Read, idx, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, walk))

function unfurl(fbr::VirtualFiber{VirtualRepeatLevel}, ctx, mode::Read, idx::Protocol{<:Any, Walk}, idxs...)
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
                    chunk = Run(
                        val = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                    ),
                    next = (ctx, idx, ext) -> quote
                        $my_q += 1
                    end
                )
            )
        )
    )

    exfurl(body, ctx, mode, idx.idx)
end

function unfurl(fbr::VirtualFiber{VirtualRepeatLevel}, ctx, mode::Read, idx::Protocol{<:Any, Gallop}, idxs...)
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

unfurl(fbr::VirtualFiber{VirtualRepeatLevel}, ctx, mode::Union{Write, Update}, idx, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, extrude), idxs...)

function unfurl(fbr::VirtualFiber{VirtualRepeatLevel}, ctx, mode::Union{Write, Update}, idx::Protocol{<:Any, Extrude}, idxs...)
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