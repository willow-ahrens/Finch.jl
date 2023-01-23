include("environments.jl")

"""
    Fiber(lvl, env=Environment())

A fiber is a combination of a (possibly nested) level `lvl` and an environment
`env`. The environment is often used to refer to a particular fiber within the
level. Fibers are arrays, of sorts. The function `refindex(fbr, i...)` is used
as a reference implementation of getindex for the fiber. Accessing an
`N`-dimensional fiber with less than `N` indices will return another fiber.
"""
struct Fiber{Lvl, Env}
    lvl::Lvl
    env::Env
end
Fiber(lvl::Lvl) where {Lvl} = Fiber{Lvl}(lvl)
Fiber{Lvl}(lvl::Lvl, env::Env=Environment()) where {Lvl, Env} = Fiber{Lvl, Env}(lvl, env)

@inline Base.ndims(::Fiber{Lvl}) where {Lvl} = level_ndims(Lvl)
@inline Base.ndims(::Type{<:Fiber{Lvl}}) where {Lvl} = level_ndims(Lvl)
@inline Base.size(fbr::Fiber) = level_size(fbr.lvl)
@inline Base.axes(fbr::Fiber) = level_axes(fbr.lvl)
@inline Base.eltype(::Fiber{Lvl}) where {Lvl} = level_eltype(Lvl)
@inline Base.eltype(::Type{<:Fiber{Lvl}}) where {Lvl} = level_eltype(Lvl)
@inline default(::Fiber{Lvl}) where {Lvl} = level_default(Lvl)
@inline default(::Type{<:Fiber{Lvl}}) where {Lvl} = level_default(Lvl)

"""
    VirtualFiber(lvl, env)

A virtual fiber is the avatar of a fiber for the purposes of compilation. Two
fibers should share a `name` only if they hold the same data. `lvl` is a virtual
object representing the level nest and `env` is a virtual object representing
the environment.
"""
mutable struct VirtualFiber{Lvl}
    lvl::Lvl
    env
    function VirtualFiber{Lvl}(lvl::Lvl, env) where {Lvl}
        @assert !(lvl isa Vector)
        @assert env != nothing
        new{Lvl}(lvl, env)
    end
end
VirtualFiber(lvl::Lvl, env) where {Lvl} = VirtualFiber{Lvl}(lvl, env)

function virtualize(ex, ::Type{<:Fiber{Lvl, Env}}, ctx, tag=ctx.freshen(:tns)) where {Lvl, Env}
    lvl = virtualize(:($ex.lvl), Lvl, ctx, Symbol(tag, :_lvl))
    env = virtualize(:($ex.env), Env, ctx)
    env.name = tag
    VirtualFiber(lvl, env)
end
(ctx::Finch.LowerJulia)(fbr::VirtualFiber) = :(Fiber($(ctx(fbr.lvl)), $(ctx(fbr.env))))
IndexNotation.isliteral(::VirtualFiber) =  false

virtual_size(tns::VirtualFiber, ctx) = virtual_level_size(tns.lvl, ctx)
function virtual_resize!(tns::VirtualFiber, ctx, dims...)
    tns.lvl = virtual_level_resize!(tns.lvl, ctx, dims...)
    tns
end
virtual_eltype(tns::VirtualFiber) = virtual_level_eltype(tns.lvl)
virtual_default(tns::VirtualFiber) = virtual_level_default(tns.lvl)

getname(fbr::VirtualFiber) = envname(fbr.env)
setname(fbr::VirtualFiber, name) = VirtualFiber(fbr.lvl, envrename!(fbr.env, name))
#setname(fbr::VirtualFiber, name) = (fbr.env.name = name; fbr)

"""
    default(fbr)

The default for a fiber is the value that each element of the fiber will have
after initialization. This value is most often zero, and defaults to nothing.

See also: [`initialize!`](@ref)
"""
function default end

"""
    initialize!(fbr, ctx, mode)

Initialize the virtual fiber to it's default value in the context `ctx` with
access mode `mode`. Return the new fiber object.
"""
function initialize!(fbr::VirtualFiber, ctx::LowerJulia, mode, idxs...)
    if mode.kind === updater
        lvl = initialize_level!(fbr.lvl, ctx, mode)
        push!(ctx.preamble, assemble_level!(lvl, ctx, literal(1), literal(1)))
        fbr = VirtualFiber(lvl, fbr.env)
    end
    return access(refurl(fbr, ctx, mode), mode, idxs...)
end

"""
    initialize_level!(fbr, ctx, mode)

Initialize the level within the virtual fiber to it's default value in the
context `ctx` with access mode `mode`. Return the new level.
"""
function initialize_level! end

initialize_level!(fbr, ctx, mode) = fbr.lvl



