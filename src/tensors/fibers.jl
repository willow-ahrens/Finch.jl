abstract type AbstractFiber{Lvl} end
abstract type AbstractVirtualTensor end
abstract type AbstractVirtualFiber{Lvl} <: AbstractVirtualTensor end

"""
    Fiber(lvl)

`Fiber` represents the root of a level-tree tensor. To easily construct a valid
fiber, use [`Fiber!`](@ref) or [`fiber`](@ref). Users should avoid calling
this constructor directly.

In particular, `Fiber` represents the tensor at position 1 of `lvl`. The
constructor `Fiber(lvl)` wraps a level assuming it is already in a valid state.
The constructor `Fiber!(lvl)` first initializes `lvl` assuming no positions are
valid.
"""
struct Fiber{Lvl} <: AbstractFiber{Lvl}
    lvl::Lvl
end



mutable struct VirtualFiber{Lvl} <: AbstractVirtualFiber{Lvl}
    lvl::Lvl
end

is_injective(fiber::VirtualFiber, ctx) = is_level_injective(fiber.lvl, ctx)
is_atomic(fiber::VirtualFiber, ctx) = is_level_atomic(fiber.lvl, ctx)

function virtualize(ex, ::Type{<:Fiber{Lvl}}, ctx, tag=freshen(ctx, :tns)) where {Lvl}
    lvl = virtualize(:($ex.lvl), Lvl, ctx, Symbol(tag, :_lvl))
    VirtualFiber(lvl)
end
lower(fbr::VirtualFiber, ctx::AbstractCompiler, ::DefaultStyle) = :(Fiber($(ctx(fbr.lvl))))
FinchNotation.finch_leaf(x::VirtualFiber) = virtual(x)

"""
    SubFiber(lvl, pos)

`SubFiber` represents a fiber at position `pos` within `lvl`.
"""
struct SubFiber{Lvl, Pos} <: AbstractFiber{Lvl}
    lvl::Lvl
    pos::Pos
end

mutable struct VirtualSubFiber{Lvl} <: AbstractVirtualFiber{Lvl}
    lvl::Lvl
    pos
end
function virtualize(ex, ::Type{<:SubFiber{Lvl, Pos}}, ctx, tag=freshen(ctx, :tns)) where {Lvl, Pos}
    lvl = virtualize(:($ex.lvl), Lvl, ctx, Symbol(tag, :_lvl))
    pos = virtualize(:($ex.pos), Pos, ctx)
    VirtualSubFiber(lvl, pos)
end
lower(fbr::VirtualSubFiber, ctx::AbstractCompiler, ::DefaultStyle) = :(SubFiber($(ctx(fbr.lvl)), $(ctx(fbr.pos))))
FinchNotation.finch_leaf(x::VirtualSubFiber) = virtual(x)

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
    tns
end
virtual_eltype(tns::AbstractVirtualFiber, ctx) = virtual_level_eltype(tns.lvl)
virtual_default(tns::AbstractVirtualFiber, ctx) = virtual_level_default(tns.lvl)
postype(fbr::AbstractVirtualFiber) = postype(fbr.lvl)
allocator(fbr::AbstractVirtualFiber) = allocator(fbr.lvl)


function declare!(fbr::VirtualFiber, ctx::AbstractCompiler, init)
    lvl = declare_level!(fbr.lvl, ctx, literal(1), init)
    push!(ctx.code.preamble, assemble_level!(lvl, ctx, literal(1), literal(1))) #TODO this feels unnecessary?
    fbr = VirtualFiber(lvl)
end

function instantiate_reader(fbr::VirtualFiber, ctx::AbstractCompiler, protos)
    return Unfurled(fbr, instantiate_reader(VirtualSubFiber(fbr.lvl, literal(1)), ctx, protos))
end

function instantiate_updater(fbr::VirtualFiber, ctx::AbstractCompiler, protos)
    return Unfurled(fbr, instantiate_updater(VirtualSubFiber(fbr.lvl, literal(1)), ctx, protos))
end

