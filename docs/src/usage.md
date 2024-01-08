```@meta
CurrentModule = Finch
```

# Usage

## General Purpose (`@finch`)

Most users will want to use the [`@finch`](@ref) macro, which executes the given
program immediately in the given scope. The program will be JIT-compiled on the
first call to `@finch` with the given array argument types. If the array
arguments to `@finch` are [type
stable](https://docs.julialang.org/en/v1/manual/faq/#man-type-stability), the
program will be JIT-compiled when the surrounding function is compiled.

Very often, the best way to inspect Finch compiler behavior is through the
[`@finch_code`](@ref) macro, which prints the generated code instead of
executing it.

```@docs
@finch
@finch_code
```

## Ahead Of Time (`@finch_kernel`)

While [`@finch`](@ref) is the recommended way to use Finch, it is also possible
to run finch ahead-of-time. The [`@finch_kernel`](@ref) macro generates a
function definition ahead-of-time, which can be evaluated and then called later.

There are several reasons one might want to do this:

1. If we want to make tweaks to the Finch implementation, we can directly modify the source code of the resulting function.
2. When benchmarking Finch functions, we can easily and reliably ensure the benchmarked code is [inferrable](https://docs.julialang.org/en/v1/devdocs/inference/).
3. If we want to use Finch to generate code but don't want to include Finch as a dependency in our project, we can use [`@finch_kernel`](@ref) to generate the functions ahead of time and copy and paste the generated code into our project.  Consider automating this workflow to keep the kernels up to date!

```@docs
    @finch_kernel
```

As an example, the following code generates an spmv kernel definition, evaluates
the definition, and then calls the kernel several times.

```julia
let
    A = Fiber(Dense(SparseList(Element(0.0))))
    x = Fiber(Dense(Element(0.0)))
    y = Fiber(Dense(Element(0.0)))
    def = @finch_kernel function spmv(y, A, x)
        y .= 0.0
        for j = _, i = _
            y[i] += A[i, j] * x[j]
        end
    end
    eval(def)
end

function main()
    for i = 1:10
        A2 = Fiber(Dense(SparseList(Element(0.0))), fsprand(10, 10, 0.1))
        x2 = Fiber(Dense(Element(0.0)), rand(10))
        y2 = Fiber(Dense(Element(0.0)))
        spmv(y2, A2, x2)
    end
end

main()
```