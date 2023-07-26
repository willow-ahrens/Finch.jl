using Finch
using SparseArrays
using MatrixDepot
using BenchmarkTools

A = @fiber(d(sl(e(0.0))), SparseMatrixCSC(matrixdepot("Boeing/ct20stif")))
(m, n) = size(A)
x = @fiber(d(e(0.0)), randn(m))
y = @fiber(d(e(0.0)))

println("serial")
@btime begin
    (A, x, y) = $((A, x, y))
    Finch.@finch begin
        y .= 0
        for j = _
            for i = _
                y[j] += A[walk(i), j] * x[i]
            end
        end
    end
end


println("parallel")
@btime begin
    (A, x, y) = $(A, x, y)
    Finch.@finch begin
        y .= 0
        for j = parallel(_)
            for i = _
                y[j] += A[walk(i), j] * x[i]
            end
        end
    end
end