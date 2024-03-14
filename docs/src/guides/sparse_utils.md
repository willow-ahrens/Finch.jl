# Sparse and Structured Array Utilities

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

Finch tensors support an arbitrary "background" value for sparse arrays. While most arrays use `0` as the background value, this is not always the case. For example, a sparse array of `Int` might use `typemin(Int)` as the background value. The `default` function returns the background value of a tensor. If you ever want to change the background value of an existing array, you can use the `redefault!` function. The `countstored` function returns the number of stored elements in a tensor, and calling `pattern!` on a tensor returns tensor which is true whereever the original tensor stores a value. Note that countstored doesn't always return the number of non-zero elements in a tensor, as it counts the number of stored elements, and stored elements may include the background value. You can call `dropdefaults!` to remove explicitly stored background values from a tensor.

```jldoctest example1; setup = :(using Finch)
julia> A = fsparse([1, 1, 2, 3], [2, 4, 5, 6], [1.0, 2.0, 3.0])
SparseCOO{2} (0.0) [:,1:6]
├─ [1, 2]: 1.0
├─ [1, 4]: 2.0
└─ [2, 5]: 3.0

julia> min.(A, -1)


)
Dense [:,1:6]
├─ [:, 1]: Dense [1:3]
│  ├─ [1]: -1.0
│  ├─ [2]: -1.0
│  └─ [3]: -1.0
├─ [:, 2]: Dense [1:3]
│  ├─ [1]: -1.0
│  ├─ [2]: -1.0
│  └─ [3]: -1.0
├─ [:, 3]: Dense [1:3]
│  ├─ [1]: -1.0
│  ├─ [2]: -1.0
│  └─ [3]: -1.0
├─ [:, 4]: Dense [1:3]
│  ├─ [1]: -1.0
│  ├─ [2]: -1.0
│  └─ [3]: -1.0
├─ [:, 5]: Dense [1:3]
│  ├─ [1]: -1.0
│  ├─ [2]: -1.0
│  └─ [3]: -1.0
└─ [:, 6]: Dense [1:3]
   ├─ [1]: -1.0
   ├─ [2]: -1.0
   └─ [3]: -1.0

julia> default(A)
0.0

julia> B = redefault!(A, -Inf)
SparseCOO{2} (-Inf) [:,1:6]
├─ [1, 2]: 1.0
├─ [1, 4]: 2.0
└─ [2, 5]: 3.0

julia> min.(B, -1)


)
Sparse (-Inf) [:,1:6]
├─ [:, 2]: Sparse (-Inf) [1:3]
│  └─ [1]: -1.0
├─ [:, 4]: Sparse (-Inf) [1:3]
│  └─ [1]: -1.0
└─ [:, 5]: Sparse (-Inf) [1:3]
   └─ [2]: -1.0

julia> countstored(A)
3

julia> pattern!(A)
SparseCOO{2} (false) [:,1:6]
├─ [1, 2]: true
├─ [1, 4]: true
└─ [2, 5]: true

```

```@docs
redefault!
pattern!
countstored
dropdefaults
dropdefaults!
```