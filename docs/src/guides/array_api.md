```@meta
CurrentModule = Finch
```

# High-Level Array API

Finch tensors also support many of the basic array operations one might expect,
including indexing, slicing, and elementwise maps, broadcast, and reduce.
For example:

```jldoctest example1; setup = :(using Finch)
julia> A = fsparse([1, 1, 2, 3], [2, 4, 5, 6], [1.0, 2.0, 3.0])
SparseCOO{2} (0.0) [:,1:6]
├─ [1, 2]: 1.0
├─ [1, 4]: 2.0
└─ [2, 5]: 3.0

julia> A + 0
SwizzleArray(Tensor(Dense{Int64}(Dense{Int64}(Element{0.0, Float64, Int64}([0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 0.0, 0.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0.0]), 3), 6)), (1, 2))

julia> A + 1
SwizzleArray(Tensor(Dense{Int64}(Dense{Int64}(Element{1.0, Float64, Int64}([1.0, 1.0, 1.0, 2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 3.0, 1.0, 1.0, 1.0, 4.0, 1.0, 1.0, 1.0, 1.0]), 3), 6)), (1, 2))

julia> B = A .* 2
SwizzleArray(Tensor(Sparse{Int64}(Sparse{Int64}(Element{0.0, Float64, Int64}([2.0, 4.0, 6.0]), 3, Finch.DictTable{Int64, Int64, Vector{Int64}, Vector{Int64}, Vector{Int64}, Dict{Tuple{Int64, Int64}, Int64}}([1, 2, 3, 4], [1, 1, 2], [1, 2, 3], Dict((3, 2) => 3, (1, 1) => 1, (2, 1) => 2))), 6, Finch.DictTable{Int64, Int64, Vector{Int64}, Vector{Int64}, Vector{Int64}, Dict{Tuple{Int64, Int64}, Int64}}([1, 4], [2, 4, 5], [1, 2, 3], Dict((1, 2) => 1, (1, 4) => 2, (1, 5) => 3)))), (1, 2))

julia> B[1:2, 1:2]
Sparse (0.0) [:,1:2]
└─ [:, 2]: Sparse (0.0) [1:2]
   └─ [1]: 2.0

julia> map(x -> x^2, B)
SwizzleArray(Tensor(Sparse{Int64}(Sparse{Int64}(Element{0.0, Float64, Int64}([4.0, 16.0, 36.0]), 3, Finch.DictTable{Int64, Int64, Vector{Int64}, Vector{Int64}, Vector{Int64}, Dict{Tuple{Int64, Int64}, Int64}}([1, 2, 3, 4], [1, 1, 2], [1, 2, 3], Dict((3, 2) => 3, (1, 1) => 1, (2, 1) => 2))), 6, Finch.DictTable{Int64, Int64, Vector{Int64}, Vector{Int64}, Vector{Int64}, Dict{Tuple{Int64, Int64}, Int64}}([1, 4], [2, 4, 5], [1, 2, 3], Dict((1, 2) => 1, (1, 4) => 2, (1, 5) => 3)))), (1, 2))
```

# Array Fusion

Finch supports array fusion, which allows you to compose multiple array operations
into a single kernel. This can be a significant performance optimization, as it
allows the compiler to optimize the entire operation at once. The two functions
the user needs to know about are `lazy` and `compute`. You can use `lazy` to
mark an array as an input to a fused operation, and call `compute` to execute
the entire operation at once. For example:

```jldoctest example1
julia> C = lazy(A);

julia> D = lazy(B);

julia> E = (C .+ D)/2;

julia> compute(E)
SwizzleArray(Tensor(Sparse{Int64}(Sparse{Int64}(Element{0.0, Float64, Int64}([1.5, 3.0, 4.5]), 3, Finch.DictTable{Int64, Int64, Vector{Int64}, Vector{Int64}, Vector{Int64}, Dict{Tuple{Int64, Int64}, Int64}}([1, 2, 3, 4], [1, 1, 2], [1, 2, 3], Dict((3, 2) => 3, (1, 1) => 1, (2, 1) => 2))), 6, Finch.DictTable{Int64, Int64, Vector{Int64}, Vector{Int64}, Vector{Int64}, Dict{Tuple{Int64, Int64}, Int64}}([1, 4], [2, 4, 5], [1, 2, 3], Dict((1, 2) => 1, (1, 4) => 2, (1, 5) => 3)))), (1, 2))

```

In the above example, `E` is a fused operation that adds `C` and `D` together
and then divides the result by 2. The `compute` function examines the entire
operation and decides how to execute it in the most efficient way possible.
In this case, it would likely generate a single kernel that adds the elements of `A` and `B`
together and divides each result by 2, without materializing an intermediate.

```@docs
lazy
compute
```

# Einsum

Finch also supports a highly general `@einsum` macro which supports any reduction over any simple pointwise array expression.

```@docs
@einsum
```