"""
    freeze!(fbr, ctx, mode, idxs...)

Freeze the virtual fiber in the context `ctx` with access mode `mode`. Return
the new fiber object.
"""
function freeze!(fbr::VirtualFiber, ctx::LowerJulia, mode, idxs...)
    if mode.kind === updater
        return VirtualFiber(freeze_level!(fbr.lvl, ctx, envposition(fbr.env)), fbr.env)
    else
        return fbr
    end
end

"""
    freeze_level!(fbr, ctx, mode)

Freeze the level within the virtual fiber. These are the bulk cleanup steps.
"""
function freeze_level! end

freeze_level!(fbr, ctx, mode) = fbr.lvl

function trim!(fbr::VirtualFiber, ctx)
    delete!(fbr.env, :name)
    VirtualFiber(trim_level!(fbr.lvl, ctx, 1), fbr.env)
end
trim!(fbr, ctx) = fbr

#TODO get rid of isa IndexNode when this is all over

function stylize_access(node, ctx::Stylize{LowerJulia}, tns::VirtualFiber)
    if !isempty(node.idxs)
        if getunbound(node.idxs[1]) ⊆ keys(ctx.ctx.bindings)
            return SelectStyle()
        elseif ctx.root isa IndexNode && ctx.root.kind === loop && ctx.root.idx == get_furl_root(node.idxs[1])
            return ChunkStyle()
        end
    end
    return DefaultStyle()
end

function select_access(node, ctx::Finch.SelectVisitor, tns::VirtualFiber)
    if !isempty(node.idxs)
        if getunbound(node.idxs[1]) ⊆ keys(ctx.ctx.bindings)
            var = index(ctx.ctx.freshen(:s))
            val = cache!(ctx.ctx, :s, node.idxs[1])
            ctx.idxs[var] = val
            ext = first(virtual_size(tns, ctx.ctx))
            ext_2 = Extent(val, val)
            tns_2 = truncate(tns, ctx.ctx, ext, ext_2)
            return access(tns_2, node.mode, var, node.idxs[2:end]...)
        end
    end
    return similarterm(node, operation(node), map(ctx, arguments(node)))
end

function chunkify_access(node, ctx, tns::VirtualFiber)
    if !isempty(node.idxs)
        if ctx.idx == get_furl_root(node.idxs[1])
            idxs = map(ctx, node.idxs)
            return access(unfurl(tns, ctx.ctx, node.mode, nothing, node.idxs...), node.mode, get_furl_root(node.idxs[1]), idxs[2:end]...)
        else
            idxs = map(ctx, node.idxs)
            return access(node.tns, node.mode, idxs...)
        end
    end
    return node
end

get_furl_root(idx) = nothing
function get_furl_root(idx::IndexNode)
    if idx.kind === index
        return idx
    elseif idx.kind === access && idx.tns.kind === virtual
        get_furl_root_access(idx, idx.tns.val)
    elseif idx.kind === protocol
        return get_furl_root(idx.idx)
    else
        return nothing
    end
end
get_furl_root_access(idx, tns) = nothing
#These are also good examples of where modifiers might be great.

refurl(tns, ctx, mode) = tns
function exfurl(tns, ctx, mode, idx::IndexNode)
    if idx.kind === index
        return tns
    elseif idx.kind === access && idx.tns.kind === virtual
        exfurl_access(tns, ctx, mode, idx, idx.tns.val)
    else
        error("unimplemented")
    end
end

function Base.show(io::IO, fbr::Fiber)
    print(io, "Fiber(")
    print(io, fbr.lvl)
    if fbr.env != Environment()
        print(io, ", ")
        print(io, fbr.env)
    end
    print(io, ")")
end

function Base.show(io::IO, mime::MIME"text/plain", fbr::Fiber)
    if get(io, :compact, false)
        print(io, "@fiber($(summary_f_code(fbr.lvl)))")
    else
        display_fiber(io, mime, fbr)
    end
end

#=
function Base.show(io::IO, fbr::VirtualFiber)
    print(io, getname(fbr))
end
function Base.show(io::IO, ext::Extent)
    print(io, ext.start)
    print(io, ":")
    print(io, ext.stop)
end
=#

function Base.show(io::IO, mime::MIME"text/plain", fbr::VirtualFiber)
    if get(io, :compact, false)
        print(io, "@virtualfiber($(summary_f_code(fbr.lvl)))")
    else
        show(io, fbr)
    end
end

