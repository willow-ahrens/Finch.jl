using Finch
using SparseArrays
using LinearAlgebra

n = m = 100
p = q = 0.1

A_ref = sprand(n, p)
B_ref = sprand(n, q)
I, V = findnz(A_ref)
J, W = findnz(B_ref)
A = Fiber(
    HollowList(n, [1, length(I) + 1], I,
    Element{0.0, Float64}(V))
)
B = Fiber(
    HollowList(n, [1, length(J) + 1], J,
    Element{0.0, Float64}(W))
)
C = Fiber(
    HollowList(
    Element{0.0, Float64}())
)
D = Fiber(
    HollowList(
    Element{0.0, Float64}())
)
a = Fiber(Element{0.0, Float64}(zeros(1)))
b = Fiber(Element{0.0, Float64}(zeros(1)))
