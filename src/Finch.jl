module Finch

using SyntaxInterface
using RewriteTools
using RewriteTools.Rewriters
using MacroTools
using Base.Iterators
using Base: @kwdef

export @index, @index_code_lowered

export Fiber, HollowList, HollowHash, HollowCoo, HollowByte, Solid, Element, FiberArray, Scalar
export walk, gallop, follow, extrude, laminate, select

include("util.jl")

include("semantics.jl")
include("IndexNotation/IndexNotation.jl")
using .IndexNotation
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
include("cases.jl")

include("phases.jl")
include("pipelines.jl")
include("cycles.jl")
include("jumpers.jl")
include("steppers.jl")

include("execute.jl")
include("virtual_abstractarray.jl")
include("select.jl")
include("fibers.jl")
include("scalars.jl")
include("hollowlistlevels.jl")
include("hollowhashlevels.jl")
include("hollowcoolevels.jl")
include("hollowbytelevels.jl")
include("solidlevels.jl")
include("elementlevels.jl")

include("permit.jl")


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

end