# Finch.jl

[docs]:https://willow-ahrens.github.io/Finch.jl/stable
[ddocs]:https://willow-ahrens.github.io/Finch.jl/dev
[ci]:https://github.com/willow-ahrens/Finch.jl/actions/workflows/CI.yml?query=branch%3Amain
[cov]:https://codecov.io/gh/willow-ahrens/Finch.jl
[tool]:https://mybinder.org/v2/gh/willow-ahrens/Finch.jl/gh-pages?labpath=dev%2Finteractive.ipynb

[docs_ico]:https://img.shields.io/badge/docs-stable-blue.svg
[ddocs_ico]:https://img.shields.io/badge/docs-dev-blue.svg
[ci_ico]:https://github.com/willow-ahrens/Finch.jl/actions/workflows/CI.yml/badge.svg?branch=main
[cov_ico]:https://codecov.io/gh/willow-ahrens/Finch.jl/branch/main/graph/badge.svg
[tool_ico]:https://mybinder.org/badge_logo.svg

| **Documentation**                             | **Build Status**                      | **Try It Online!**    |
|:---------------------------------------------:|:-------------------------------------:|:---------------------:|
| [![][docs_ico]][docs] [![][ddocs_ico]][ddocs] | [![][ci_ico]][ci] [![][cov_ico]][cov] | [![][tool_ico]][tool] |

Finch is a adaptable Julia-to-Julia compiler for loop nests over sparse or
structured multidimensional arrays.  Finch allows you to write `for`-loops as if
they are dense, but compile them to be sparse! Finch compiles the loops based on
the structure of the data! The compiler takes care of applying rules like `x * 0
=> 0` and the like to avoid redundant computation. 

| **Features**                             | **Syntax (e.g. ...)** |
|:---------------------------------------------:|:------------------:|
| Supports Major Sparse Formats (CSC, CSF, COO, Hash, Bytemap, Dense Triangular)! |  `Fiber!(Dense(SparseList(Element(0.0)))`|
| Supports RLE (Run Length Encoding) and Sparse RLE! |  `Fiber!(Dense(RepeatRLE(0.0)))`|
| Supports Arbitrary Fill Values Other Than Zero! |  `Fiber!(SparseList(Element(1.0)))`|
| Supports Arbitrary Operators! |  `x[] <<min>>= y[i] + z[i]`|
| Supports Multiple Outputs! |  `x[] <<min>>= y; z[] <<max>>=y`|
| Supports Multicore Parallelism! |  `for i = parallel(1:100)`|
| Supports `if`! |  `if dist[] < best_dist[]`|
| Supports Convolution! |  `A[i + j]`|
| Supports Concatenation! |  `coalesce(A[~i], B[~i - size(A, 1)])`|

In addition to supporting [sparse
arrays](https://en.wikipedia.org/wiki/Sparse_matrix), Finch can also handle
[custom operators and fill values other than
zero](https://en.wikipedia.org/wiki/GraphBLAS),
[runs](https://en.wikipedia.org/wiki/Run-length_encoding) of repeated values, or
even [special
structures](https://en.wikipedia.org/wiki/Sparse_matrix#Special_structure) such
as clustered nonzeros or triangular patterns. Finch also supports
`if`-statements and custom user types and functions.  Users can add rewrite
rules to inform the compiler about any special user-defined properties or
optimizations.  You can even modify indexing expressions to express sparse
convolution, or to describe windows into structured arrays.


As an example, here's a program which calculates the minimum, maximum, sum, and
variance of a sparse vector, reading the vector only once, and only reading
nonzero values:

````julia
using Finch

X = Fiber!(SparseList(Element(0.0)), fsprand((10,), 0.5))
x_min = Scalar(Inf)
x_max = Scalar(-Inf)
x_sum = Scalar(0.0)
x_var = Scalar(0.0)
@finch begin
    for i = _
        x = X[i]
        x_min[] <<min>>= x
        x_max[] <<max>>= x
        x_sum[] += x
        x_var[] += x * x
    end
end;
````

Array formats in Finch are described recursively mode by mode.  Semantically, an
array in Finch can be understood as a tree, where each level in the tree
corresponds to a dimension and each edge corresponds to an index. For example,
`Fiber!(Dense(SparseList(Element(0.0))))` constructs a `Float64` CSC-format sparse matrix, and
`Fiber!(SparseList(SparseList(Element(0.0))))` constructs a DCSC-format hypersparse matrix. As another
example, here's a column-major sparse matrix-vector multiply:

````julia
x = Fiber!(Dense(Element(0.0)), rand(42));
A = Fiber!(Dense(SparseList(Element(0.0))), fsprand((42, 42), 0.1));
y = Fiber!(Dense(Element(0.0)));
@finch begin
    y .= 0
    for j=_, i=_
        y[i] += A[i, j] * x[j]
    end
end;
````

At it's heart, Finch is powered by a new domain specific language for
coiteration, breaking structured iterators into control flow units we call
**Looplets**. Looplets are lowered progressively with
several stages for rewriting and simplification.

The technologies enabling Finch are described in our [manuscript](https://doi.org/10.1145/3579990.3580020).

# Installation

At the [Julia](https://julialang.org/downloads/) REPL, install the latest stable version by running:

````julia
julia> using Pkg; Pkg.add("Finch")
````

