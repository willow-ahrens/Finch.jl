"""
    IsoLevel{Vf, Vp, [Tv = Union{typeof(Vf), typeof(Vp)}], [Tp=Int]}()

A subfiber of a pattern level is the Boolean value true, but it's `fill_value` is
false. IsoLevels are used to create tensors that represent which values
are stored by other fibers. See [`pattern!`](@ref) for usage examples.

```jldoctest
julia> Tensor(Dense(Iso(false, true)), 3)
3-Tensor
└─ Dense [1:3]
   ├─ [1]: true
   ├─ [2]: true
   └─ [3]: true
```
"""
struct IsoLevel{Vf, Vp, Tv, Tp} <: AbstractLevel end
const Iso = IsoLevel

function IsoLevel(vf, vp, args...)
    isbits(vf) || throw(ArgumentError("Finch currently only supports isbits fill values"))
    isbits(vp) || throw(ArgumentError("Finch currently only supports isbits pattern values"))
    IsoLevel{vf, vp}(args...)
end
IsoLevel{Vf, Vp}() where {Vf, Vp} = IsoLevel{Vf, Vp, Union{typeof(Vf), typeof(Vp)}}()
IsoLevel{Vf, Vp, Tv}() where {Vf, Vp, Tv} = IsoLevel{Vf, Vp, Tv, Int}()

Base.summary(::Iso{Vf, Vp}) where {Vf, Vp} = "Iso($Vf, $Vp)"
similar_level(::IsoLevel, ::Any, ::Type, ::Vararg) = IsoLevel()

countstored_level(lvl::IsoLevel, pos) = pos

labelled_show(io::IO, ::SubFiber{<:IsoLevel}) =
    print(io, true)

Base.resize!(lvl::IsoLevel) = lvl

pattern!(::IsoLevel{Vf, Vp, Tv, Tp}) where {Vf, Vp, Tv, Tp} = IsoLevel{false, true, Tv, Tp}()

function Base.show(io::IO, lvl::IsoLevel)
    print(io, "Iso($(lvl.Vf), $(lvl.Vp)")
end

@inline level_ndims(::Type{<:IsoLevel}) = 0
@inline level_size(::IsoLevel) = ()
@inline level_axes(::IsoLevel) = ()
@inline level_eltype(::Type{<:IsoLevel}) = Bool
@inline level_fill_value(::Type{<:IsoLevel}) = false
(fbr::AbstractFiber{<:IsoLevel})() = true
data_rep_level(::Type{<:IsoLevel}) = ElementData(false, Bool)

postype(::Type{<:IsoLevel{Vf, Vp, Tv, Tp}}) where {Vf, Vp, Tv, Tp} = Tp

function moveto(lvl::IsoLevel{Vf, Vp, Tv, Tp}, device) where {Vf, Vp, Tv, Tp}
    return IsoLevel{Vf, Vp, Tv, Tp}()
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

struct VirtualIsoLevel <: AbstractVirtualLevel
    Vf
    Vp
    Tv
    Tp
end

function virtual_moveto_level(ctx::AbstractCompiler, lvl::VirtualIsoLevel, arch)
end

is_level_injective(ctx, ::VirtualIsoLevel) = []
is_level_atomic(ctx, lvl::VirtualIsoLevel) = ([], false)
is_level_concurrent(ctx, lvl::VirtualIsoLevel) = ([], true)

lower(ctx::AbstractCompiler, lvl::VirtualIsoLevel, ::DefaultStyle) = :(IsoLevel($(lvl.Vf), $(lvl.Vp)))
virtualize(ctx, ex, ::Type{IsoLevel{Vf, Vp, Tv, Tp}}) where {Vf, Vp, Tv, Tp} = VirtualIsoLevel(Vf, Vp, Tv, Tp)

virtual_level_resize!(ctx, lvl::VirtualIsoLevel) = lvl
virtual_level_size(ctx, ::VirtualIsoLevel) = ()
virtual_level_fill_value(lvl::VirtualIsoLevel) = lvl.Vf
virtual_level_eltype(::VirtualIsoLevel) = Bool

postype(lvl::VirtualIsoLevel) = lvl.Tp

function declare_level!(ctx, lvl::VirtualIsoLevel, pos, init)
    init == literal(false) || throw(FinchProtocolError("Must initialize Iso Levels to false"))
    lvl
end

freeze_level!(ctx, lvl::VirtualIsoLevel, pos) = lvl

thaw_level!(ctx, lvl::VirtualIsoLevel, pos) = lvl

assemble_level!(ctx, lvl::VirtualIsoLevel, pos_start, pos_stop) = quote end
reassemble_level!(ctx, lvl::VirtualIsoLevel, pos_start, pos_stop) = quote end

instantiate(ctx, fbr::VirtualSubFiber{VirtualIsoLevel}, mode::Reader, protos) = FillLeaf(fbr.lvl.Vp)

function instantiate(ctx, fbr::VirtualSubFiber{VirtualIsoLevel}, mode::Updater, protos)
    val = freshen(ctx, :null)
    push_preamble!(ctx, :($val = false))
    VirtualScalar(nothing, fbr.lvl.Tv, false, gensym(), val)
end

function instantiate(ctx, fbr::VirtualHollowSubFiber{VirtualIsoLevel}, mode::Updater, protos)
    VirtualScalar(nothing, fbr.lvl.Tv, false, gensym(), fbr.dirty)
end

function lower_access(ctx::AbstractCompiler, node, tns::VirtualFiber{VirtualIsoLevel})
    val = freshen(ctx, :null)
    push_preamble!(ctx, :($val = false))
    val
end
