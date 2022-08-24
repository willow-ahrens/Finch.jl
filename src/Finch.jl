module Finch

using Requires
using SyntaxInterface
using RewriteTools
using RewriteTools.Rewriters
using MacroTools
using Base.Iterators
using Base: @kwdef
using SparseArrays

export @finch, @finch_program, @finch_code, value

export Fiber, SparseList, SparseHash, SparseCoo, SparseBytemap, Dense, Repeat, Element, Pattern, FiberArray, Scalar
export walk, gallop, follow, extrude, laminate, select
export fiber, @fiber, pattern!, dropdefaults, dropdefaults!

export permit, offset, window

include("util.jl")

include("semantics.jl")
include("IndexNotation/IndexNotation.jl")
using .IndexNotation
using .IndexNotation: and, or
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
include("denselevels.jl")
include("repeatlevels.jl")
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

end