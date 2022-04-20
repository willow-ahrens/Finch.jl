using Finch
using Test
using MacroTools

include("matrices.jl")

using Finch: VirtualAbstractArray, Run, Spike, Extent, Scalar, Cases, Stepper, Jumper, AcceptRun, AcceptSpike, Thunk, Phase, Pipeline, Leaf, Simplify
using Finch: @i, @index_program_instance, execute, execute_code_lowered, start, stop
using Finch: getname, Virtual

@testset "Finch.jl" begin
    println("B[i] = A(ds)[j, i]")
    A = Fiber(
        Solid(4,
        HollowList(10, [1, 6, 9, 9, 10], [1, 3, 5, 7, 9, 3, 5, 8, 3],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0, 1.0, 1.0, 1.0, 7.0]))))
    B = Fiber(
        HollowByte(4,
        Element{0.0}()))

    ex = @index_program_instance @loop j i B[i] += A[j, i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i j B[j] += A[i, j]

    @test B.lvl.srt[1:6] == [(1, 1), (1, 3), (1, 5), (1, 7), (1, 8), (1, 9)]
    exit()

    include("test_ssa.jl")
    include("parse.jl")
    include("fibers.jl")
    include("simplevectors.jl")
    include("kernels.jl")

end