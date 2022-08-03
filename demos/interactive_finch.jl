using MatrixDepot
using Finch
using BenchmarkTools
using SparseArrays
using LinearAlgebra
using Cthulhu
using Profile

n = 10_000
p = 0.1
q = 0.1

A = fiber(sprand(n, p))
B = fiber(sprand(n, q))
C = similar(A)


F = fiber([1, 1, 1, 1, 1])

@index @loop i j C[i] += (A[i] != 0) * coalesce(A[permit[offset[3-i, j]]], 0) * coalesce(F[permit[j]], 0)
@index_code @loop i j C[i] += (A[i] != 0) * coalesce(A[permit[offset[3-i, j]]], 0) * coalesce(F[permit[j]], 0)

@index_code @loop i C[i] = A[i] + B[i]
@index @loop i C[i] = A[i] + B[i]

@index_code @loop i C[i] = A[i::gallop] + B[i]
@index @loop i C[i] = A[i::gallop] + B[i]

@index_code @loop i C[i] = A[i] + B[i::gallop]
@index @loop i C[i] = A[i] + B[i::gallop]

@index_code @loop i C[i] = A[i::gallop] + B[i::gallop]
@index @loop i C[i] = A[i::gallop] + B[i::gallop]

D = Scalar{0.0}()

@index_code @loop i D[] += A[i] * B[i]
@index @loop i D[] += A[i] * B[i]

@index_code @loop i D[] += A[i::gallop] * B[i]
@index @loop i D[] += A[i::gallop] * B[i]

@index_code @loop i D[] += A[i] * B[i::gallop]
@index @loop i D[] += A[i] * B[i::gallop]

@index_code @loop i D[] += A[i::gallop] * B[i::gallop]
@index @loop i D[] += A[i::gallop] * B[i::gallop]

@index_code @loop i C[i] = coalesce(A[permit[i]], B[permit[offset[$n, i]]])
@index @loop i C[i] = coalesce(A[permit[i]], B[permit[offset[$n, i]]])

R = @f(s(r(0.0)))
copyto!(@f(s(r(0.0))), [ones(4, 4) zeros(4, 4); zeros(4, 4) ones(4, 4)])
b = @f(s(e(0.0)))
@index @loop i j b[i] += a[i, j]