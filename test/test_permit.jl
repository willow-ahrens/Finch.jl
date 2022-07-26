@testset "permit" begin

    #=
    A = Finch.Fiber(
        Solid(5,
        Element{0.0}([1, 2, 3, 4, 5])))
    B = Finch.Fiber(
        Solid(2,
        Element{0.0}([10, 20])))
    C = Finch.Fiber(Solid(Element{0.0}()))

    println(@index_code @loop i C[i] += A[i] + coalesce(B[permit[i]], 0))
    @index @loop i C[i] += A[i] + coalesce(B[permit[i]], 0)
    println(FiberArray(C))

    A = Finch.Fiber(
        Solid(5,
        Element{0.0}([1, 2, 3, 4, 5])))
    B = Finch.Fiber(
        Solid(2,
        Element{0.0}([1, 1])))
    C = Finch.Fiber(Solid(Element{0.0}()))
    =#

    A_ref = sprand(10, 0.5); B_ref = sprand(10, 0.5); C_ref = vcat(A_ref, B_ref)
    A = fiber(A_ref); B = fiber(B_ref); C = f"l"(0.0)
    println(@index_code @loop i C[i] = coalesce(A[permit[i]], B[permit[offset[10, i]]]))
    @index @loop i C[i] = coalesce(A[permit[i]], B[permit[offset[10, i]]])
    
    println(@index_code @loop i C[i] = coalesce(A[permit[i]], B[offset[10, permit[i]]]))
    @index @loop i C[i] = coalesce(A[permit[i]], B[offset[10, permit[i]]])
    @test FiberArray(C) == C_ref

    F = fiber([1,1,1,1,1])

    println(@index_code @loop i j C[i] += (A[i] != 0) * coalesce(A[permit[offset[i - 3, j]]], 0) * F[j])
    @index @loop i j C[i] += (A[i] != 0) * coalesce(A[permit[offset[i - 3, j]]], 0) * F[j]
    #println(@index_code @loop i C[i] = coalesce(A[permit[i]], B[offset[5, permit[i]]]))
    #println(@index_code @loop i C[i] = coalesce(A[permit[i]], B[permit[offset[5, i]]]))
    #@index @loop i C[i] = coalesce(A[permit[i]], B[offset[5, permit[i]]])
    #@index @loop i C[i] = coalesce(A[permit[i]], B[permit[offset[5, i]]])
    #println(FiberArray(C))
    #println(@index_code @loop j i C[i] += B[j] * coalesce(A[offset[j - 1, permit[i]]], 0))
    #println(@index_code @loop i j C[i] += B[j] * coalesce(A[offset[i - 1, permit[j]]], 0))
    #println(@index_code @loop i j C[i] += B[j] * coalesce(A[offset[i - 1, permit[j]]], 0) * (A[i] != 0))
    println(@index_code @loop i C[i] = A[window[2, 4, i]])
    @index @loop i C[i] = A[window[2, 4, i]]
    println(FiberArray(C))

end