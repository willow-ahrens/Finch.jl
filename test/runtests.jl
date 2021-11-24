using Finch
using Pigeon
using Test
using MacroTools

using Finch: VirtualAbstractArray, Run, Extent

@testset "Finch.jl" begin
    A = VirtualAbstractArray(1, :A, :A)
    B = VirtualAbstractArray(1, :B, :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = Run(access(VirtualAbstractArray(0, :A, :A), Pigeon.Write()), Extent(1, 10))
    B = Run(access(VirtualAbstractArray(0, :B, :B), Pigeon.Read()), Extent(1, 10))
    println(lower_julia(@i @loop i A[i] = B[i]))
end
