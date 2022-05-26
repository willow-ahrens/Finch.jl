@testset "fibers" begin

    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Scalar{0.0}()


    ex = @index_program_instance (@loop j if j == 1 B[] += A[j] end)
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index (@loop j if j == 1 B[] += A[j] end)

    println(B)
    @test B() == 2.0

    @index (@loop j if j == 2 B[] += A[j] end)

    println(B)
    @test B() == 0.0

end