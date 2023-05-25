```@meta
CurrentModule = Finch
```

# The three big strategies for matmul

Matrix multiplication is a fundamental operation in linear algebra. It takes two
input matrices, `A` and `B`, and produces the output matrix `C_ij = A_ik B_kj`.
The three main algorithms for matrix multiplication correspond to three
different loop orderings over `i`, `j`, and `k`. The inner
products algorithm iterates over `k` in the inner loop, calculating each entry
of `C` as a dot product of a row of `A` and a column of `B`. The outer products
algorithm iterates over `k` in the outer loop, calculating `C` as the sum of the
outer products of the columns of `A` and the rows of `B`. Gustavson's algorithm
iterates over `k` in the middle loop, calculating each column of `C` as the sum of
columns of `A` scaled by the entries in each row of `B`.

# Inner Products

The inner products algorithm is the simplest. However, since the algorithm
iterates over each `i` and `j`, regardless of whether that row and column share
nonzeros, it's not asymptotically optimal. For example, even if `C` ends up
entirely zero, inner products will still iterate over all `i`, `j`, and `k`. It
performs better when `A` and `B` are very sparse and we expect the output to be
more dense. 

```jldoctest example1; setup=:(using Finch)
function spgemm_inner(A, B)
    # determine a suitable zero value for the output
    z = default(A) * default(B) + false

    # construct the output in CSC format
    C = @fiber d(sl(e(z)))

    # transpose A
    w = @fiber sh{2}(e(z))
    AT = @fiber d(sl(e(z)))
    @finch (w .= 0; @loop k i w[k, i] = A[i, k])
    @finch (AT .= 0; @loop i k AT[k, i] = w[k, i])

    # perform the inner products algorithm
    @finch (C .= 0; @loop j i k C[i, j] += AT[k, i] * B[k, j])
    return C
end
```

# Outer Products




