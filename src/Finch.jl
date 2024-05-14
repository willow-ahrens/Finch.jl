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
using Random: AbstractRNG, default_rng, randexp, randperm
using PrecompileTools
using Compat
using DataStructures
using JSON
using Distributions: Binomial, Normal, Poisson
using TOML
using UUIDs
using Preferences
using Polyester

export @finch, @finch_program, @finch_code, @finch_kernel, value

export Tensor
export SparseRLE, SparseRLELevel
export DenseRLE, DenseRLELevel
export SparseInterval, SparseIntervalLevel
export Sparse, SparseLevel, SparseDict
export SparseList, SparseListLevel
export SparsePoint, SparsePointLevel
export SparseBand, SparseBandLevel
export SparseHash, SparseHashLevel
export SparseCOO, SparseCOOLevel
export SparseByteMap, SparseByteMapLevel
export SparseVBL, SparseVBLLevel
export Dense, DenseLevel
export Element, ElementLevel
export Separate, SeparateLevel
export Atomic, AtomicLevel
export Pattern, PatternLevel
export Scalar, SparseScalar, ShortCircuitScalar, SparseShortCircuitScalar
export walk, gallop, follow, extrude, laminate
export Tensor, pattern!, dropfills, dropfills!, set_fill_value!
export diagmask, lotrimask, uptrimask, bandmask, chunkmask
export scale, products, offset, permissive, protocolize, swizzle, toeplitz, window
export PlusOneVector

export lazy, compute, tensordot, @einsum

export choose, minby, maxby, overwrite, initwrite, filterop, d

export fill_value, AsArray, expanddims

export parallelAnalysis, ParallelAnalysisResults
export parallel, realextent, extent, dimless
export CPU, CPULocalVector, CPULocalMemory

export Limit, Eps

struct FinchProtocolError <: Exception
    msg::String
end

struct FinchExtensionError <: Exception
    msg::String
end

const FINCH_VERSION = VersionNumber(TOML.parsefile(joinpath(dirname(@__DIR__), "Project.toml"))["version"])

include("util/convenience.jl")
include("util/shims.jl")
include("util/limits.jl")
include("util/staging.jl")
include("util/style.jl")
include("util/vectors.jl")

include("environment.jl")

include("FinchNotation/FinchNotation.jl")
using .FinchNotation
using .FinchNotation: and, or, InitWriter

include("abstract_tensor.jl")
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
include("tensors/abstract_level.jl")
include("tensors/fibers.jl")
include("tensors/levels/sparse_rle_levels.jl")
include("tensors/levels/sparse_interval_levels.jl")
include("tensors/levels/sparse_list_levels.jl")
include("tensors/levels/sparse_point_levels.jl")
include("tensors/levels/sparse_hash_levels.jl")
include("tensors/levels/sparse_coo_levels.jl")
include("tensors/levels/sparse_band_levels.jl")
include("tensors/levels/sparse_levels.jl")
include("tensors/levels/sparse_bytemap_levels.jl")
include("tensors/levels/sparse_vbl_levels.jl")
include("tensors/levels/dense_levels.jl")
include("tensors/levels/dense_rle_levels.jl")
include("tensors/levels/element_levels.jl")
include("tensors/levels/separate_levels.jl")
include("tensors/levels/atomic_levels.jl")
include("tensors/levels/pattern_levels.jl")
include("tensors/masks.jl")
include("tensors/abstract_combinator.jl")
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

include("postprocess.jl")

export fsparse, fsparse!, fsprand, fspzeros, ffindnz, fread, fwrite, countstored

export bspread, bspwrite
export ftnsread, ftnswrite, fttread, fttwrite

export moveto, postype

include("FinchLogic/FinchLogic.jl")
using .FinchLogic

include("scheduler/LogicCompiler.jl")
include("scheduler/LogicExecutor.jl")
include("scheduler/LogicInterpreter.jl")
include("scheduler/optimize.jl")

include("interface/traits.jl")
include("interface/abstract_arrays.jl")
include("interface/abstract_unit_ranges.jl")
include("interface/index.jl")
include("interface/compare.jl")
include("interface/copy.jl")
include("interface/fsparse.jl")
include("interface/fileio/fileio.jl")
include("interface/lazy.jl")
include("interface/eager.jl")
include("interface/einsum.jl")

@deprecate default fill_value
@deprecate redefault! set_fill_value!
@deprecate dropdefaults dropfills
@deprecate dropdefaults! dropfills!

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

        if @load_preference("precompile", true)
            @info "Running enhanced precompilation... (to disable, run `using Preferences; Preferences.set_preferences!(\"Finch\", \"precompile\"=>false)`"
            include("../test/precompile.jl")
        end
    end
end

end
