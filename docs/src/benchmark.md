```@meta
EditURL = "benchmark.jl"
```

# Benchmarking

Julia code is [nototoriously
fussy](https://github.com/JuliaCI/BenchmarkTools.jl#why-does-this-package-exist)
to benchmark.
We'll use [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl)
to automatically follow best practices for getting reliable julia benchmarks. We'll also
follow the [Julia Performance Tips](https://docs.julialang.org/en/v1/manual/performance-tips/).

Finch is even trickier to benchmark, for a few reasons:
1. The first time an @finch function is called, it is compiled, which takes an
   extra long time. @finch can also incur dynamic dispatch costs if the array
   types are not [type
   stable](https://docs.julialang.org/en/v1/manual/faq/#man-type-stability). We
   can remedy this by using [`@finch_kernel`](@ref), which simplifies
   benchmarking by compiling the function ahead of time, so it behaves like a
   normal Julia function. If you must use `@finch`, try to ensure that the code
   is type-stable.
2. Finch fibers reuse memory from previous calls, so the first time a fiber is
   used in a finch function, it will allocate memory, but subsequent times not so
   much. If we want to benchmark the memory allocation, we can reconstruct the
   fiber each time. Otherwise, we can let the repeated executions of the kernel
   measure the non-allocating runtime.
3. Runtime for sparse code often depends on the sparsity pattern, so it's
   important to benchmark with representative data. Using standard matrices or tensors from
   [MatrixDepot.jl](https://github.com/JuliaLinearAlgebra/MatrixDepot.jl) or
   [TensorDepot.jl](https://github.com/willow-ahrens/TensorDepot.jl) is a good
   way to do this.

````julia
using Finch
using BenchmarkTools
using SparseArrays
using MatrixDepot
````

````
[32m[1m Downloading[22m[39m artifact: MPICH
[32m[1m Downloading[22m[39m artifact: HDF5
[ Info: verify download of index files...
[ Info: creating database file
[ Info: reading index files
[ Info: downloading: https://sparse.tamu.edu/files/ss_index.mat
[ Info: downloading index file https://math.nist.gov/MatrixMarket/matrices.html
[ Info: adding metadata...
[ Info: adding svd data...
[ Info: writing database
[ Info: used remote sites are sparse.tamu.edu with MAT index and math.nist.gov with HTML index

````

Load a sparse matrix from MatrixDepot.jl and convert it to a Finch fiber

````julia
A = Fiber!(Dense(SparseList(Element(0.0))), matrixdepot("HB/west0067"))
(m, n) = size(A)

x = Fiber!(Dense(Element(0.0)), rand(n))
y = Fiber!(Dense(Element(0.0)))
````

````
Dense [1:0]
````

Construct a Finch kernel for sparse matrix-vector multiply

````julia
eval(@finch_kernel function spmv(y, A, x)
    y .= 0
    for j = _, i = _
        y[i] += A[i, j] * x[j]
    end
end)
````

````
spmv (generic function with 1 method)
````

Benchmark the kernel, ignoring allocation costs for y

````julia
@benchmark spmv($y, $A, $x)
````

````
BenchmarkTools.Trial: 10000 samples with 165 evaluations.
 Range (min … max):  642.473 ns … 955.224 ns  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     697.636 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   685.754 ns ±  35.020 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  ▃█▇▄▆▂▁   ▃▅▃        ▃██▅▆▄     ▄▅▄                           ▂
  ████████▇████▆▇▇▇▆▅▆▆█████████▇█████▇█▇██▇▇████▇██▅▇▇▇▆▇▆▇▆▇▇ █
  642 ns        Histogram: log(frequency) by time        792 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
````

The `@benchmark` macro will benchmark a function in local scope, and it will run
the function a few times to estimate the runtime. It will also try to avoid
first-time compilation costs by running the function once before benchmarking
it. Note the use of `$` to interpolate the arrays into the benchmark, bringing
them into the local scope.

We can also benchmark the memory allocation of the kernel by constructing `y` in the
benchmark kernel

````julia
@benchmark begin
    y = Fiber!(Dense(Element(0.0)))
    y = spmv(y, $A, $x).y
end
````

````
BenchmarkTools.Trial: 10000 samples with 134 evaluations.
 Range (min … max):  630.649 ns … 199.249 μs  ┊ GC (min … max):  0.00% … 99.51%
 Time  (median):       1.028 μs               ┊ GC (median):     0.00%
 Time  (mean ± σ):     1.100 μs ±   5.442 μs  ┊ GC (mean ± σ):  13.98% ±  2.81%

           ▅█ ▃  ▇                         ▄▅▆      ▁            
  ▃▃▃▂▁▂▁▁▂████▃▃█▇▇▇▃▃▂▃▃▃▂▂▂▂▃▃▃▃▂▂▂▂▂▂▃▆████▅▄▄▆██▇▄▃▃▃▃▃▃▂▂ ▄
  631 ns           Histogram: frequency by time         1.26 μs <

 Memory estimate: 624 bytes, allocs estimate: 2.
````

