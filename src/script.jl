using SparseArrays
using FiberArrays

A = sprand(10, 20, 0.5)

bottom = ScalarLevel(A.nzval)
middle = SparseLevel{Float64, Int, 1}(20, 10, A.colptr, A.rowval, bottom)
top = DenseLevel{Float64, Int, 2}(1, 20, middle)

println(top[1])