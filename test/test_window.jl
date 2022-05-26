@testset "reindexing" begin
    println("dense = reindex")
    A = collect(1:10)
    B = zeros(10)
    ex = @index_program_instance @loop i B[i] = select[5, i], A[i]

    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i B[i] = ifelse(select[5, i], A[i], 0)

    println(B)

    @test B == [0.0, 0.0, 0.0, 0.0, 5.0, 0.0, 0.0, 0.0, 0.0, 0.0]
end