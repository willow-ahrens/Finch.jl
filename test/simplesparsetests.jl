include("simplesparsevector.jl")
@testset "simplesparsevector" begin
    A = SimpleSparseVector{Float64, Int, 0.0}([1, 3, 5, 7, 9, 10], [2.0, 3.0, 4.0, 5.0, 6.0, 7.0])
    B = SimpleSparseVector{Float64, Int, 0.0}([1, 5, 8, 10], [1.0, 1.0, 1.0])
    println(A)
    println(B)
    C = zeros(9)
    ex = @I @loop i C[i] += A[i] + B[i]
    display(lower_julia(virtualize(:ex, typeof(ex))))
    println()
    execute(ex)
    println(C)
end