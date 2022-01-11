module Finch

using Pigeon
using Pigeon: Dimensions, dimensionalize!, DefaultStyle, getname
using Pigeon: visit!, isliteral, pass
using RewriteTools
using RewriteTools: istree, arguments, operation, similarterm
using RewriteTools: Chain, Fixpoint
using RewriteTools: Postwalk, Prewalk
using SyntaxInterface
using MacroTools
using DataStructures
using Base.Iterators

using Pigeon: Read, Write, Update

using Pigeon: @ex

export Virtual, Scalar, Chunk
export @I, execute

export Fiber, SparseLevel, DenseLevel, ScalarLevel

include("virtualize.jl")
include("lower.jl")
include("protocols.jl")
include("annihilate.jl")
include("chunks.jl")
include("runs.jl")
include("spikes.jl")
include("cases.jl")
include("streams.jl")
include("execute.jl")
include("virtual_abstractarray.jl")
include("fibers.jl")

end