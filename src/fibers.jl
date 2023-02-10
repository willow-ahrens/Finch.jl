abstract type AbstractFiber{Lvl} end
abstract type AbstractVirtualFiber{Lvl} end

struct Fiber{Lvl} <: AbstractFiber{Lvl}
    lvl::Lvl
end

mutable struct VirtualFiber{Lvl} <: AbstractVirtualFiber{Lvl}
    lvl::Lvl
end
function virtualize(ex, ::Type{<:Fiber{Lvl}}, ctx, tag=ctx.freshen(:tns)) where {Lvl}
    lvl = virtualize(:($ex.lvl), Lvl, ctx, Symbol(tag, :_lvl))
    VirtualFiber(lvl)
end
(ctx::Finch.LowerJulia)(fbr::VirtualFiber) = :(Fiber($(ctx(fbr.lvl))))
IndexNotation.isliteral(::VirtualFiber) = false

struct SubFiber{Lvl, Pos} <: AbstractFiber{Lvl}
    lvl::Lvl
    pos::Pos
end

mutable struct VirtualSubFiber{Lvl}
    lvl::Lvl
    pos
end
function virtualize(ex, ::Type{<:SubFiber{Lvl, Pos}}, ctx, tag=ctx.freshen(:tns)) where {Lvl, Pos}
    lvl = virtualize(:($ex.lvl), Lvl, ctx, Symbol(tag, :_lvl))
    pos = virtualize(:($ex.pos), Pos, ctx)
    VirtualFiber(lvl, pos)
end
(ctx::Finch.LowerJulia)(fbr::VirtualSubFiber) = :(Fiber($(ctx(fbr.lvl)), $(ctx(fbr.pos))))
IndexNotation.isliteral(::VirtualSubFiber) =  false

@inline Base.ndims(::AbstractFiber{Lvl}) where {Lvl} = level_ndims(Lvl)
@inline Base.ndims(::Type{<:AbstractFiber{Lvl}}) where {Lvl} = level_ndims(Lvl)
@inline Base.size(fbr::AbstractFiber) = level_size(fbr.lvl)
@inline Base.axes(fbr::AbstractFiber) = level_axes(fbr.lvl)
@inline Base.eltype(::AbstractFiber{Lvl}) where {Lvl} = level_eltype(Lvl)
@inline Base.eltype(::Type{<:AbstractFiber{Lvl}}) where {Lvl} = level_eltype(Lvl)
@inline default(::AbstractFiber{Lvl}) where {Lvl} = level_default(Lvl)
@inline default(::Type{<:AbstractFiber{Lvl}}) where {Lvl} = level_default(Lvl)

virtual_size(tns::AbstractVirtualFiber, ctx) = virtual_level_size(tns.lvl, ctx)
function virtual_resize!(tns::AbstractVirtualFiber, ctx, dims...)
    tns.lvl = virtual_level_resize!(tns.lvl, ctx, dims...)
    (tns, nodim)
end
virtual_eltype(tns::AbstractVirtualFiber) = virtual_level_eltype(tns.lvl)
virtual_elaxis(tns::AbstractVirtualFiber) = nodim
virtual_default(tns::AbstractVirtualFiber) = virtual_level_default(tns.lvl)

"""
    default(fbr)

The default for a fiber is the value that each element of the fiber will have
after initialization. This value is most often zero, and defaults to nothing.

See also: [`initialize!`](@ref)
"""
function default end

"""
    initialize!(fbr, ctx)

Initialize the virtual fiber to it's default value in the context `ctx`. Return the new fiber object.
"""
function initialize!(fbr::VirtualFiber, ctx::LowerJulia)
    lvl = initialize_level!(fbr.lvl, ctx, literal(1))
    push!(ctx.preamble, assemble_level!(lvl, ctx, literal(1), literal(1))) #TODO this feels unnecessary?
    fbr = VirtualFiber(lvl)
end

function get_reader(fbr::VirtualFiber, ctx::LowerJulia, protos...)
    return get_level_reader(fbr.lvl, ctx, literal(1), protos...)
end

function get_updater(fbr::VirtualFiber, ctx::LowerJulia, protos...)
    return get_level_updater(fbr.lvl, ctx, literal(1), protos...)
end

"""
    initialize_level!(fbr, ctx, pos)

Initialize the level within the virtual fiber to it's default value in the
context `ctx` with access mode `mode`. Return the new level.
"""
function initialize_level! end

data_rep(fbr::Fiber) = data_rep(typeof(fbr))
data_rep(::Type{<:AbstractFiber{Lvl}}) where {Lvl} = SolidData(data_rep_level(Lvl))

"""
    freeze!(fbr, ctx, mode, idxs...)

Freeze the virtual fiber in the context `ctx` with access mode `mode`. Return
the new fiber object.
"""
function freeze!(fbr::VirtualFiber, ctx::LowerJulia, mode, idxs...)
    if mode.kind === updater
        return VirtualFiber(freeze_level!(fbr.lvl, ctx, literal(1)))
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
    VirtualFiber(trim_level!(fbr.lvl, ctx, literal(1)))
