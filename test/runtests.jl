using Finch
using Pigeon
using Test
using MacroTools

using Finch: VirtualAbstractArray, Run, Spike, Extent, Scalar, Cases

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
    A = VirtualAbstractArray(1, :A, :A)
    B = VirtualAbstractArray(1, :B, :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = ChunkVector(Run(VirtualAbstractArray(0, :A, :A), Extent(1, 10)), Extent(1, 10), :A)
    B = ChunkVector(Run(VirtualAbstractArray(0, :B, :B), Extent(1, 10)), Extent(1, 10), :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = VirtualAbstractArray(1, :A, :A)
    B = ChunkVector(Spike(Run(0, Extent(1, 9)), 1, Extent(1, 10)), Extent(1, 10), :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = ChunkVector(Spike(Run(VirtualAbstractArray(0, :A, :A1), Extent(1, 9)), VirtualAbstractArray(0, :A, :A2), Extent(1, 10)), Extent(1, 10), :A)
    B = ChunkVector(Spike(Run(0, Extent(1, 9)), 1, Extent(1, 10)), Extent(1, 10), :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = ChunkVector(Spike(Run(VirtualAbstractArray(0, :A, :A1), Extent(1, 9)), VirtualAbstractArray(0, :A, :A2), Extent(1, 10)), Extent(1, 10), :A)
    B = ChunkVector(Cases([
        :foobar => Spike(Run(0, Extent(1, 9)), 1, Extent(1, 10))
        true => Run(42, Extent(1, 10))
    ]), Extent(1, 10), :B)
    println(lower_julia(@i @loop i A[i] = B[i]))
end
