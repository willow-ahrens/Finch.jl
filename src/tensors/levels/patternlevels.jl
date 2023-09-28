"""
    PatternLevel{[Tp, V]}()

A subfiber of a pattern level is the Boolean value true, but it's `default` is
false. PatternLevels are used to create tensors that represent which values
are stored by other fibers. See [`pattern`](@ref) for usage examples.

```jldoctest
julia> Fiber!(Dense(Pattern(), 3))
Dense [1:3]
├─[1]: true
├─[2]: true
├─[3]: true
```
"""
struct PatternLevel{Tp, V} end
const Pattern = PatternLevel

PatternLevel() = PatternLevel{Int, Vector{Bool}}()

Base.summary(::Pattern) = "Pattern()"
similar_level(::PatternLevel) = PatternLevel()

countstored_level(lvl::PatternLevel, pos) = pos

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:PatternLevel}, depth)
    show(io, mime, true)
end

pattern!(::PatternLevel{Tp, V}) where {Tp, V} = Pattern{Tp, V}()

function Base.show(io::IO, lvl::PatternLevel)
    print(io, "Pattern()")
end 

@inline level_ndims(::Type{<:PatternLevel}) = 0
@inline level_size(::PatternLevel) = ()
@inline level_axes(::PatternLevel) = ()
@inline level_eltype(::Type{<:PatternLevel}) = Bool
@inline level_default(::Type{<:PatternLevel}) = false
(fbr::AbstractFiber{<:PatternLevel})() = true
data_rep_level(::Type{<:PatternLevel}) = ElementData(false, Bool)

postype(::Type{<:PatternLevel{Tp}}) where {Tp} = Tp

function moveto(lvl::PatternLevel{Tp}, device) where {Tp}
    return PatternLevel{Tp}()
end


"""
    pattern!(fbr)

Return the pattern of `fbr`. That is, return a fiber which is true wherever
`fbr` is structurally unequal to it's default. May reuse memory and render the
original fiber unusable when modified.

```jldoctest
julia> A = Fiber!(SparseList(Element(0.0), 10), [2.0, 0.0, 3.0, 0.0, 4.0, 0.0, 5.0, 0.0, 6.0, 0.0])
SparseList (0.0) [1:10]
├─[1]: 2.0
├─[3]: 3.0
├─[5]: 4.0
├─[7]: 5.0
├─[9]: 6.0

julia> pattern!(A)
SparseList (false) [1:10]
├─[1]: true
├─[3]: true
├─[5]: true
├─[7]: true
├─[9]: true
```
"""
pattern!(fbr::Fiber) = Fiber(pattern!(fbr.lvl))
pattern!(fbr::SubFiber) = SubFiber(pattern!(fbr.lvl), fbr.pos)

struct VirtualPatternLevel <: AbstractVirtualLevel end

is_level_injective(::VirtualPatternLevel, ctx) = []
is_level_atomic(lvl::VirtualPatternLevel, ctx) = true

lower(lvl::VirtualPatternLevel, ctx::AbstractCompiler, ::DefaultStyle) = :(PatternLevel())
virtualize(ex, ::Type{<:PatternLevel}, ctx) = VirtualPatternLevel()

virtual_level_resize!(lvl::VirtualPatternLevel, ctx) = lvl
virtual_level_size(::VirtualPatternLevel, ctx) = ()
virtual_level_default(::VirtualPatternLevel) = false
virtual_level_eltype(::VirtualPatternLevel) = Bool

function declare_level!(lvl::VirtualPatternLevel, ctx, pos, init)
    init == literal(false) || throw(FinchProtocolError("Must initialize Pattern Levels to false"))
    lvl
end

freeze_level!(lvl::VirtualPatternLevel, ctx, pos) = lvl

thaw_level!(lvl::VirtualPatternLevel, ctx, pos) = lvl

assemble_level!(lvl::VirtualPatternLevel, ctx, pos_start, pos_stop) = quote end
reassemble_level!(lvl::VirtualPatternLevel, ctx, pos_start, pos_stop) = quote end

trim_level!(lvl::VirtualPatternLevel, ctx::AbstractCompiler, pos) = lvl

instantiate_reader(::VirtualSubFiber{VirtualPatternLevel}, ctx, protos) = Fill(true)

function instantiate_updater(fbr::VirtualSubFiber{VirtualPatternLevel}, ctx, protos)
    val = freshen(ctx.code, :null)
    push!(ctx.code.preamble, :($val = false))
    VirtualScalar(nothing, Bool, false, gensym(), val)
end

function instantiate_updater(fbr::VirtualTrackedSubFiber{VirtualPatternLevel}, ctx, protos)
    VirtualScalar(nothing, Bool, false, gensym(), fbr.dirty)
end

function lower_access(ctx::AbstractCompiler, node, tns::VirtualFiber{VirtualPatternLevel})
    val = freshen(ctx.code, :null)
    push!(ctx.code.preamble, :($val = false))
    val
end
