@testset "permit" begin
    A = Finch.Fiber(
        Repeat(10, [1, 7], [1, 3, 5, 7, 9, 10],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0, 7.0])))

    @test diff("repeat_display.txt", display(A))

    @test FiberArray(A) == [2.0, 3.0, 3.0, 4.0, 4.0, 5.0, 5.0, 6.0, 6.0, 7.0]

    B = f"s"(0.0)

    display(@index_code @loop i B[i] = A[i])
    @index @loop i B[i] = A[i]
    @test FiberArray(B) == [2.0, 3.0, 3.0, 4.0, 4.0, 5.0, 5.0, 6.0, 6.0, 7.0]
    @test diff("s_equals_r", @index_code @loop i B[i] = A[i])
end