abstract type AbstractFiber{Lvl, T, N} <: AbstractArray{T, N} end
abstract type AbstractVirtualTensor end
abstract type AbstractVirtualFiber{Lvl} <: AbstractVirtualTensor end

"""
    Tensor{Lvl, [T=level_eltype(Lvl)], [N=level_eldims(Lvl)]} <: AbstractFiber{Lvl, T, N}

The multidimensional array type used by `Finch`. `Tensor` is a thin wrapper
around the hierarchical level storage of type `Lvl`.
"""
struct Tensor{Lvl, T, N} <: AbstractFiber{Lvl, T, N}
    lvl::Lvl
end

"""
    Tensor(lvl)

Construct a `Tensor` using the tensor level storage `lvl`. No initialization of
storage is performed, it is assumed that position 1 of `lvl` corresponds to a
valid tensor, and `lvl` will be wrapped as-is. Call a different constructor to
initialize the storage.
"""
Tensor(lvl::Lvl) where {Lvl<:AbstractLevel} = Tensor{Lvl, level_eltype(Lvl), level_ndims(Lvl)}(lvl)

"""
    Tensor(lvl, [undef], dims...)

Construct a `Tensor` of size `dims`, and initialize to `undef`, potentially
allocating memory.  Here `undef` is the `UndefInitializer` singleton type.
`dims...` may be a variable number of dimensions or a tuple of dimensions, but
it must correspond to the number of dimensions in `lvl`.
"""
Tensor(lvl::AbstractLevel, dims::Number...) = Tensor(lvl, undef, dims...)
Tensor(lvl::AbstractLevel, dims::Tuple) = Tensor(lvl, undef, dims...)
Tensor(lvl::AbstractLevel, init::UndefInitializer, dims...) = Tensor(assemble!(resize!(lvl, dims...)))
Tensor(lvl::AbstractLevel, init::UndefInitializer, dims::Tuple) = Tensor(assemble!(resize!(lvl, dims...)))
Tensor(lvl::AbstractLevel, init::UndefInitializer) = Tensor(assemble!(lvl))
"""
    Tensor(lvl, arr)

Construct a `Tensor` and initialize it to the contents of `arr`.
To explicitly copy into a tensor,
use @ref[`copyto!`]
"""
Tensor(lvl::AbstractLevel, arr) = dropdefaults!(Tensor(lvl), arr)

"""
    Tensor(arr, [init = zero(eltype(arr))])

Copy an array-like object `arr` into a corresponding, similar `Tensor`
datastructure. Uses `init` as an initial value. May reuse memory when possible.
To explicitly copy into a tensor, use @ref[`copyto!`].

# Examples

```jldoctest
julia> println(summary(Tensor(sparse([1 0; 0 1]))))
2×2 Tensor(Dense(SparseList(Element(0))))

julia> println(summary(Tensor(ones(3, 2, 4))))
3×2×4 Tensor(Dense(Dense(Dense(Element(0.0)))))
```
"""
function Tensor(arr::AbstractArray{Tv, N}, default::Tv=zero(eltype(arr))) where {Tv, N}
    Base.copyto!(Tensor((DenseLevel^(ndims(arr)))(Element{zero(eltype(arr))}())), arr)
end

mutable struct VirtualFiber{Lvl} <: AbstractVirtualFiber{Lvl}
    lvl::Lvl
end

is_injective(tns::VirtualFiber, ctx) = is_level_injective(tns.lvl, ctx)
is_atomic(tns::VirtualFiber, ctx) = is_level_atomic(tns.lvl, ctx)

function virtualize(ex, ::Type{<:Tensor{Lvl}}, ctx, tag=freshen(ctx, :tns)) where {Lvl}
    lvl = virtualize(:($ex.lvl), Lvl, ctx, Symbol(tag, :_lvl))
    VirtualFiber(lvl)
end
lower(fbr::VirtualFiber, ctx::AbstractCompiler, ::DefaultStyle) = :(Tensor($(ctx(fbr.lvl))))
FinchNotation.finch_leaf(x::VirtualFiber) = virtual(x)

"""
    SubFiber(lvl, pos)

`SubFiber` represents a tensor at position `pos` within `lvl`.
"""
struct SubFiber{Lvl, Pos, T, N} <: AbstractFiber{Lvl, T, N}
    lvl::Lvl
    pos::Pos
end

SubFiber(lvl::Lvl, pos::Pos) where {Lvl, Pos} = SubFiber{Lvl, Pos, level_eltype(Lvl), level_ndims(Lvl)}(lvl, pos)

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

function instantiate(fbr::VirtualFiber, ctx::AbstractCompiler, mode, protos)
    return Unfurled(fbr, instantiate(VirtualSubFiber(fbr.lvl, literal(1)), ctx, mode, protos))
