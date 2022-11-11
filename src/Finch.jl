module Finch

using Requires
using SyntaxInterface
using RewriteTools
using RewriteTools.Rewriters
using MacroTools
using Base.Iterators
using Base: @kwdef
using SparseArrays
using SnoopPrecompile
using Compat

export @finch, @finch_program, @finch_code, value

export Fiber, SparseList, SparseHash, SparseCoo, SparseBytemap, SparseVBL, Dense, RepeatRLE, Element, Pattern, Scalar
export walk, fastwalk, gallop, follow, extrude, laminate, select
export fiber, @fiber, pattern!, dropdefaults, dropdefaults!

export permit, offset, window

include("util.jl")

include("semantics.jl")
include("IndexNotation/IndexNotation.jl")
using .IndexNotation
using .IndexNotation: and, or, right
include("virtualize.jl")
include("style.jl")
include("transform_ssa.jl")
include("lower.jl")
include("dimensionalize.jl")
include("annihilate.jl")

include("shifts.jl")
include("chunks.jl")
include("runs.jl")
include("spikes.jl")
include("switches.jl")

include("phases.jl")
include("pipelines.jl")
include("cycles.jl")
include("jumpers.jl")
include("steppers.jl")

include("execute.jl")
include("select.jl")
include("fibers.jl")
include("scalars.jl")
include("sparselistlevels.jl")
include("sparsehashlevels.jl")
include("sparsecoolevels.jl")
include("sparsebytemaplevels.jl")
include("sparsevbllevels.jl")
include("denselevels.jl")
include("repeatrlelevels.jl")
include("elementlevels.jl")
include("patternlevels.jl")

include("permit.jl")
include("offset.jl")
include("window.jl")

include("fibers_meta.jl")
export fsparse, fsparse!, fsprand, fspzeros, ffindnz

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

include("glue_AbstractArrays.jl")
include("glue_SparseArrays.jl")
function __init__()
    #@require SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf" include("glue_SparseArrays.jl")
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
        Finch.execute_code(:ex, typeof(Finch.@finch_program_instance @loop i j y[i] += A[i, j] * x[i]))
    end
end

end