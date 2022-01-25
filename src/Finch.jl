module Finch

using Pigeon
using Pigeon: Dimensions, dimensionalize!, DefaultStyle, getname
using Pigeon: visit!, isliteral, pass
using SyntaxInterface
using RewriteTools
using RewriteTools.Rewriters
using MacroTools
using DataStructures
using Base.Iterators

using Pigeon: Read, Write, Update

export Virtual, Scalar, Chunk
export @I, execute

export Fiber, HollowListLevel, SolidLevel, ElementLevel

include("virtualize.jl")
include("lower.jl")
include("protocols.jl")
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