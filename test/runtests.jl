using Finch
using Test
using MacroTools

include("matrices.jl")

using Finch: VirtualAbstractArray, Run, Spike, Extent, Scalar, Cases, Stepper, Jumper, AcceptRun, AcceptSpike, Thunk, Phase, Pipeline, Leaf, Simplify
using Finch: @i, @index_program_instance, execute, execute_code_lowered, start, stop
using Finch: getname, Virtual

@testset "Finch.jl" begin

    for (mtx, A_ref) in matrices
        A_ref = SparseMatrixCSC(A_ref)
        m, n = size(A_ref)
        if m == n
            println("B(ds)[i, j] = w[j] where w[j] += A(ds)[i, k] * A(ds)(k, j)")
            A = Finch.Fiber(
                Solid(n,
                HollowList(m, A_ref.colptr, A_ref.rowval,
                Element{0.0}(A_ref.nzval))))
            B = Fiber(
                Solid(0,
                HollowList(0,
                Element{0.0}())))
            w = Fiber(
                HollowByte(m, #TODO
                Element{0.0}()))

            ex = @index_program_instance @loop i ((@loop j B[i, j] = w[j]) where (@loop k j w[j] = A[i, k] * A[k, j]))
            display(execute_code_lowered(:ex, typeof(ex)))
            println()

            @index @loop i ((@loop j B[i, j] = w[j]) where (@loop k j w[j] = A[i, k] * A[k, j]))
        end
    end

    include("test_ssa.jl")
    include("parse.jl")
    include("fibers.jl")
    include("simplevectors.jl")
    include("kernels.jl")
end