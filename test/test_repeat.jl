@testset "permit" begin
    A = Finch.Fiber(
        Repeat{0.0}(10, [1, 7], [1, 3, 5, 7, 9, 10], [2.0, 3.0, 4.0, 5.0, 6.0, 7.0]))

    @test diff("repeat_display.txt", display(A))

    @test FiberArray(A) == [2.0, 3.0, 3.0, 4.0, 4.0, 5.0, 5.0, 6.0, 6.0, 7.0]

    B = f"s"(0.0)

    @index @loop i B[i] = A[i]
    @test FiberArray(B) == [2.0, 3.0, 3.0, 4.0, 4.0, 5.0, 5.0, 6.0, 6.0, 7.0]

    C = [1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3]

    display(@index_code @loop i A[i] = C[i])
    println()
    @index @loop i A[i] = C[i]

    display(A)
    println()

    D = fiber(sprand(10, 0.5))
    display(@index_code @loop i A[i] = D[i])
    println()
    @index @loop i A[i] = D[i]

    display(A)
    println()
end