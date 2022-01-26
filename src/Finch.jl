module Finch

using SyntaxInterface
using RewriteTools
using RewriteTools.Rewriters
using MacroTools
using DataStructures
using Base.Iterators

export @I, execute

export Fiber, HollowList, Solid, Element

include("semantics.jl")
include("IndexNotation/IndexNotation.jl")
using .IndexNotation
include("virtualize.jl")
include("style.jl")
include("dimensionalize.jl")
include("lower.jl")
include("annihilate.jl")
include("chunks.jl")
include("runs.jl")
include("spikes.jl")
include("cases.jl")
include("steppers.jl")
include("phases.jl")
include("execute.jl")
include("virtual_abstractarray.jl")
include("fibers.jl")

end