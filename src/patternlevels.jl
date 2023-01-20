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

@inline level_ndims(::Type{PatternLevel}) = 0
@inline level_size(::PatternLevel) = ()
@inline level_axes(::PatternLevel) = ()
@inline level_eltype(::Type{PatternLevel}) = Bool
@inline level_default(::Type{PatternLevel}) = false
(fbr::Fiber{<:PatternLevel})() = true

"""
    pattern!(fbr)

Return the pattern of `fbr`. That is, return a fiber which is true wherever
`fbr` is structurally unequal to it's default. May reuse memory and render the
original fiber unusable when modified.

```jldoctest
julia> A = Finch.Fiber(SparseList(10, [1, 6], [1, 3, 5, 7, 9], Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
SparseList (0.0) [1:10]
│ 
└─[1] [3] [5] [7] [9]
  2.0 3.0 4.0 5.0 6.0

julia> pattern!(A)
SparseList (false) [1:10]
│ 
└─[1]  [3]  [5]  [7]  [9] 
  true true true true true
```
"""
pattern!(fbr::Fiber) = Fiber(pattern!(fbr.lvl), fbr.env)

struct VirtualPatternLevel end

(ctx::Finch.LowerJulia)(lvl::VirtualPatternLevel) = :(PatternLevel())
virtualize(ex, ::Type{<:PatternLevel}, ctx, tag) = VirtualPatternLevel()

virtual_level_resize!(lvl::VirtualPatternLevel, ctx) = lvl
virtual_level_size(::VirtualPatternLevel, ctx) = ()
virtual_level_default(::VirtualPatternLevel) = false
virtual_level_eltype(::VirtualPatternLevel) = Bool

initialize_level!(fbr::VirtualFiber{VirtualPatternLevel}, ctx, mode) = fbr.lvl

finalize_level!(fbr::VirtualFiber{VirtualPatternLevel}, ctx, mode) = fbr.lvl

interval_assembly_depth(lvl::VirtualPatternLevel) = Inf

assemble!(fbr::VirtualFiber{VirtualPatternLevel}, ctx, mode) = fbr.lvl

reinitialize!(fbr::VirtualFiber{VirtualPatternLevel}, ctx, mode) = fbr.lvl

trim_level!(lvl::VirtualPatternLevel, ctx::LowerJulia, pos) = lvl

function refurl(fbr::VirtualFiber{VirtualPatternLevel}, ctx, mode)
    if mode.kind === reader
        return Simplify(Fill(true))
    else
        fbr
    end
end

hasdefaultcheck(::VirtualPatternLevel) = true

function lowerjulia_access(ctx::LowerJulia, node, tns::VirtualFiber{VirtualPatternLevel})
    @assert isempty(node.idxs)

    node.mode.kind === reader && return true

    if envdefaultcheck(tns.env) !== nothing
        push!(ctx.preamble, quote
            $(envdefaultcheck(tns.env)) = false
        end)
    end

    val = ctx.freshen(:null)
    push!(ctx.preamble, :($val = false))
    val
end