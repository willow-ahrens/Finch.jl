struct PatternLevel end
const Pattern = PatternLevel

"""
`f_code(p)` = [PatternLevel](@ref).
"""
f_code(::Val{:p}) = Pattern
summary_f_code(::Pattern) = "p()"
similar_level(::PatternLevel) = PatternLevel()

function Base.show(io::IO, lvl::PatternLevel)
    print(io, "Pattern()")
end 

@inline arity(fbr::Fiber{<:PatternLevel}) = 0
@inline shape(fbr::Fiber{<:PatternLevel}) = ()
@inline domain(fbr::Fiber{<:PatternLevel}) = ()
@inline image(fbr::Fiber{<:PatternLevel}) = Bool
@inline default(lvl::Fiber{<:PatternLevel}) = false

(fbr::Fiber{<:PatternLevel})() = true

"""
    pattern!(fbr)

Return the pattern of `fbr`. That is, return a fiber which is true wherever
`fbr` is structurally unequal to it's default. May reuse memory and render the
original fiber unusable when modified.

```jldoctest
julia> A = Finch.Fiber(
    HollowList(10, [1, 6], [1, 3, 5, 7, 9],
    Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
HollowList (0.0) [1:10]
│ 
└─[1] [3] [5] [7] [9]
  2.0 3.0 4.0 5.0 6.0

julia> pattern!(A)
HollowList (false) [1:10]
│ 
└─[1]  [3]  [5]  [7]  [9] 
  true true true true true
```
"""
pattern!(fbr::Fiber) = Fiber(pattern!(fbr.lvl), fbr.env)

struct VirtualPatternLevel end

(ctx::Finch.LowerJulia)(lvl::VirtualPatternLevel) = :(PatternLevel())
virtualize(ex, ::Type{<:PatternLevel}, ctx, tag) = VirtualPatternLevel()

function getsites(fbr::VirtualFiber{VirtualPatternLevel})
    return []
end

setdims!(fbr::VirtualFiber{VirtualPatternLevel}, ctx, mode) = fbr
getdims(::VirtualFiber{VirtualPatternLevel}, ctx, mode) = ()

@inline default(fbr::VirtualFiber{VirtualPatternLevel}) = false
@inline image(fbr::VirtualFiber{VirtualPatternLevel}) = Bool

initialize_level!(fbr::VirtualFiber{VirtualPatternLevel}, ctx, mode::Union{Write, Update}) = fbr.lvl

finalize_level!(fbr::VirtualFiber{VirtualPatternLevel}, ctx, mode::Union{Write, Update}) = fbr.lvl

interval_assembly_depth(lvl::VirtualPatternLevel) = Inf

assemble!(fbr::VirtualFiber{VirtualPatternLevel}, ctx, mode) = fbr.lvl

reinitialize!(fbr::VirtualFiber{VirtualPatternLevel}, ctx, mode) = fbr.lvl

function refurl(fbr::VirtualFiber{VirtualPatternLevel}, ctx, ::Read)
    Simplify(Literal(true))
end

function (ctx::Finch.LowerJulia)(node::Access{<:VirtualFiber{VirtualPatternLevel}}, ::DefaultStyle) where {Tv, Ti}
    @assert isempty(node.idxs)
    true
end

hasdefaultcheck(::VirtualPatternLevel) = true

function (ctx::Finch.LowerJulia)(node::Access{<:VirtualFiber{VirtualPatternLevel}, <:Union{Write, Update}}, ::DefaultStyle) where {Tv, Ti}
    @assert isempty(node.idxs)
    tns = node.tns

    if envdefaultcheck(tns.env) !== nothing
        push!(ctx.preamble, quote
            $(envdefaultcheck(tns.env)) = false
        end)
    end

    val = ctx.freshen(:null)
    push!(ctx.preamble, :($val = false))
    val
end