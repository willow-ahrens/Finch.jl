"""
    PatternLevel{[Tp=Int]}()

A subfiber of a pattern level is the Boolean value true, but it's `fill_value` is
false. PatternLevels are used to create tensors that represent which values
are stored by other fibers. See [`pattern!`](@ref) for usage examples.

```jldoctest
julia> Tensor(Dense(Pattern()), 3)
3-Tensor
└─ Dense [1:3]
   ├─ [1]: true
   ├─ [2]: true
   └─ [3]: true
```
"""
struct PatternLevel{Tp} <: AbstractLevel end
const Pattern = PatternLevel

PatternLevel() = PatternLevel{Int}()

Base.summary(::Pattern) = "Pattern()"
similar_level(::PatternLevel, ::Any, ::Type, ::Vararg) = PatternLevel()

countstored_level(lvl::PatternLevel, pos) = pos

labelled_show(io::IO, ::SubFiber{<:PatternLevel}) =
    print(io, true)

Base.resize!(lvl::PatternLevel) = lvl

pattern!(::PatternLevel{Tp}) where {Tp} = Pattern{Tp}()

function Base.show(io::IO, lvl::PatternLevel)
    print(io, "Pattern()")
end 

@inline level_ndims(::Type{<:PatternLevel}) = 0
@inline level_size(::PatternLevel) = ()
@inline level_axes(::PatternLevel) = ()
@inline level_eltype(::Type{<:PatternLevel}) = Bool
@inline level_fill_value(::Type{<:PatternLevel}) = false
(fbr::AbstractFiber{<:PatternLevel})() = true
data_rep_level(::Type{<:PatternLevel}) = ElementData(false, Bool)

postype(::Type{<:PatternLevel{Tp}}) where {Tp} = Tp

function moveto(lvl::PatternLevel{Tp}, device) where {Tp}
    return PatternLevel{Tp}()
end


"""
    pattern!(fbr)

Return the pattern of `fbr`. That is, return a tensor which is true wherever
`fbr` is structurally unequal to its fill_value. May reuse memory and render the
original tensor unusable when modified.

```jldoctest
julia> A = Tensor(SparseList(Element(0.0), 10), [2.0, 0.0, 3.0, 0.0, 4.0, 0.0, 5.0, 0.0, 6.0, 0.0])
10-Tensor
└─ SparseList (0.0) [1:10]
   ├─ [1]: 2.0
   ├─ [3]: 3.0
   ├─ ⋮
   ├─ [7]: 5.0
   └─ [9]: 6.0

julia> pattern!(A)
10-Tensor
└─ SparseList (false) [1:10]
   ├─ [1]: true
   ├─ [3]: true
   ├─ ⋮
   ├─ [7]: true
   └─ [9]: true
```
"""
pattern!(fbr::Tensor) = Tensor(pattern!(fbr.lvl))
pattern!(fbr::SubFiber) = SubFiber(pattern!(fbr.lvl), fbr.pos)

struct VirtualPatternLevel <: AbstractVirtualLevel
    Tp
end

function virtual_moveto_level(ctx::AbstractCompiler, lvl::VirtualPatternLevel, arch)
end

is_level_injective(ctx, ::VirtualPatternLevel) = []
is_level_atomic(ctx, lvl::VirtualPatternLevel) = ([], false)
is_level_concurrent(ctx, lvl::VirtualPatternLevel) = ([], true)

lower(ctx::AbstractCompiler, lvl::VirtualPatternLevel, ::DefaultStyle) = :(PatternLevel())
virtualize(ctx, ex, ::Type{PatternLevel{Tp}}) where {Tp} = VirtualPatternLevel(Tp)

virtual_level_resize!(ctx, lvl::VirtualPatternLevel) = lvl
virtual_level_size(ctx, ::VirtualPatternLevel) = ()
virtual_level_fill_value(::VirtualPatternLevel) = false
virtual_level_eltype(::VirtualPatternLevel) = Bool

postype(lvl::VirtualPatternLevel) = lvl.Tp

function declare_level!(ctx, lvl::VirtualPatternLevel, pos, init)
    init == literal(false) || throw(FinchProtocolError("Must initialize Pattern Levels to false"))
    lvl
end

freeze_level!(ctx, lvl::VirtualPatternLevel, pos) = lvl

thaw_level!(ctx, lvl::VirtualPatternLevel, pos) = lvl

assemble_level!(ctx, lvl::VirtualPatternLevel, pos_start, pos_stop) = quote end
reassemble_level!(ctx, lvl::VirtualPatternLevel, pos_start, pos_stop) = quote end

instantiate(ctx, ::VirtualSubFiber{VirtualPatternLevel}, mode::Reader, protos) = FillLeaf(true)

function instantiate(ctx, fbr::VirtualSubFiber{VirtualPatternLevel}, mode::Updater, protos)
    val = freshen(ctx.code, :null)
    push!(ctx.code.preamble, :($val = false))
    VirtualScalar(nothing, Bool, false, gensym(), val)
end

function instantiate(ctx, fbr::VirtualHollowSubFiber{VirtualPatternLevel}, mode::Updater, protos)
    VirtualScalar(nothing, Bool, false, gensym(), fbr.dirty)
end

function lower_access(ctx::AbstractCompiler, node, tns::VirtualFiber{VirtualPatternLevel})
    val = freshen(ctx.code, :null)
    push!(ctx.code.preamble, :($val = false))
    val
end
