using Finch
using Pigeon
using Test
using MacroTools

using Finch: VirtualAbstractArray, Run, Spike, Extent, Scalar, Cases, Stream, AcceptRun, Thunk

Base.@kwdef struct ChunkVector
    body
    ext
    name = gensym()
end

Pigeon.lower_axes(arr::ChunkVector, ctx::Finch.LowerJuliaContext) = (arr.ext,)
Pigeon.getsites(arr::ChunkVector) = (1,)
Pigeon.getname(arr::ChunkVector) = arr.name
Pigeon.make_style(root, ctx::Finch.LowerJuliaContext, node::Access{ChunkVector}) = Finch.ChunkStyle()
function Pigeon.visit!(node::Access{ChunkVector}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle)
    return Access(node.tns.body, node.mode, node.idxs)
end

@testset "Finch.jl" begin

    include("parse.jl")
    include("simplesparsetests.jl")
    include("simplerunlengthtests.jl")
    exit()

    A = VirtualAbstractArray(1, :A, :A)
    B = VirtualAbstractArray(1, :B, :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = ChunkVector(Run(VirtualAbstractArray(0, :A, :A)), Extent(1, 10), :A)
    B = ChunkVector(Run(VirtualAbstractArray(0, :B, :B)), Extent(1, 10), :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = VirtualAbstractArray(1, :A, :A)
    B = ChunkVector(Spike(0, 1), Extent(1, 10), :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = ChunkVector(Spike(VirtualAbstractArray(0, :A, :A1), VirtualAbstractArray(0, :A, :A2)), Extent(1, 10), :A)
    B = ChunkVector(Spike(0, 1), Extent(1, 10), :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = ChunkVector(Spike(VirtualAbstractArray(0, :A, :A1), VirtualAbstractArray(0, :A, :A2)), Extent(1, 10), :A)
    B = ChunkVector(Cases([
        :foobar => Spike(0, 1)
        true => Run(42)
    ]), Extent(1, 10), :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    my_i = gensym(:stream_i0)
    my_i′ = gensym(:stream_i1)
    my_p = gensym(:stream_p)
    A = ChunkVector(
        Thunk(
            preamble = quote
                $my_p = 2
                $my_i = lvl.idx[$my_p]
                $my_i′ = lvl.idx[$my_p + 1]
            end,
            body = Stream(
                step = (ctx, start, stop) -> my_i,
                body = (ctx, start, stop) -> begin
                    Cases([
                        :($my_i == $stop) =>
                            Thunk(
                                body = Spike(
                                    body = 0,
                                    tail = Virtual{Int}(:(lvl.val[$my_i])),
                                ),
                                epilogue = quote
                                    $my_p += 1
                                    $my_i = $my_i′
                                    $my_i′ = lvl.idx[$my_p + 1]
                                end
                            ),
                        :($my_i == $stop) =>
                            Run(
                                body = 0,
                            ),
                    ])
                end,
            )
        ),
        Extent(1, 10), :A)
    
    B = VirtualAbstractArray(1, :B, :B)

    println(lower_julia(@i @loop i B[i] = A[i] + A[i]))

end