function display_fiber_data(io::IO, mime::MIME"text/plain", fbr, N, crds, print_coord, get_fbr)
    (height, width) = displaysize(io)
    depth = envdepth(fbr.env)

    println(io, "│ "^(depth + N))
    if ndims(fbr) == N
        print_elem(io, crd) = show(IOContext(io, :compact=>true), get_fbr(crd))
        calc_pad(crd) = max(textwidth(sprint(print_coord, crd)), textwidth(sprint(print_elem, crd)))
        print_coord_pad(io, crd) = (print_coord(io, crd); print(io, " "^(calc_pad(crd) - textwidth(sprint(print_coord, crd)))))
        print_elem_pad(io, crd) = (print_elem(io, crd); print(io, " "^(calc_pad(crd) - textwidth(sprint(print_elem, crd)))))
        print_coords(io, crds) = (foreach(crd -> (print_coord_pad(io, crd); print(io, " ")), crds[1:end-1]); if !isempty(crds) print_coord_pad(io, crds[end]) end)
        print_elems(io, crds) = (foreach(crd -> (print_elem_pad(io, crd); print(io, " ")), crds[1:end-1]); if !isempty(crds) print_elem_pad(io, crds[end]) end)
        width -= depth * 2 + 2
        if length(crds) < width && textwidth(sprint(print_coords, crds)) < width
            print(io, "│ "^depth, "└─"^N); print_coords(io, crds); println(io)
            print(io, "│ "^depth, "  "^N); print_elems(io, crds); println(io)
        else
            leftwidth = cld(width - 1, 2)
            leftsize = searchsortedlast(cumsum(map(calc_pad, crds[1:min(end, leftwidth)]) .+ 1), leftwidth)
            leftpad = " " ^ (leftwidth - textwidth(sprint(print_coords, crds[1:leftsize])))
            rightwidth = width - leftwidth - 1
            rightsize = searchsortedlast(cumsum(map(calc_pad, reverse(crds[max(end - rightwidth, 1):end])) .+ 1), rightwidth)
            rightpad = " " ^ (rightwidth - textwidth(sprint(print_coords, crds[end-rightsize + 1:end])))
            print(io, "│ "^depth, "└─"^N); print_coords(io, crds[1:leftsize]); print(io, leftpad, " ", rightpad); print_coords(io, crds[end-rightsize + 1:end]); println(io)
            print(io, "│ "^depth, "  "^N); print_elems(io, crds[1:leftsize]); print(io, leftpad, "…", rightpad); print_elems(io, crds[end-rightsize + 1:end]); println(io)
        end
    else
        cap = 2
        if length(crds) > 2cap + 1
            foreach((crd -> (print(io, "│ " ^ depth, "├─"^N); print_coord(io, crd); println(io, ":"); show(io, mime, get_fbr(crd)); println(io, "│ "^(depth + N)))), crds[1:cap])
            
            println(io, "│ " ^ depth, "│ ⋮")
            println(io, "│ " ^ depth, "│")
            foreach((crd -> (print(io, "│ " ^ depth, "├─"^N); print_coord(io, crd); println(io, ":"); show(io, mime, get_fbr(crd)); println(io, "│ "^(depth + N)))), crds[end - cap + 1:end - 1])
            !isempty(crds) && (print(io, "│ " ^ depth, "├─"^N); print_coord(io, crds[end]); println(io, ":"); show(io, mime, get_fbr(crds[end])))
        else
            foreach((crd -> (print(io, "│ " ^ depth, "├─"^N); print_coord(io, crd); println(io, ":"); show(io, mime, get_fbr(crd)); println(io, "│ "^(depth + N)))), crds[1:end - 1])
            !isempty(crds) && (print(io, "│ " ^ depth, "├─"^N); print_coord(io, crds[end]); println(io, ":"); show(io, mime, get_fbr(crds[end])))
        end
    end
end

"""
    @fiber ctr

Construct a fiber using abbreviated level constructor names. To override
abbreviations, expressions may be interpolated with `\$`. For example,
`Fiber(DenseLevel(SparseListLevel(Element(0.0))))` can also be constructed as
`@fiber(sl(d(e(0.0))))`. Consult the documentation for the helper function
[f_code](@ref) for a full listing of level format codes.
"""
macro fiber(ex)
    function walk(ex)
        if ex isa Expr && ex.head == :$
            return esc(ex.args[1])
        elseif ex isa Expr
            return Expr(ex.head, map(walk, ex.args)...)
        elseif ex isa Symbol
            return :(@something($f_code($(Val(ex))), $(esc(ex))))
        else
            return esc(ex)
        end
    end
    return :($Fiber($(walk(ex))))
end

@inline f_code(@nospecialize ::Any) = nothing

Base.summary(fbr::Fiber) = "$(join(size(fbr), "×")) @fiber($(summary_f_code(fbr.lvl)))"

Base.similar(fbr::Fiber) = Fiber(similar_level(fbr.lvl))
Base.similar(fbr::Fiber, dims::Tuple) = Fiber(similar_level(fbr.lvl, dims...))