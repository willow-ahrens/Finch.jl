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
        Element{0.0}([10, 20])))
    C = Finch.Fiber(Solid(Element{0.0}()))

    println(@index_code_lowered @loop i C[i] = coalesce(A[permit[i]], B[$(Finch.StaticOffset(shift=5))[permit[i]]])) #TODO get rid of + and 0 and also add in the right offset syntax
    #@index @loop i C[i] += coalesce(A[permit[i]], B[permit[offset[5, i]]], 0)
    @index @loop i C[i] += coalesce(A[permit[i]], B[$(Finch.StaticOffset(shift=5))[permit[i]]], 0)
    println(FiberArray(C))
    #println(@index_code_lowered @loop i j C[i] += A[offset[j - 1, i]] * coalesce(B[permit[j]], 0))
    #println(FiberArray(C))
end