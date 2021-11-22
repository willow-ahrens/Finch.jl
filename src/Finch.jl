module Finch

using Pigeon
using SymbolicUtils
using SymbolicUtils: istree, arguments, operation, similarterm
using SymbolicUtils: Postwalk, Prewalk

export SparseLevel
export SparseFiber
export DenseLevel
export DenseFiber
export ScalarLevel
export ScalarFiber

export lower

include("utils.jl")
include("levels.jl")
include("virtuals.jl")
include("lower.jl")

end