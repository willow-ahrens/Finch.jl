# Sparse Array Utilities

## Sparse Constructors

In addition to the `Tensor` constructor, Finch provides a number of convenience
constructors for common tensor types. For example, the `spzeros` and `sprand` functions   
have `fspzeros` and `fsprand` counterparts that return Finch tensors. We can also construct
a sparse COO `Tensor` from a list of indices and values using the `fsparse` function.

```@docs
fsparse
fsparse!
fsprand
fspzeros
ffindnz
```

## Fill Values

Finch tensors support an arbitrary "background" value for sparse arrays. While most arrays use `0` as the background value, this is not always the case. For example, a sparse array of `Int` might use `typemin(Int)` as the background value. The `default` function returns the background value of a tensor. If you ever want to change the background value of an existing array, you can use the `set_fill_value!` function. The `countstored` function returns the number of stored elements in a tensor, and calling `pattern!` on a tensor returns tensor which is true whereever the original tensor stores a value. Note that countstored doesn't always return the number of non-zero elements in a tensor, as it counts the number of stored elements, and stored elements may include the background value. You can call `dropfills!` to remove explicitly stored background values from a tensor.

```jldoctest example1; setup = :(using Finch)
julia> A = fsparse([1, 1, 2, 3], [2, 4, 5, 6], [1.0, 2.0, 3.0])
SparseCOO{2} (0.0) [:,1:6]
├─ [1, 2]: 1.0
├─ [1, 4]: 2.0
└─ [2, 5]: 3.0

julia> min.(A, -1)
SwizzleArray(Tensor(Dense{Int64}(Dense{Int64}(Element{-1.0, Float64, Int64}([-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0]), 3), 6)), (1, 2))

julia> fill_value(A)
0.0

julia> B = set_fill_value!(A, -Inf)
SparseCOO{2} (-Inf) [:,1:6]
├─ [1, 2]: 1.0
├─ [1, 4]: 2.0
└─ [2, 5]: 3.0

julia> min.(B, -1)
SwizzleArray(Tensor(Sparse{Int64}(Sparse{Int64}(Element{-Inf, Float64, Int64}([-1.0, -1.0, -1.0]), 3, Finch.DictTable{Int64, Int64, Vector{Int64}, Vector{Int64}, Vector{Int64}, Dict{Tuple{Int64, Int64}, Int64}}([1, 2, 3, 4], [1, 1, 2], [1, 2, 3], Dict((3, 2) => 3, (1, 1) => 1, (2, 1) => 2))), 6, Finch.DictTable{Int64, Int64, Vector{Int64}, Vector{Int64}, Vector{Int64}, Dict{Tuple{Int64, Int64}, Int64}}([1, 4], [2, 4, 5], [1, 2, 3], Dict((1, 2) => 1, (1, 4) => 2, (1, 5) => 3)))), (1, 2))

julia> countstored(A)
3

julia> pattern!(A)
SparseCOO{2} (false) [:,1:6]
├─ [1, 2]: true
├─ [1, 4]: true
└─ [2, 5]: true

```

```@docs
set_fill_value!
pattern!
countstored
dropfills
dropfills!
```

### How to tell whether an entry is "fill"

In the sparse world, a semantic distinction is sometimes made between
"explicitly stored" values and "implicit" or "fill" values (usually zero).
However, the formats in the Finch compiler represent a diverse set of structures
beyond sparsity, and it is often unclear whether any of the values in the tensor
are "explicit" (consider a mask matrix, which can be represented with a constant
number of bits). Thus, Finch makes no semantic distinction between values which
are stored explicitly or not. If users wish to make this distinction, they should
instead store a tensor of tuples of the form `(value, is_fill)`. For example,

```jldoctest example3; setup = :(using Finch)
julia> A = fsparse([1, 1, 2, 3], [2, 4, 5, 6], [(1.0, false), (0.0, true), (3.0, false)]; fill_value=(0.0, true))
SparseCOO{2} ((0.0, true)) [:,1:6]
├─ [1, 2]: (1.0, false)
├─ [1, 4]: (0.0, true)
└─ [2, 5]: (3.0, false)

julia> B = Tensor(Dense(SparseList(Element((0.0, true)))), A)
Dense [:,1:6]
├─ [:, 1]: SparseList ((0.0, true)) [1:3]
├─ [:, 2]: SparseList ((0.0, true)) [1:3]
│  └─ [1]: (1.0, false)
├─ [:, 3]: SparseList ((0.0, true)) [1:3]
├─ [:, 4]: SparseList ((0.0, true)) [1:3]
├─ [:, 5]: SparseList ((0.0, true)) [1:3]
│  └─ [2]: (3.0, false)
└─ [:, 6]: SparseList ((0.0, true)) [1:3]

julia> sum(map(last, B))
16

julia> sum(map(first, B))
4.0

```