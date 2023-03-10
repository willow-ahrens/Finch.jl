module Finch

using Requires
using SyntaxInterface
using RewriteTools
using RewriteTools.Rewriters
using Base.Iterators
using Base: @kwdef
using SparseArrays
using SnoopPrecompile
using Compat

export @finch, @finch_program, @finch_code, value

export Fiber, Fiber!, SparseList, SparseHash, SparseCOO, SparseBytemap, SparseVBL, Dense, RepeatRLE, Element, Pattern, Scalar
export walk, gallop, follow, extrude, laminate
export fiber, @fiber, pattern!, dropdefaults, dropdefaults!, redefault!
export diagmask, lotrimask, uptrimask, bandmask

export choose, minby, maxby

export permit, offset, staticoffset, window

include("util.jl")

include("semantics.jl")
include("FinchNotation/FinchNotation.jl")
using .FinchNotation
using .FinchNotation: and, or, right
include("virtualize.jl")
include("style.jl")
include("lower.jl")
include("dimensionalize.jl")
include("annihilate.jl")

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

register(DefaultAlgebra)
#TODO add an uninitialized_fiber type so that we can perhaps do this through executing declare(fbr),
#obviating the need to have a separate generated function registration mechanism for fibers.
@generated function Fiber!(lvl)
    contain(LowerJulia()) do ctx
        lvl = virtualize(:lvl, lvl, ctx)
        lvl = resolve(lvl, ctx)
        lvl = declare_level!(lvl, ctx, literal(0), literal(virtual_level_default(lvl)))
        push!(ctx.preamble, assemble_level!(lvl, ctx, literal(1), literal(1)))
        lvl = freeze_level!(lvl, ctx, literal(1))
        :(Fiber($(ctx(lvl))))
    end |> lower_caches |> lower_cleanup
end

include("glue_AbstractArrays.jl")
include("glue_AbstractUnitRanges.jl")
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
        Finch.execute_code(:ex, typeof(Finch.@finch_program_instance begin
                @loop j i y[i] += A[i, j] * x[i]
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