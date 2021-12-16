include("simplerunlength.jl")
@testset "simplerunlength" begin
    println()
    A = SimpleRunLength{Float64, Int, :A}([1, 3, 5, 7, 9, 10], [2.0, 3.0, 4.0, 5.0, 6.0])
    B = SimpleRunLength{Float64, Int, :B}([1, 5, 8, 10], [1.0, 2.0, 3.0])
    println(A)
    println(B)
    C = SimpleRunLength{Float64, Int, :C}([1, 10], [0.0])
    ex = @I @loop i C[i] += A[i] + B[i]
    display(lower_julia(virtualize(:ex, typeof(ex))))
    println()
    execute(ex)
    println(C)
end