end
trim!(fbr, ctx) = fbr

#TODO get rid of these when we redo unfurling
set_clean!(lvl, ctx) = quote end
get_dirty(lvl, ctx) = true

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

supports_reassembly(lvl) = false

function Base.show(io::IO, fbr::Fiber)
    print(io, "Fiber(", fbr.lvl, ")")
end

function Base.show(io::IO, mime::MIME"text/plain", fbr::Fiber)
    if get(io, :compact, false)
        print(io, "@fiber($(summary_f_code(fbr.lvl)))")
    else
        display_fiber(io, mime, fbr, 0)
    end
end

function Base.show(io::IO, mime::MIME"text/plain", fbr::VirtualFiber)
    if get(io, :compact, false)
        print(io, "VirtualFiber($(summary_f_code(fbr.lvl)))")
    else
        show(io, fbr)
    end
end

function Base.show(io::IO, fbr::SubFiber)
    print(io, "SubFiber(", fbr.lvl, ", ", fbr.pos, ")")
end

function Base.show(io::IO, mime::MIME"text/plain", fbr::SubFiber)
    if get(io, :compact, false)
        print(io, "SubFiber($(summary_f_code(fbr.lvl)), $(fbr.pos))")
    else
        display_fiber(io, mime, fbr, 0)
    end
end

function Base.show(io::IO, mime::MIME"text/plain", fbr::VirtualSubFiber)
    if get(io, :compact, false)
        print(io, "VirtualSubFiber($(summary_f_code(fbr.lvl)))")
    else
        show(io, fbr)
    end
end

(fbr::Fiber)(idx...) = SubFiber(fbr.lvl, 1)(idx...)

display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber, depth) = display_fiber(io, mime, SubFiber(fbr.lvl, 1), depth)
function display_fiber_data(io::IO, mime::MIME"text/plain", fbr, depth, N, crds, print_coord, get_fbr)
    (height, width) = displaysize(io)

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
            foreach((crd -> (print(io, "│ " ^ depth, "├─"^N); print_coord(io, crd); println(io, ":"); display_fiber(io, mime, get_fbr(crd), depth + N); println(io, "│ "^(depth + N)))), crds[1:cap])
            
            println(io, "│ " ^ depth, "│ ⋮")
            println(io, "│ " ^ depth, "│")
            foreach((crd -> (print(io, "│ " ^ depth, "├─"^N); print_coord(io, crd); println(io, ":"); display_fiber(io, mime, get_fbr(crd), depth + N); println(io, "│ "^(depth + N)))), crds[end - cap + 1:end - 1])
            !isempty(crds) && (print(io, "│ " ^ depth, "├─"^N); print_coord(io, crds[end]); println(io, ":"); display_fiber(io, mime, get_fbr(crds[end]), depth + N))
        else
            foreach((crd -> (print(io, "│ " ^ depth, "├─"^N); print_coord(io, crd); println(io, ":"); display_fiber(io, mime, get_fbr(crd), depth + N); println(io, "│ "^(depth + N)))), crds[1:end - 1])
            !isempty(crds) && (print(io, "│ " ^ depth, "├─"^N); print_coord(io, crds[end]); println(io, ":"); display_fiber(io, mime, get_fbr(crds[end]), depth + N))
        end
    end
end

function f_decode(ex)
    if ex isa Expr && ex.head == :$
        return esc(ex.args[1])
    elseif ex isa Expr
        return Expr(ex.head, map(f_decode, ex.args)...)
    elseif ex isa Symbol
        return :(@something($f_code($(Val(ex))), $(esc(ex))))
    else
        return esc(ex)
    end
end

"""
    @fiber ctr [arg]

Construct a fiber using abbreviated level constructor names. To override
abbreviations, expressions may be interpolated with `\$`. For example,
`Fiber(DenseLevel(SparseListLevel(Element(0.0))))` can also be constructed as
`@fiber(sl(d(e(0.0))))`. Consult the documentation for the helper function
[f_code](@ref) for a full listing of level format codes.

Optionally, an argument may be specified to copy into the fiber. This expression
allocates. Use `fiber(arg)` for a zero-cost copy, if available.
"""
macro fiber(ex)
    return :($Fiber!($(f_decode(ex))))
end

macro fiber(ex, arg)
    return :($dropdefaults!($Fiber!($(f_decode(ex))), arg))
end

@inline f_code(@nospecialize ::Any) = nothing

Base.summary(fbr::Fiber) = "$(join(size(fbr), "×")) @fiber($(summary_f_code(fbr.lvl)))"
Base.summary(fbr::SubFiber) = "$(join(size(fbr), "×")) SubFiber($(summary_f_code(fbr.lvl)))"

Base.similar(fbr::AbstractFiber) = Fiber(similar_level(fbr.lvl))
Base.similar(fbr::AbstractFiber, dims::Tuple) = Fiber(similar_level(fbr.lvl, dims...))