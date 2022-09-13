```@meta
CurrentModule = Finch
```

# Finch

[Finch](https://github.com/willowahrens/Finch.jl) is an adaptable compiler for
loop nests over structured arrays. Finch can specialize to tensors with runs of
repeated values, or to tensors which are sparse (mostly zero). Finch supports
general sparsity as well as many specialized sparsity patterns, like clustered
nonzeros, diagonals, or triangles.  In addition to zero, Finch supports
optimizations over arbitrary fill values and operators.

At it's heart, Finch is powered by a domain specific language for coiteration,
breaking structured iterators into units we call Looplets. The Looplets are
lowered progressively, leaving several opportunities to rewrite and simplify
intermediate expressions.

## Installation:

```julia
julia> using Pkg; Pkg.add("Finch")
```

## Quick start guide

You can convert an AbstractArray to a Finch Fiber with the `fiber` function:

```julia
julia> using Finch, SparseArrays

julia> A = fiber(sprand(5, 6, 0.5))
Dense [1:5]
│ 
├─[1]:
│ SparseList (0.0) [1:6]
│ │ 
│ └─[1]      [3]    
│   0.758513 0.65606
│ 
├─[2]:
│ SparseList (0.0) [1:6]
│ │ 
│ └─[2]      [5]     
│   0.103387 0.103223
│ 
├─[3]:
│ SparseList (0.0) [1:6]
│ │ 
│ └─[1]      [2]     
│   0.653705 0.225958
│ 
├─[4]:
│ SparseList (0.0) [1:6]
│ │ 
│ └─[1]      [2]      [4]      [5]     
│   0.918955 0.898256 0.444113 0.843331
│ 
├─[5]:
│ SparseList (0.0) [1:6]
│ │ 
│ └─[4]      
│   0.0701716


julia> A(1, 3)
0.65605977333406

julia> A(1, 2)
0.0
```

Arrays in finch are stored using a recursive tree-based approach. 