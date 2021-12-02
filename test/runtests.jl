using Finch
using Pigeon
using Test
using MacroTools

using Finch: VirtualAbstractArray, Run, Spike, Extent, Scalar

@testset "Finch.jl" begin
    A = VirtualAbstractArray(1, :A, :A)
    B = VirtualAbstractArray(1, :B, :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = Run(VirtualAbstractArray(0, :A, :A), Extent(1, 10))
    B = Run(VirtualAbstractArray(0, :B, :B), Extent(1, 10))
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = VirtualAbstractArray(1, :A, :A)
    B = Spike(Run(0, Extent(1, 9)), 1, Extent(1, 10))
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = Spike(Run(VirtualAbstractArray(0, :A, :A1), Extent(1, 9)), VirtualAbstractArray(0, :A, :A2), Extent(1, 10))
    B = Spike(Run(0, Extent(1, 9)), 1, Extent(1, 10))
    println(lower_julia(@i @loop i A[i] = B[i]))
end
