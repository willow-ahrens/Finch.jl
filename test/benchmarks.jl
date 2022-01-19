using MatrixDepot
using Finch
using BenchmarkTools
using SparseArrays
using Cthulhu

function spmv(mtx)
    println("spmv: $mtx")
    A_ref = SparseMatrixCSC(mdopen(mtx).A)
    (m, n) = size(A_ref)
    A = Finch.Fiber{Float64}((
        SolidLevel(m),
        HollowLevel{0.0, Float64}(n, A_ref.colptr, A_ref.rowval),
        ScalarLevel{0.0, Float64}(A_ref.nzval),
    ))
    y = Finch.Fiber{Float64}((
        SolidLevel(m),
        ScalarLevel{0.0, Float64}(zeros(m)),
    ))
    x = Finch.Fiber{Float64}((
        SolidLevel(n),
        ScalarLevel{0.0, Float64}(rand(n)),
    ))
    ex = @I @loop i j y[i] += A[i, j] * x[j]
    display(Finch.execute_code_lowered(:ex, typeof(ex)))
    execute(ex)
    println()
    #println(@descend execute(ex))

    println("Finch:")
    @btime execute($ex)

    println("Julia:")
    x_ref = rand(n)
    @btime $A_ref * $x_ref
end

spmv("Boeing/ct20stif")