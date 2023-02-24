# Finch.jl

#[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://willow-ahrens.github.io/Finch.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://willow-ahrens.github.io/Finch.jl/dev)
[![Build Status](https://github.com/willow-ahrens/Finch.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/willow-ahrens/Finch.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/willow-ahrens/Finch.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/willow-ahrens/Finch.jl)

Finch is an adaptable Julia-to-Julia compiler for loop nests over sparse or structured
multidimensional arrays. In addition to supporting [sparse
arrays](https://en.wikipedia.org/wiki/Sparse_matrix), Finch can also handle
[custom operators and fill values other than zero](https://en.wikipedia.org/wiki/GraphBLAS),
[runs](https://en.wikipedia.org/wiki/Run-length_encoding) of repeated values, or
even [special
structures](https://en.wikipedia.org/wiki/Sparse_matrix#Special_structure) such
as clustered nonzeros or triangular patterns.

Finch supports loops and reductions over pointwise expressions on arrays,
incorporating arbitrary element types and operators. Users can add rewrite rules
to inform the compiler about any special properties or optimizations that might
apply to the situation at hand. You can even modify indexing expressions to 
express sparse convolution, or to describe windows into structured
arrays.

Finch is very experimental, the interfaces are subject to change.

We're always trying to make Finch easier to use! Here's a column-major SpMV:

```julia
x = @fiber(d(e(0.0)), rand(42));
A = @fiber(d(sl(e(0.0))), sprand(42, 42, 0.1));
y = @fiber(d(e(0.0)));
@finch @loop j i y[i] += A[i, j] * x[j];
```

Array formats in Finch are described recursively mode by mode, using a
relaxation of TACO's [level format
abstraction](https://dl.acm.org/doi/pdf/10.1145/3276493).  Semantically, an
array in Finch can be understood as a tree, where each level in the tree
corresponds to a dimension and each edge corresponds to an index. In addition
to choosing a data storage format, Finch allows users to choose an access **protocol**,
determining which strategy should be used to traverse the array.

The input to Finch is an extended form of [concrete index
notation](https://arxiv.org/abs/1802.10574). In addition to simple loops and
pointwise expressions, Finch supports the where, multi, and sieve statements.
The where statement describes temporary tensors, the multi statements describe
computations with multiple outputs, and the sieve statement filters out
iterations.

At it's heart, Finch is powered by a new domain specific language for
coiteration, breaking structured iterators into control flow units we call
**Looplets**. Looplets are lowered progressively, leaving several opportunities to
rewrite and simplify intermediate expressions.

The technologies enabling Finch are described in our [manuscript](https://arxiv.org/abs/2209.05250).
