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
export lower_julia
export @I, execute

include("lower.jl")
include("annihilate.jl")
include("virtuals.jl")
include("chunks.jl")
include("runs.jl")
include("spikes.jl")
include("cases.jl")
include("streams.jl")
include("mesa.jl")
include("execute.jl")

end