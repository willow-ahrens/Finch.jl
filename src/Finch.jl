module Finch

using Pigeon
using Pigeon: Dimensions, dimensionalize!, DefaultStyle, getname
using Pigeon: visit!, isliteral, pass
using SymbolicUtils
using SymbolicUtils: istree, arguments, operation, similarterm
using SymbolicUtils: Chain, Fixpoint
using SymbolicUtils: Postwalk, Prewalk
using TermInterface
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