end

function virtual_moveto(fbr::VirtualFiber, ctx::AbstractCompiler, arch)
    virtual_moveto_level(fbr.lvl, ctx, arch)
end

function virtual_moveto(fbr::VirtualSubFiber, ctx::AbstractCompiler, arch)
    virtual_moveto_level(fbr.lvl, ctx, arch)
end

struct HollowSubFiber{Lvl, Pos, Dirty, T, N} <: AbstractFiber{Lvl, T, N}
    lvl::Lvl
    pos::Pos
    dirty::Dirty
end

HollowSubFiber(lvl::Lvl, pos::Pos, dirty::Dirty) where {Lvl, Pos, Dirty} = HollowSubFiber{Lvl, Pos, Dirty, level_eltype(Lvl), level_ndims(Lvl)}(lvl, pos, dirty)

mutable struct VirtualHollowSubFiber{Lvl}
    lvl::Lvl
    pos
    dirty
end
function virtualize(ex, ::Type{<:HollowSubFiber{Lvl, Pos, Dirty}}, ctx, tag=freshen(ctx, :tns)) where {Lvl, Pos, Dirty}
    lvl = virtualize(:($ex.lvl), Lvl, ctx, Symbol(tag, :_lvl))
    pos = virtualize(:($ex.pos), Pos, ctx)
    dirty = virtualize(:($ex.dirty), Dirty, ctx)
    VirtualHollowSubFiber(lvl, pos, dirty)
end
lower(fbr::VirtualHollowSubFiber, ctx::AbstractCompiler, ::DefaultStyle) = :(HollowSubFiber($(ctx(fbr.lvl)), $(ctx(fbr.pos))))
FinchNotation.finch_leaf(x::VirtualHollowSubFiber) = virtual(x)

function virtual_moveto(fbr::VirtualHollowSubFiber, ctx::AbstractCompiler, arch)
    return VirtualHollowSubFiber(virtual_moveto_level(fbr.lvl, ctx, arch), fbr.pos, fbr.dirty)
end

"""
    redefault!(fbr, init)

Return a tensor which is equal to `fbr`, but with the default (implicit) value
set to `init`.  May reuse memory and render the original tensor unusable when
modified.

```jldoctest
julia> A = Tensor(SparseList(Element(0.0), 10), [2.0, 0.0, 3.0, 0.0, 4.0, 0.0, 5.0, 0.0, 6.0, 0.0])
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
redefault!(fbr::Tensor, init) = Tensor(redefault!(fbr.lvl, init))

"""
    resize!(fbr, dims...)

Set the shape of `fbr` equal to `dims`. May reuse memory and render the original
tensor unusable when modified.
"""
Base.resize!(fbr::Tensor, dims...) = Tensor(resize!(fbr.lvl, dims...))

data_rep(fbr::Tensor) = data_rep(typeof(fbr))
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

function Base.show(io::IO, fbr::Tensor)
    print(io, "Tensor(", fbr.lvl, ")")
end

function Base.show(io::IO, mime::MIME"text/plain", fbr::Tensor)
    if get(io, :compact, false)
        print(io, "Tensor($(summary(fbr.lvl)))")
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

(fbr::Tensor)(idx...) = SubFiber(fbr.lvl, 1)(idx...)

display_fiber(io::IO, mime::MIME"text/plain", fbr::Tensor, depth) = display_fiber(io, mime, SubFiber(fbr.lvl, 1), depth)
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
countstored(fbr::Tensor) = countstored_level(fbr.lvl, 1)

countstored(arr::Array) = length(arr)



@staged function assemble!(lvl)
    contain(LowerJulia()) do ctx
        lvl = virtualize(:lvl, lvl, ctx.code)
        def = literal(virtual_level_default(lvl))
        lvl = declare_level!(lvl, ctx, literal(0), def)
        push!(ctx.code.preamble, assemble_level!(lvl, ctx, literal(1), literal(1)))
        lvl = freeze_level!(lvl, ctx, literal(1))
        ctx(lvl)
    end
end

Base.summary(fbr::Tensor) = "$(join(size(fbr), "×")) Tensor($(summary(fbr.lvl)))"
Base.summary(fbr::SubFiber) = "$(join(size(fbr), "×")) SubFiber($(summary(fbr.lvl)))"

Base.similar(fbr::AbstractFiber) = Tensor(similar_level(fbr.lvl))
Base.similar(fbr::AbstractFiber, dims::Tuple) = Tensor(similar_level(fbr.lvl, dims...))

moveto(tns::Tensor, device) = Tensor(moveto(tns.lvl, device))