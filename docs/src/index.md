```@meta
CurrentModule = Finch
```

# Finch

[Finch](https://github.com/willow-ahrens/Finch.jl) is an adaptable compiler for
loop nests over sparse or otherwise structured arrays. Finch supports general
sparsity as well as many specialized sparsity patterns, like clustered nonzeros,
diagonals, or triangles.  In addition to zero, Finch supports optimizations over
arbitrary fill values and operators, even run-length-compression.

At it's heart, Finch is powered by a domain specific language for coiteration,
breaking structured iterators into units we call Looplets. The Looplets are
lowered progressively, leaving several opportunities to rewrite and simplify
intermediate expressions.

## Installation:

```julia
julia> using Pkg; Pkg.add("Finch")
```

## Basics:

To begin, the following program sums the rows of a sparse matrix:
```julia
using Finch
A = sprand(5, 5, 0.5)
y = zeros(5)
@finch begin
    y .= 0
    for i=_, j=_
        y[i] += A[i, j]
    end
end
```

The [`@finch`](@ref) macro takes a block of code, and compiles it using the sparsity
attributes of the arguments. In this case, `A` is a sparse matrix, so the
compiler generates a sparse loop nest. The compiler takes care of applying rules
like `x * 0 => 0` during compilation to make the code more efficient.

You can call [`@finch`](@ref) on any loop program, but it will only generate sparse code
if the arguments are sparse. For example, the following program calculates the
sum of the elements of a dense matrix:
```julia
using Finch
A = rand(5, 5)
s = Scalar(0.0)
@finch begin
    s .= 0
    for i=_, j=_
        s[] += A[i, j]
    end
end
```

You can call [`@finch_code`](@ref) to see the generated code (since `A` is dense, the
code is dense):
```jldoctest example1; setup=:(using Finch; A = rand(5, 5); s = Scalar(0))
julia> @finch_code for i=_, j=_ ; s[] += A[i, j] end
quote
    s = (ex.bodies[1]).body.body.lhs.tns.bind
    s_val = s.val
    A = (ex.bodies[1]).body.body.rhs.tns.bind
    sugar_1 = size((ex.bodies[1]).body.body.rhs.tns.bind)
    A_mode1_stop = sugar_1[1]
    A_mode2_stop = sugar_1[2]
    @warn "Performance Warning: non-concordant traversal of A[i, j] (hint: most arrays prefer column major or first index fast, run in fast mode to ignore this warning)"
    result = nothing
    for i_3 = 1:A_mode1_stop
        for j_3 = 1:A_mode2_stop
            val = A[i_3, j_3]
            s_val = val + s_val
        end
    end
    result = ()
    s.val = s_val
    result
end
```

We're working on adding more documentation, for now take a look at the
[examples](https://github.com/willow-ahrens/Finch.jl/blob/main/docs/examples)!