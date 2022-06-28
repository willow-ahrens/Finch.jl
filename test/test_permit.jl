@testset "permit" begin

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

    A = Finch.Fiber(
        Solid(5,
        Element{0.0}([1, 2, 3, 4, 5])))
    B = Finch.Fiber(
        Solid(2,
        Element{0.0}([10, 20])))
    C = Finch.Fiber(Solid(Element{0.0}()))

    println(@index_code_lowered @loop i C[i] += A[i] + coalesce(B[permit[offset[5, i]]], 0))
    @index @loop i C[i] += A[i] + coalesce(B[permit[offset[5, i]]], 0)
    println(FiberArray(C))
end