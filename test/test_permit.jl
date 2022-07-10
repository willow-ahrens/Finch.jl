@testset "permit" begin

    #=
    A = Finch.Fiber(
        Solid(5,
        Element{0.0}([1, 2, 3, 4, 5])))
    B = Finch.Fiber(
        Solid(2,
        Element{0.0}([10, 20])))
    C = Finch.Fiber(Solid(Element{0.0}()))

    println(@index_code_lowered @loop i C[i] += A[i] + coalesce(B[permit[i]], 0))
    @index @loop i C[i] += A[i] + coalesce(B[permit[i]], 0)
    println(FiberArray(C))
    =#

    A = Finch.Fiber(
        Solid(5,
        Element{0.0}([1, 2, 3, 4, 5])))
    B = Finch.Fiber(
        Solid(2,
        Element{0.0}([1, 1])))
    C = Finch.Fiber(Solid(Element{0.0}()))

    #println(@index_code_lowered @loop i C[i] = coalesce(A[permit[i]], B[offset[5, permit[i]]]))
    #println(@index_code_lowered @loop i C[i] = coalesce(A[permit[i]], B[permit[offset[5, i]]]))
    #@index @loop i C[i] = coalesce(A[permit[i]], B[offset[5, permit[i]]])
    #@index @loop i C[i] = coalesce(A[permit[i]], B[permit[offset[5, i]]])
    #println(FiberArray(C))
    #println(@index_code_lowered @loop j i C[i] += B[j] * coalesce(A[offset[j - 1, permit[i]]], 0))
    #println(@index_code_lowered @loop i j C[i] += B[j] * coalesce(A[offset[i - 1, permit[j]]], 0))
    println(FiberArray(C))

end