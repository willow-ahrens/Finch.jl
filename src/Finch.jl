module Finch

@static if !isdefined(Base, :get_extension)
    using Requires
end

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

export @finch, @finch_program, @finch_code, value

export Fiber, Fiber!, Scalar
export SparseList, SparseListLevel
export SparseHash, SparseHashLevel
export SparseCOO, SparseCOOLevel
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

export permit, offset, staticoffset, window

export default, AsArray

include("util.jl")

include("semantics.jl")
include("FinchNotation/FinchNotation.jl")
using .FinchNotation
using .FinchNotation: and, or, InitWriter
include("virtualize.jl")
include("style.jl")
include("lower.jl")
include("dimensionalize.jl")
include("extent_oracle.jl")
using .ExtentOracle
include("annihilate.jl")

include("looplets/fills.jl")
include("looplets/nulls.jl")
include("looplets/shifts.jl")
include("looplets/chunks.jl")
include("looplets/runs.jl")
include("looplets/spikes.jl")
include("looplets/switches.jl")
include("looplets/phases.jl")
include("looplets/pipelines.jl")
include("looplets/cycles.jl")
include("looplets/jumpers.jl")
include("looplets/steppers.jl")

include("execute.jl")
include("masks.jl")
include("scalars.jl")

include("fibers.jl")
include("levels/sparselistlevels.jl")
include("levels/sparsehashlevels.jl")
include("levels/sparsecoolevels.jl")
include("levels/sparsebytemaplevels.jl")
include("levels/sparsevbllevels.jl")
include("levels/denselevels.jl")
include("levels/repeatrlelevels.jl")
include("levels/elementlevels.jl")
include("levels/patternlevels.jl")

include("traits.jl")

include("modifiers.jl")

export fsparse, fsparse!, fsprand, fspzeros, ffindnz, countstored

module h
    using Finch
    function generate_embed_docs()
        finch_h = read(joinpath(dirname(pathof(Finch)), "../embed/finch.h"), String)
        blocks = map(m -> m.captures[1], eachmatch(r"\/\*\!(((?!\*\/)(.|\n|\r))*)\*\/", finch_h))
        map(blocks) do block
            block = strip(block)
            lines = collect(eachline(IOBuffer(block)))
            key = Meta.parse(strip(lines[1]))
            body = strip(join(lines[2:end], "\n"))
            @eval begin
                """
                    $($body)
                """
                $key
            end
        end
    end

    generate_embed_docs()
end

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

end