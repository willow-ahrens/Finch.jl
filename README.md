# Finch.jl

| **Documentation**                                                               | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://willow-ahrens.github.io/Finch.jl/stable) [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://willow-ahrens.github.io/Finch.jl/dev) | [![Build Status](https://github.com/willow-ahrens/Finch.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/willow-ahrens/Finch.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Coverage](https://codecov.io/gh/willow-ahrens/Finch.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/willow-ahrens/Finch.jl) |

Finch is a adaptable Julia-to-Julia compiler for loop nests over sparse or structured
multidimensional arrays. In addition to supporting [sparse
arrays](https://en.wikipedia.org/wiki/Sparse_matrix), Finch can also handle
[custom operators and fill values other than zero](https://en.wikipedia.org/wiki/GraphBLAS),
[runs](https://en.wikipedia.org/wiki/Run-length_encoding) of repeated values, or
even [special
structures](https://en.wikipedia.org/wiki/Sparse_matrix#Special_structure) such
as clustered nonzeros or triangular patterns.

Finch allows you to write `for`-loops as if they are dense, but compile them to be
sparse! The compiler takes care of applying rules like `x * 0 => 0` and the like
to avoid redundant computation.  Finch also supports `if`-statements and custom
user types and functions.  Users can add rewrite rules to inform the compiler
about any special user-defined properties or optimizations.  You can even modify
indexing expressions to express sparse convolution, or to describe windows into
structured arrays.

As an example, here's a program which calculates the minimum, maximum, sum, and
variance of a sparse vector, reading the vector only once, and only reading
nonzero values:

```julia
X = @fiber(sl(e(0.0)), sprand(10, 1))
x = Scalar(0.0)
x_min = Scalar(Inf)
x_max = Scalar(-Inf)
x_sum = Scalar(0.0)
x_var = Scalar(0.0)
@finch begin
    for i = _
        x .= 0
        x[] = X[i]
        x_min[] <<min>>= x[]
        x_max[] <<max>>= x[]
        x_sum[] += x[]
        x_var[] += x[] * x[]
    end
```

Array formats in Finch are described recursively mode by mode.  Semantically, an
array in Finch can be understood as a tree, where each level in the tree
corresponds to a dimension and each edge corresponds to an index. For example,
`@fiber(d(sl(e(0.0))))` constructs a `Float64` CSC-format sparse matrix, and 
`@fiber(sl(sl(e(0.0))))` constructs a DCSC-format hypersparse matrix. As another
example, here's a column-major sparse matrix-vector multiply:

```julia
x = @fiber(d(e(0.0)), rand(42));
A = @fiber(d(sl(e(0.0))), sprand(42, 42, 0.1));
y = @fiber(d(e(0.0)));
@finch begin
    y .= 0
    for j=_, i=_
        y[i] += A[i, j] * x[j]
    end
end
```

At it's heart, Finch is powered by a new domain specific language for
coiteration, breaking structured iterators into control flow units we call
**Looplets**. Looplets are lowered progressively with
several stages for rewriting and simplification.

The technologies enabling Finch are described in our [manuscript](https://arxiv.org/abs/2209.05250).
