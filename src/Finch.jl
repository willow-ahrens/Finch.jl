module Finch

@static if !isdefined(Base, :get_extension)
    using Requires
end

using AbstractTrees
using SyntaxInterface
using RewriteTools
using RewriteTools.Rewriters
using Base.Iterators
using Base: @kwdef
using Random: randsubseq, AbstractRNG, default_rng
using PrecompileTools
using Compat
using DataStructures
using JSON
using CIndices

export @finch, @finch_program, @finch_code, @finch_kernel, value

export Fiber, Fiber!, Scalar
export SparseRLE, SparseRLELevel 
export SparseList, SparseListLevel
export SparseHash, SparseHashLevel
export SparseCOO, SparseCOOLevel
export SparseTriangle, SparseTriangleLevel
export SparseByteMap, SparseByteMapLevel
export SparseVBL, SparseVBLLevel
export Dense, DenseLevel
export RepeatRLE, RepeatRLELevel
export Element, ElementLevel
export Pattern, PatternLevel
export walk, gallop, follow, extrude, laminate
export fiber, fiber!, @fiber, pattern!, dropdefaults, dropdefaults!, redefault!
export diagmask, lotrimask, uptrimask, bandmask

export choose, minby, maxby, overwrite, initwrite

export default, AsArray

export parallel, extent, dimless

include("util.jl")

include("FinchNotation/FinchNotation.jl")
using .FinchNotation
using .FinchNotation: and, or, InitWriter
include("semantics.jl")
include("virtualize.jl")
include("style.jl")
include("dimensions.jl")
include("lower.jl")

include("transforms/concordize.jl")
include("transforms/wrapperize.jl")
include("transforms/scopes.jl")
include("transforms/lifecycle.jl")
include("transforms/dimensionalize.jl")
include("transforms/evaluate.jl")

include("execute.jl")

include("symbolic/symbolic.jl")

include("looplets/thunks.jl")
include("looplets/lookups.jl")
include("looplets/nulls.jl")
include("looplets/unfurl.jl")
include("looplets/runs.jl")
include("looplets/spikes.jl")
include("looplets/switches.jl")
include("looplets/phases.jl")
include("looplets/pipelines.jl")
include("looplets/jumpers.jl")
include("looplets/steppers.jl")
include("looplets/fills.jl")

include("tensors/scalars.jl")
include("tensors/fibers.jl")
include("tensors/levels/sparserlelevels.jl")
include("tensors/levels/sparselistlevels.jl")
include("tensors/levels/sparsehashlevels.jl")
include("tensors/levels/sparsecoolevels.jl")
include("tensors/levels/sparsebytemaplevels.jl")
include("tensors/levels/sparsevbllevels.jl")
include("tensors/levels/denselevels.jl")
include("tensors/levels/repeatrlelevels.jl")
include("tensors/levels/elementlevels.jl")
include("tensors/levels/patternlevels.jl")
include("tensors/levels/sparsetrianglelevels.jl")
include("tensors/masks.jl")
include("tensors/combinators/unfurled.jl")
include("tensors/combinators/protocolized.jl")
include("tensors/combinators/roots.jl")
include("tensors/combinators/permissive.jl")
include("tensors/combinators/offset.jl")
include("tensors/combinators/toeplitz.jl")
include("tensors/combinators/windowed.jl")


include("traits.jl")

export fsparse, fsparse!, fsprand, fspzeros, ffindnz, countstored

include("base/abstractarrays.jl")
include("base/abstractunitranges.jl")
include("base/broadcast.jl")
include("base/index.jl")
include("base/mapreduce.jl")
include("base/compare.jl")
include("base/copy.jl")
include("base/fsparse.jl")

@static if !isdefined(Base, :get_extension)
    function __init__()
        @require SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf" include("../ext/SparseArraysExt.jl")
        @require HDF5 = "f67ccb44-e63f-5c2f-98bd-6dc0ccc4ba2f" include("../ext/HDF5Ext/HDF5Ext.jl")
        @require TensorMarket = "8b7d4fe7-0b45-4d0d-9dd8-5cc9b23b4b77" include("../ext/TensorMarketExt.jl")
    end
end

@setup_workload begin
    # Putting some things in `setup` can reduce the size of the
    # precompile file and potentially make loading faster.
    @compile_workload begin
        # all calls in this block will be precompiled, regardless of whether
        # they belong to your package or not (on Julia 1.8 and higher)
        y = @fiber d(e(0.0))
        A = @fiber d(sl(e(0.0)))
        x = @fiber sl(e(0.0))
        Finch.execute_code(:ex, typeof(Finch.@finch_program_instance begin
                @loop j i y[i] += A[i, j] * x[j]
            end
        ))

    end
end

include("fileio/fiberio.jl")
include("fileio/binsparse.jl")
include("fileio/tensormarket.jl")

export fbrread, fbrwrite, bsread, bswrite
export ftnsread, ftnswrite, fttread, fttwrite

include("resumables.jl")

end
