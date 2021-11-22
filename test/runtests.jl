using Finch
using Pigeon
using Test
using MacroTools

using Finch: VirtualAbstractArray

@testset "Finch.jl" begin
    A = VirtualAbstractArray(1, :A, :A)
    B = VirtualAbstractArray(1, :B, :B)
    println(lower_julia(@i @loop i A[i] = B[i]))
end
