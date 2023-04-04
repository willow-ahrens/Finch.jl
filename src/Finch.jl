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
using SnoopPrecompile
using Compat

export @finch, @finch_program, @finch_code, value

export Fiber, Fiber!, SparseList, SparseHash, SparseCOO, SparseByteMap, SparseVBL, Dense, RepeatRLE, Element, Pattern, Scalar
export walk, gallop, follow, extrude, laminate
export fiber, fiber!, @fiber, pattern!, dropdefaults, dropdefaults!, redefault!
export diagmask, lotrimask, uptrimask, bandmask

export choose, minby, maxby, overwrite, initwrite

export permit, offset, staticoffset, window

include("util.jl")

registry = []

include("semantics.jl")
include("FinchNotation/FinchNotation.jl")
using .FinchNotation
using .FinchNotation: and, or, InitWriter
include("virtualize.jl")
include("style.jl")
include("lower.jl")
include("dimensionalize.jl")
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

function register(algebra)
    for r in registry
        @eval Finch $(r(algebra))
    end
end

register(DefaultAlgebra)

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
    end
end

@precompile_setup begin
    # Putting some things in `setup` can reduce the size of the
    # precompile file and potentially make loading faster.
    @precompile_all_calls begin
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

function constprop_read(tns::VirtualScalar, ctx, stmt, node)
    if @capture stmt sequence(declare(~a, ~z))
        return z
    else
        return node
    end
end

end