function virtual_moveto(fbr::VirtualFiber, ctx::AbstractCompiler, arch)
    return VirtualFiber(virtual_moveto_level(fbr.lvl, ctx, arch))
end

function virtual_moveto(fbr::VirtualSubFiber, ctx::AbstractCompiler, arch)
    return VirtualTrackedSubFiber(virtual_moveto_level(fbr.lvl, ctx, arch), fbr.pos)
end

struct TrackedSubFiber{Lvl, Pos, Dirty} <: AbstractFiber{Lvl}
    lvl::Lvl
    pos::Pos
    dirty::Dirty
end

mutable struct VirtualTrackedSubFiber{Lvl}
    lvl::Lvl
    pos
    dirty
end
function virtualize(ex, ::Type{<:TrackedSubFiber{Lvl, Pos, Dirty}}, ctx, tag=freshen(ctx, :tns)) where {Lvl, Pos, Dirty}
    lvl = virtualize(:($ex.lvl), Lvl, ctx, Symbol(tag, :_lvl))
    pos = virtualize(:($ex.pos), Pos, ctx)
    dirty = virtualize(:($ex.dirty), Dirty, ctx)
    VirtualTrackedSubFiber(lvl, pos, dirty)
end
lower(fbr::VirtualTrackedSubFiber, ctx::AbstractCompiler, ::DefaultStyle) = :(TrackedSubFiber($(ctx(fbr.lvl)), $(ctx(fbr.pos))))
FinchNotation.finch_leaf(x::VirtualTrackedSubFiber) = virtual(x)

function virtual_moveto(fbr::VirtualTrackedSubFiber, ctx::AbstractCompiler, arch)
    return VirtualTrackedSubFiber(virtual_moveto_level(fbr.lvl, ctx, arch), fbr.pos, fbr.dirty)
end

"""
    redefault!(fbr, init)

Return a fiber which is equal to `fbr`, but with the default (implicit) value
set to `init`.  May reuse memory and render the original fiber unusable when
modified.

```jldoctest
julia> A = Fiber!(SparseList(Element(0.0), 10), [2.0, 0.0, 3.0, 0.0, 4.0, 0.0, 5.0, 0.0, 6.0, 0.0])
SparseList (0.0) [1:10]
├─[1]: 2.0
├─[3]: 3.0
├─[5]: 4.0
├─[7]: 5.0
├─[9]: 6.0

julia> redefault!(A, Inf)
SparseList (Inf) [1:10]
├─[1]: 2.0
├─[3]: 3.0
├─[5]: 4.0
├─[7]: 5.0
├─[9]: 6.0
```
"""
redefault!(fbr::Fiber, init) = Fiber(redefault!(fbr.lvl, init))
redefault!(fbr::SubFiber, init) = SubFiber(redefault!(fbr.lvl, init), fbr.pos)

data_rep(fbr::Fiber) = data_rep(typeof(fbr))
data_rep(::Type{<:AbstractFiber{Lvl}}) where {Lvl} = data_rep_level(Lvl)

function freeze!(fbr::VirtualFiber, ctx::AbstractCompiler)
    return VirtualFiber(freeze_level!(fbr.lvl, ctx, literal(1)))
end

thaw_level!(lvl, ctx, pos) = throw(FinchProtocolError("cannot modify $(typeof(lvl)) in place (forgot to declare with .= ?)"))
function thaw!(fbr::VirtualFiber, ctx::AbstractCompiler)
    return VirtualFiber(thaw_level!(fbr.lvl, ctx, literal(1)))
end

function trim!(fbr::VirtualFiber, ctx)
    VirtualFiber(trim_level!(fbr.lvl, ctx, literal(1)))
end

supports_reassembly(lvl) = false

function Base.show(io::IO, fbr::Fiber)
    print(io, "Fiber(", fbr.lvl, ")")
end

function Base.show(io::IO, mime::MIME"text/plain", fbr::Fiber)
    if get(io, :compact, false)
        print(io, "Fiber!($(summary(fbr.lvl)))")
    else
        display_fiber(io, mime, fbr, 0)
    end
