struct SolidLevel{Ti, Lvl}
    I::Ti
    lvl::Lvl
end
SolidLevel{Ti}(I, lvl::Lvl) where {Ti, Lvl} = SolidLevel{Ti, Lvl}(I, lvl)
SolidLevel{Ti}(lvl::Lvl) where {Ti, Lvl} = SolidLevel{Ti, Lvl}(zero(Ti), lvl)
SolidLevel(lvl) = SolidLevel(0, lvl)
const Solid = SolidLevel

dimension(lvl::SolidLevel) = lvl.I

@inline arity(fbr::Fiber{<:SolidLevel}) = 1 + arity(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline shape(fbr::Fiber{<:SolidLevel}) = (fbr.lvl.I, shape(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline domain(fbr::Fiber{<:SolidLevel}) = (1:fbr.lvl.I, domain(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline image(fbr::Fiber{<:SolidLevel}) = image(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline default(fbr::Fiber{<:SolidLevel}) = default(Fiber(fbr.lvl.lvl, Environment(fbr.env)))

(fbr::Fiber{<:SolidLevel})() = fbr
function (fbr::Fiber{<:SolidLevel{Ti}})(i, tail...) where {D, Tv, Ti, N, R}
    lvl = fbr.lvl
    p = envposition(fbr.env)
    q = (p - 1) * lvl.I + i
    fbr_2 = Fiber(lvl.lvl, Environment(position=q, index=i, parent=fbr.env))
    fbr_2(tail...)
end

function Base.show(io::IO, lvl::SolidLevel)
    print(io, "Solid(")
    print(io, lvl.I)
    print(io, ", ")
    show(io, lvl.lvl)
    print(io, ")")
end 

function Base.show(io::IO, mime::MIME"text/plain", fbr::Fiber{<:SolidLevel})
    (height, width) = get(io, :displaysize, (40, 80))
    indent = get(io, :indent, 0)
    p = envposition(fbr.env)
    crds = 1:fbr.lvl.I

    print_coord(io, crd) = (print(io, "["); show(io, crd); print(io, "]"))
    print(io, "Solid ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]:")
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
        indent = max(maximum(crd -> textwidth(sprint(print_coord, crd)), crds[[1:N ; end-N:end]]) + 1, indent + 2)
        print_slice_pad(io, crd) = (print(io, " "^(indent - 1 - textwidth(sprint(print_coord, crd)))); print_coord(io, crd); print(io, " "))
        print_fibers(io, crds) = foreach((crd -> (print_slice_pad(io, crd); show(IOContext(io, :indent => indent), mime, fbr(crd)); println(io))), crds)
        println(io)
        if length(crds) > 2N + 1
            print_fibers(io, crds[1:N])
            println(io,  " " ^ (indent - 1), "⋮", " ")
            println(io)
            print_fibers(io, crds[end - N + 1:end])
        else
            print_fibers(io, crds)
        end
    end
end


mutable struct VirtualSolidLevel
    ex
    Ti
    I
    lvl
end
function virtualize(ex, ::Type{SolidLevel{Ti, Lvl}}, ctx, tag=:lvl) where {Ti, Lvl}
    sym = ctx.freshen(tag)
    I = Virtual{Int}(:($sym.I))
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSolidLevel(sym, Ti, I, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualSolidLevel)
    quote
        $SolidLevel{$(lvl.Ti)}(
            $(ctx(lvl.I)),
            $(ctx(lvl.lvl)),
        )
    end
end

getsites(fbr::VirtualFiber{VirtualSolidLevel}) =
    [envdepth(fbr.env) + 1, getsites(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))...]

function getdims(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode)
    ext = Extent(1, fbr.lvl.I)
    if mode != Read()
        ext = suggest(ext)
    end
    (ext, getdims(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)...)
end

function setdims!(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode, dim, dims...)
    fbr.lvl.I = getstop(dim)
    fbr.lvl.lvl = setdims!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode, dims...).lvl
    fbr
end

@inline default(fbr::VirtualFiber{<:VirtualSolidLevel}) = default(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))

reinitializeable(lvl::VirtualSolidLevel) = reinitializeable(lvl.lvl)
function initialize_level!(fbr::VirtualFiber{VirtualSolidLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    fbr.lvl.lvl = initialize_level!(VirtualFiber(fbr.lvl.lvl, Environment(fbr.env, reinitialized=envreinitialized(fbr.env))), ctx, mode)
    return fbr.lvl
end

function reinitialize!(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode)
    lvl = fbr.lvl
    p_start = getstart(envposition(fbr.env))
    p_stop = getstop(envposition(fbr.env))
    q_start = call(*, p_start, lvl.I)
    q_stop = call(*, p_stop, lvl.I)
    if interval_assembly_depth(lvl.lvl) >= 1
        reinitialize!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Extent(q_start, q_stop), index = Extent(1, lvl.I), parent=fbr.env)), ctx, mode)
    else
        p = ctx.freshen(lvl.ex, :_p)
        p = ctx.freshen(lvl.ex, :_q)
        i_2 = ctx.freshen(lvl.ex, :_i)
        push!(ctx.preamble, quote
            for $p = $(ctx(p_start)):$(ctx(p_stop))
                for $i = 1:$(lvl.I)
                    $q = ($p - 1) * $(ctx(lvl.I)) + $i
                    reinitialize!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual(q), index=Virtual(i), parent=fbr.env)), ctx, mode)
                end
            end
        end)
    end
end

interval_assembly_depth(lvl::VirtualSolidLevel) = min(Inf, interval_assembly_depth(lvl.lvl) - 1)

function assemble!(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode)
    lvl = fbr.lvl
    p_start = getstart(envposition(fbr.env))
    p_stop = getstop(envposition(fbr.env))
    q_start = call(*, p_start, lvl.I)
    q_stop = call(*, p_stop, lvl.I)
    if interval_assembly_depth(lvl.lvl) >= 1
        assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Extent(q_start, q_stop), index = Extent(1, lvl.I), parent=fbr.env)), ctx, mode)
    else
        p = ctx.freshen(lvl.ex, :_p)
        p = ctx.freshen(lvl.ex, :_q)
        i_2 = ctx.freshen(lvl.ex, :_i)
        push!(ctx.preamble, quote
            for $p = $(ctx(p_start)):$(ctx(p_stop))
                for $i = 1:$(ctx(lvl.I))
                    $q = ($p - 1) * $(ctx(lvl.I)) + $i
                    assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual(q), index=Virtual(i), parent=fbr.env)), ctx, mode)
                end
            end
        end)
    end
end

function finalize_level!(fbr::VirtualFiber{VirtualSolidLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    fbr.lvl.lvl = finalize_level!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)
    return fbr.lvl
end

hasdefaultcheck(lvl::VirtualSolidLevel) = hasdefaultcheck(lvl.lvl)

unfurl(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode::Union{Write, Update, Read}, idx, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, follow), idxs...)

function unfurl(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode::Union{Read, Write, Update}, idx::Protocol{<:Any, <:Union{Follow, Laminate, Extrude}}, idxs...) #TODO should protocol be strict?
    lvl = fbr.lvl
    tag = lvl.ex

    p = envposition(fbr.env)
    q = ctx.freshen(tag, :_q)
    body = Leaf(
        val = default(fbr),
        body = (i) -> Thunk(
            preamble = quote
                $q = ($(ctx(p)) - 1) * $(ctx(lvl.I)) + $(ctx(i))
            end,
            body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(q), index=i, guard=envdefaultcheck(fbr.env), parent=fbr.env)), ctx, mode, idxs...),
        )
    )

    exfurl(body, ctx, mode, idx.idx)
end