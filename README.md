# Finch.jl: Simplifying Sparse and Structured Array Programming

[docs]:https://willow-ahrens.github.io/Finch.jl/stable
[ddocs]:https://willow-ahrens.github.io/Finch.jl/dev
[ci]:https://github.com/willow-ahrens/Finch.jl/actions/workflows/CI.yml?query=branch%3Amain
[cov]:https://codecov.io/gh/willow-ahrens/Finch.jl
[example]:https://github.com/willow-ahrens/Finch.jl/tree/main/docs/examples

[docs_ico]:https://img.shields.io/badge/docs-stable-blue.svg
[ddocs_ico]:https://img.shields.io/badge/docs-dev-blue.svg
[ci_ico]:https://github.com/willow-ahrens/Finch.jl/actions/workflows/CI.yml/badge.svg?branch=main
[cov_ico]:https://codecov.io/gh/willow-ahrens/Finch.jl/branch/main/graph/badge.svg
[example_ico]:https://img.shields.io/badge/examples-docs%2Fexamples-blue.svg

| **Documentation**                             | **Build Status**                      | **Examples**    |
|:---------------------------------------------:|:-------------------------------------:|:---------------------:|
| [![][docs_ico]][docs] [![][ddocs_ico]][ddocs] | [![][ci_ico]][ci] [![][cov_ico]][cov] | [![][example_ico]][example] |

Finch is a cutting-edge Julia-to-Julia compiler specially designed for optimizing loop nests over sparse or structured multidimensional arrays. Finch empowers users to write conventional `for` loops which the compiler transforms behind-the-scenes into their sparse counterparts.

## Key Features

- **Ease of Writing**: Maintain readable, dense loop structures in your code, and let Finch handle the complexities of sparse data manipulation.
- **Smart Compilation**: Finch’s compiler is intuitive and modular, applying optimizations such as constant propagation and term rewriting. Rules like `x * 0 => 0` eliminate unnecessary computations in sparse code automatically.
- **Wide Format Support**: Seamlessly works with major sparse formats (CSC, CSF, COO, Hash, Bytemap, Dense Triangular) and unique structures like Run Length Encoding or user-defined background (zero) values.
- **Enhanced Control Structures**: Introduces flexibility in computations by supporting conditionals, multiple outputs, and even user-defined types and functions.

### Comprebhensive Sparse Formats

Finch supports a wide variety of array structure beyond sparsity. Whether you're dealing with [custom background (zero) values](https://en.wikipedia.org/wiki/GraphBLAS), [run-length encoding](https://en.wikipedia.org/wiki/Run-length_encoding), or matrices with [special structures](https://en.wikipedia.org/wiki/Sparse_matrix#Special_structure) like banded or triangular matrices, Finch’s compiler can understand and optimize various data patterns and computational rules to adapt to the structure of data.

### Supported Syntax and Structures

| Feature/Structure | Example Usage |
|-------------------|---------------|
| Major Sparse Formats and Structured Arrays |  `A = Fiber!(Dense(SparseList(Element(0.0)))`|
| Background Values Other Than Zero |  `B = Fiber!(SparseList(Element(1.0)))`|
| Broadcasts and Reductions |  `sum(A .* B)`|
| Custom Operators |  `x[] <<min>>= y[i] + z[i]`|
| Multiple Outputs |  `x[] <<min>>= y[i]; z[] <<max>>=y[i]`|
| Multicore Parallelism |  `for i = parallel(1:100)`|
| Conditionals |  `if dist[] < best_dist[]`|
| Affine Indexing (e.g. Convolution) |  `A[i + j]`|

## Who Should Use Finch.jl?

### Sparse Kernel Developers:
If you often find yourself needing to write sparse code for unusual or specific problems that don't have existing library solutions, Finch.jl is for you. Finch lets you outline a high-level plan and then compiles it into efficient code, making your task much easier.

### Custom Array Enthusiasts:
If you're trying to implement a new array type (e.g. blocked, padded, ragged, etc...), Finch can help. You can use the Finch tensor interface to describe the structure of the array, and Finch will take care of creating a full implementation. This includes functionalities like getindex, map, reduce, and more, all of which will work inside other Finch kernels.

### Users Seeking Convenience for Sparse Operations:
If you need flexible and convenient support for sparse array operations, Finch.jl may be a good choice. The formats in Finch can adapt to many use cases, and it supports high-level commands like broadcast and reduce. By understanding how Finch generates implementations, you can get decent performance for a variety of problems.

Note: Finch is currently optimized for sparse code and does not implement traditional dense optimizations. We are currently adding these features, but if you need dense performance, you may want to look at [LoopVectorization.jl](https://github.com/JuliaSIMD/LoopVectorization.jl) [Tullio.jl](https://github.com/mcabbott/Tullio.jl) or [JuliaGPU](https://github.com/JuliaGPU)

## Quick Start: Examples

### Calculating Sparse Vector Statistics

Below is a Julia program using Finch to compute the minimum, maximum, sum, and variance of a sparse vector. This program efficiently reads the vector once, focusing only on nonzero values.

```julia
using Finch

X = Fiber!(SparseList(Element(0.0)), fsprand((10,), 0.5))
x_min = Scalar(Inf)
x_max = Scalar(-Inf)
x_sum = Scalar(0.0)
x_var = Scalar(0.0)

@finch begin
    for i = _
        let x = X[i]
            x_min[] <<min>>= x
            x_max[] <<max>>= x
            x_sum[] += x
            x_var[] += x * x
        end
    end
end;
```

### Sparse Matrix-Vector Multiplication

Illustrating Finch's power with a more complex structure, the following example performs a sparse matrix-vector multiplication using a column-major approach.

```julia
x = Fiber!(Dense(Element(0.0)), rand(42));
A = Fiber!(Dense(SparseList(Element(0.0))), fsprand((42, 42), 0.1));
y = Fiber!(Dense(Element(0.0)));

@finch begin
    y .= 0
    for j=_, i=_
        y[i] += A[i, j] * x[j]
    end
end
```
# Installation

At the [Julia](https://julialang.org/downloads/) REPL, install the latest stable version by running:

````julia
julia> using Pkg; Pkg.add("Finch")
````

## Learn More

At it's heart, Finch is powered by a new domain specific language for
coiteration, breaking structured iterators into control flow units we call
**Looplets**. Looplets are lowered progressively with
several stages for rewriting and simplification.

The technologies enabling Finch are described in our [manuscript](https://doi.org/10.1145/3579990.3580020).
