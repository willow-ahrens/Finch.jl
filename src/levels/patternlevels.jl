"""
    PatternLevel{D, [Tv]}()

A subfiber of a pattern level is the Boolean value true, but it's `default` is
false. PatternLevels are used to create tensors that represent which values
are stored by other fibers. See [`pattern`](@ref) for usage examples.

In the [@fiber](@ref) constructor, `p` is an alias for `ElementLevel`.

```jldoctest
julia> @fiber(d(p(), 3))
Dense [1:3]
├─[1]: true
├─[2]: true
├─[3]: true
```
"""
struct PatternLevel end
const Pattern = PatternLevel

"""
`f_code(p)` = [PatternLevel](@ref).
"""
f_code(::Val{:p}) = Pattern
summary_f_code(::Pattern) = "p()"
similar_level(::PatternLevel) = PatternLevel()

countstored_level(lvl::PatternLevel, pos) = pos

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:PatternLevel}, depth)
    show(io, mime, true)
end

pattern!(::PatternLevel) = Pattern()

function Base.show(io::IO, lvl::PatternLevel)
    print(io, "Pattern()")
end 

@inline level_ndims(::Type{PatternLevel}) = 0
@inline level_size(::PatternLevel) = ()
@inline level_axes(::PatternLevel) = ()
@inline level_eltype(::Type{PatternLevel}) = Bool
@inline level_default(::Type{PatternLevel}) = false
(fbr::AbstractFiber{<:PatternLevel})() = true
data_rep_level(::Type{<:PatternLevel}) = ElementData(false, Bool)

"""
    pattern!(fbr)

Return the pattern of `fbr`. That is, return a fiber which is true wherever
`fbr` is structurally unequal to it's default. May reuse memory and render the
original fiber unusable when modified.

```jldoctest
julia> A = @fiber(sl(e(0.0), 10), [2.0, 0.0, 3.0, 0.0, 4.0, 0.0, 5.0, 0.0, 6.0, 0.0])
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

struct VirtualPatternLevel end

(ctx::Finch.LowerJulia)(lvl::VirtualPatternLevel) = :(PatternLevel())
virtualize(ex, ::Type{<:PatternLevel}, ctx) = VirtualPatternLevel()

virtual_level_resize!(lvl::VirtualPatternLevel, ctx) = lvl
virtual_level_size(::VirtualPatternLevel, ctx) = ()
virtual_level_default(::VirtualPatternLevel) = false
virtual_level_eltype(::VirtualPatternLevel) = Bool

function declare_level!(lvl::VirtualPatternLevel, ctx, pos, init)
    init == literal(false) || throw(FormatLimitation("Must initialize Pattern Levels to false"))
    lvl
end

freeze_level!(lvl::VirtualPatternLevel, ctx, pos) = lvl

thaw_level!(lvl::VirtualPatternLevel, ctx, pos) = lvl

assemble_level!(lvl::VirtualPatternLevel, ctx, pos_start, pos_stop) = quote end
reassemble_level!(lvl::VirtualPatternLevel, ctx, pos_start, pos_stop) = quote end

trim_level!(lvl::VirtualPatternLevel, ctx::LowerJulia, pos) = lvl

get_reader(::VirtualSubFiber{VirtualPatternLevel}, ctx) = Fill(true)
is_laminable_updater(lvl::VirtualPatternLevel, ctx) = true

function get_updater(fbr::VirtualSubFiber{VirtualPatternLevel}, ctx)
    val = ctx.freshen(:null)
    push!(ctx.preamble, :($val = false))
    VirtualScalar(nothing, Bool, false, gensym(), val)
end

function get_updater(fbr::VirtualTrackedSubFiber{VirtualPatternLevel}, ctx)
    VirtualScalar(nothing, Bool, false, gensym(), fbr.dirty)
end

function lowerjulia_access(ctx::LowerJulia, node, tns::VirtualFiber{VirtualPatternLevel})
    val = ctx.freshen(:null)
    push!(ctx.preamble, :($val = false))
    val
end