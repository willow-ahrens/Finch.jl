include("simplesparsevector.jl")
@testset "simplesparsevector" begin
    A = SimpleSparseVector{Float64, Int, 0.0, :A}([1, 3, 5, 7, 9, 11], [2.0, 3.0, 4.0, 5.0, 6.0])
    B = SimpleSparseVector{Float64, Int, 0.0, :B}([2, 5, 8, 11], [1.0, 1.0, 1.0])
    println(A)
    println(B)
    C = zeros(10)
    ex = @I @loop i C[i] += A[i] + B[i]
    println(typeof(ex))
    display(lower_julia(virtualize(:ex, typeof(ex))))
    println()
    execute(ex)
    println(C)

    C = SimpleSparseVector{Float64, Int, 0.0, :c}([11], [])

    ex = @I @loop i C[i] += A[i] + B[i]
    println(typeof(ex))
    display(lower_julia(virtualize(:ex, typeof(ex))))
    println()
    execute(ex)
    println(C)
end