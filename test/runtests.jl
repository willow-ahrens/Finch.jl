using Finch
using Pigeon
using Test
using MacroTools

using Finch: VirtualAbstractArray, Run, Spike, Extent, Scalar, Cases, Stream, AcceptRun, AcceptSpike, Thunk

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

    @testset "simplerun plus simplesparse" begin
        println()
        A = SimpleRunLength{Float64, Int}([1, 3, 5, 7, 9, 10], [2.0, 3.0, 4.0, 5.0, 6.0, 7.0])
        B = SimpleSparseVector{0.0, Float64, Int}([2, 5, 8, 11], [1.0, 1.0, 1.0])
        println(A)
        println(B)
        C = SimpleRunLength{Float64, Int}([1, 10], [0.0])
        ex = @I @loop i C[i] += A[i] + B[i]
        println(typeof(ex))
        display(lower_julia(virtualize(:ex, typeof(ex))))
        println()
        execute(ex)
        println(C)
    end

    @testset "simplerun plus vec" begin
        println()
        A = SimpleRunLength{Float64, Int}([1, 3, 5, 7, 9, 10], [2.0, 3.0, 4.0, 5.0, 6.0, 7.0])
        B = ones(10)
        println(A)
        println(B)
        C = SimpleRunLength{Float64, Int}([1, 10], [0.0])
        ex = @I @loop i C[i] += A[i] + B[i]
        println(typeof(ex))
        display(lower_julia(virtualize(:ex, typeof(ex))))
        println()
        execute(ex)
        println(C)
    end
end