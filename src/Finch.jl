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

export fastfinch, safefinch, debugfinch

export Tensor
export SparseRLE, SparseRLELevel 
export SingleRLE, SingleRLELevel
export SparseList, SparseListLevel
export SingleList, SingleListLevel
export SparseHash, SparseHashLevel
export SparseCOO, SparseCOOLevel
export SparseTriangle, SparseTriangleLevel
export SparseByteMap, SparseByteMapLevel
export SparseVBL, SparseVBLLevel
export Dense, DenseLevel
export RepeatRLE, RepeatRLELevel
export Element, ElementLevel
export Separation, SeparationLevel
export Pattern, PatternLevel
export Scalar, SparseScalar, ShortCircuitScalar, SparseShortCircuitScalar
export walk, gallop, follow, extrude, laminate
export Tensor, pattern!, dropdefaults, dropdefaults!, redefault!
export diagmask, lotrimask, uptrimask, bandmask
export scale, product, offset, permissive, protocolize, swizzle, toeplitz, window

export choose, minby, maxby, overwrite, initwrite, d

export default, AsArray

export parallelAnalysis, ParallelAnalysisResults
export parallel, realextent, extent, dimless
export CPU, CPULocalVector, CPULocalMemory

export Limit

struct FinchProtocolError <: Exception
    msg::String
end

struct FinchExtensionError <: Exception
    msg::String
end

include("util/util.jl")
include("util/limits.jl")

include("environment.jl")
include("FinchNotation/FinchNotation.jl")
using .FinchNotation
using .FinchNotation: and, or, InitWriter
include("semantics.jl")
include("style.jl")
include("dimensions.jl")
include("architecture.jl")
include("lower.jl")

include("transforms/concordize.jl")
include("transforms/wrapperize.jl")
include("transforms/scopes.jl")
include("transforms/lifecycle.jl")
include("transforms/dimensionalize.jl")
include("transforms/evaluate.jl")
include("transforms/concurrent.jl")

include("execute.jl")

include("symbolic/symbolic.jl")

include("looplets/thunks.jl")
include("looplets/short_circuits.jl")
include("looplets/lookups.jl")
include("looplets/nulls.jl")
include("looplets/unfurl.jl")
include("looplets/runs.jl")
include("looplets/spikes.jl")
include("looplets/switches.jl")
include("looplets/phases.jl")
include("looplets/sequences.jl")
include("looplets/jumpers.jl")
include("looplets/steppers.jl")
include("looplets/fills.jl")

include("tensors/scalars.jl")
include("tensors/levels/abstractlevel.jl")
include("tensors/fibers.jl")
include("tensors/levels/sparserlelevels.jl")
include("tensors/levels/singlerlelevels.jl")
include("tensors/levels/sparselistlevels.jl")
include("tensors/levels/singlelistlevels.jl")
include("tensors/levels/sparsehashlevels.jl")
include("tensors/levels/sparsecoolevels.jl")
include("tensors/levels/sparsebytemaplevels.jl")
include("tensors/levels/sparsevbllevels.jl")
include("tensors/levels/denselevels.jl")
include("tensors/levels/repeatrlelevels.jl")
include("tensors/levels/elementlevels.jl")
include("tensors/levels/separationlevel.jl")
include("tensors/levels/patternlevels.jl")
include("tensors/levels/sparsetrianglelevels.jl")
include("tensors/masks.jl")
include("tensors/combinators/abstractCombinator.jl")
include("tensors/combinators/unfurled.jl")
include("tensors/combinators/protocolized.jl")
include("tensors/combinators/roots.jl")
include("tensors/combinators/permissive.jl")
include("tensors/combinators/offset.jl")
include("tensors/combinators/toeplitz.jl")
include("tensors/combinators/windowed.jl")
include("tensors/combinators/swizzle.jl")
include("tensors/combinators/scale.jl")
include("tensors/combinators/product.jl")

include("traits.jl")

export fsparse, fsparse!, fsprand, fspzeros, ffindnz, fread, fwrite, countstored

export bspread, bspwrite
export ftnsread, ftnswrite, fttread, fttwrite

export moveto, postype

include("FinchLogic/FinchLogic.jl")
using .FinchLogic
include("interface/abstractarrays.jl")
include("interface/abstractunitranges.jl")
include("interface/broadcast.jl")
include("interface/index.jl")
include("interface/mapreduce.jl")
include("interface/compare.jl")
include("interface/copy.jl")
include("interface/fsparse.jl")
include("interface/fileio/fileio.jl")
include("interface/lazy.jl")
include("interface/compute.jl")

@static if !isdefined(Base, :get_extension)
    function __init__()
        @require SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf" include("../ext/SparseArraysExt.jl")
        @require HDF5 = "f67ccb44-e63f-5c2f-98bd-6dc0ccc4ba2f" include("../ext/HDF5Ext.jl")
        @require TensorMarket = "8b7d4fe7-0b45-4d0d-9dd8-5cc9b23b4b77" include("../ext/TensorMarketExt.jl")
        @require NPZ = "15e1cf62-19b3-5cfa-8e77-841668bca605" include("../ext/NPZExt.jl")
    end
end

@setup_workload begin
    # Putting some things in `setup` can reduce the size of the
    # precompile file and potentially make loading faster.
    @compile_workload begin
        # all calls in this block will be precompiled, regardless of whether
        # they belong to your package or not (on Julia 1.8 and higher)
        y = Tensor(Dense(Element(0.0)))
        A = Tensor(Dense(SparseList(Element(0.0))))
        x = Tensor(SparseList(Element(0.0)))
        Finch.execute_code(:ex, typeof(Finch.@finch_program_instance begin
                for j=_, i=_; y[i] += A[i, j] * x[j] end
            end
        ))

    end
end

end