end

function Base.show(io::IO, mime::MIME"text/plain", fbr::VirtualFiber)
    if get(io, :compact, false)
        print(io, "VirtualFiber($(summary(fbr.lvl)))")
    else
        show(io, fbr)
    end
end

function Base.show(io::IO, fbr::SubFiber)
    print(io, "SubFiber(", fbr.lvl, ", ", fbr.pos, ")")
end

function Base.show(io::IO, mime::MIME"text/plain", fbr::SubFiber)
    if get(io, :compact, false)
        print(io, "SubFiber($(summary(fbr.lvl)), $(fbr.pos))")
    else
        display_fiber(io, mime, fbr, 0)
    end
end

function Base.show(io::IO, mime::MIME"text/plain", fbr::VirtualSubFiber)
    if get(io, :compact, false)
        print(io, "VirtualSubFiber($(summary(fbr.lvl)))")
    else
        show(io, fbr)
    end
end

(fbr::Fiber)(idx...) = SubFiber(fbr.lvl, 1)(idx...)

display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber, depth) = display_fiber(io, mime, SubFiber(fbr.lvl, 1), depth)
function display_fiber_data(io::IO, mime::MIME"text/plain", fbr, depth, N, crds, print_coord, get_fbr)
    function helper(crd)
        println(io)
        print(io, "│ " ^ depth, "├─"^N, "[", ":,"^(ndims(fbr) - N))
        print_coord(io, crd)
        print(io, "]: ")
        display_fiber(io, mime, get_fbr(crd), depth + N)
    end
    cap = 2
    if length(crds) > 2cap + 1
        foreach(helper, crds[1:cap])
        println(io)
        print(io, "│ " ^ depth, "│ ⋮")
        foreach(helper, crds[end - cap + 1:end])
    else
        foreach(helper, crds)
    end
end
display_fiber(io::IO, mime::MIME"text/plain", fbr, depth) = show(io, mime, fbr) #TODO get rid of this eventually

"""
    countstored(arr)

Return the number of stored elements in `arr`. If there are explicitly stored
default elements, they are counted too.

See also: (`nnz`)(https://docs.julialang.org/en/v1/stdlib/SparseArrays/#SparseArrays.nnz)
"""
countstored(fbr::Fiber) = countstored_level(fbr.lvl, 1)

countstored(arr::Array) = length(arr)


"""
    Fiber!(ctr, [arg])

Construct a fiber from a nest of levels. This function may allocate memory.
Optionally, an argument may be specified to copy into the fiber. This expression
allocates. Use `fiber(arg)` for a zero-cost copy, if available.
"""
function Fiber! end

@staged function Fiber!(lvl)
    contain(LowerJulia()) do ctx
        lvl = virtualize(:lvl, lvl, ctx.code)
        lvl = declare_level!(lvl, ctx, literal(0), literal(virtual_level_default(lvl)))
        push!(ctx.code.preamble, assemble_level!(lvl, ctx, literal(1), literal(1)))
        lvl = freeze_level!(lvl, ctx, literal(1))
        :(Fiber($(ctx(lvl))))
    end
end

function Fiber!(lvl, arg)
    dropdefaults!(Fiber!(lvl), arg)
end

Base.summary(fbr::Fiber) = "$(join(size(fbr), "×")) Fiber!($(summary(fbr.lvl)))"
Base.summary(fbr::SubFiber) = "$(join(size(fbr), "×")) SubFiber($(summary(fbr.lvl)))"

Base.similar(fbr::AbstractFiber) = Fiber(similar_level(fbr.lvl))
Base.similar(fbr::AbstractFiber, dims::Tuple) = Fiber(similar_level(fbr.lvl, dims...))

"""
    moveto(fbr, device)

If the fiber/level is not on the given device, it creates a new version of this fiber on that memory type
and copies the data in to it, according to the `device`.
"""
moveto(fiber::Fiber, device) = Fiber(moveto(fiber.lvl, device))