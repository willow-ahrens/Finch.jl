# Using Finch with Other Languages

You can use Finch in other languages through our C interface! We also include
convenience types for converting between 0-indexed and 1-indexed arrays.

## finch.h

Refer to
[finch.h](https://github.com/willow-ahrens/Finch.jl/blob/main/embed/finch.h) for
detailed documentation. The public functions include a few shortcuts for
constructing finch datatypes, as well as convenience functions for calling Julia
from C. Refer also to the [Julia
documentation](https://docs.julialang.org/en/v1/manual/embedding/) for more
general advice. Refer to the tests for a [working
example](https://github.com/willow-ahrens/Finch.jl/blob/main/test/embed/test_embed_simple.c)
of embedding in C. Note that calling `finch_init` will call `jl_init`, as well
as initializing a few function pointers for the interface. Julia cannot see C
references to Julia objects, so `finch.h` includes a few functions to introduce
references on the Julia side that mirror C objects.

## 0-Index Compatibility

Julia, Matlab, etc. index arrays [starting at
1](https://docs.julialang.org/en/v1/devdocs/offset-arrays/). C, python, etc.
index starting at 0. In a dense array, we can simply subtract one from the
index, and in fact, this is what Julia will does under the hood when you pass a
vector [between C to
Julia](https://docs.julialang.org/en/v1/manual/embedding/#Working-with-Arrays). 

However, for sparse array formats, it's not just a matter of subtracting one
from the index, as the internal lists of indices, positions, etc all start from
zero as well. To remedy the situation, Finch defines a handy zero-indexed integer
type called `CIndex`. The internal representation of `CIndex` is one less than the
value it represents, and we can use `CIndex` as the index or position type of
a Finch array to represent arrays in other languages.

For example, if `idx_c`, `ptr_c`, and `val_c` are the internal arrays of a CSC
matrix in a zero-indexed language, we can represent that matrix as a one-indexed
Finch array without copying by calling
```@meta
DocTestSetup = quote
    using Finch
    using Finch: Cindex
end
```
```jldoctest example2
julia> m = 4; n = 3; ptr_c = [0, 3, 3, 5]; idx_c = [1, 2, 3, 0, 2]; val_c = [1.1, 2.2, 3.3, 4.4, 5.5];

julia> ptr_jl = unsafe_wrap(Array, reinterpret(Ptr{Cindex{Int}}, pointer(ptr_c)), length(ptr_c); own = false)
4-element Vector{Cindex{Int64}}:
 Cindex{Int64}(0)
 Cindex{Int64}(3)
 Cindex{Int64}(3)
 Cindex{Int64}(5)
julia> idx_jl = unsafe_wrap(Array, reinterpret(Ptr{Cindex{Int}}, pointer(idx_c)), length(idx_c); own = false)
5-element Vector{Cindex{Int64}}:
 Cindex{Int64}(1)
 Cindex{Int64}(2)
 Cindex{Int64}(3)
 Cindex{Int64}(0)
 Cindex{Int64}(2)
julia> A = Fiber(Dense(SparseList{Cindex{Int}, Cindex{Int}}(Element{0.0, Float64}(val_c), m, ptr_jl, idx_jl), n))
Dense [:,1:3]
├─[:,1]: SparseList (0.0) [1:Cindex{Int64}(3)]
│ ├─[Cindex{Int64}(1)]: 1.1
│ ├─[Cindex{Int64}(2)]: 2.2
│ ├─[Cindex{Int64}(3)]: 3.3
├─[:,2]: SparseList (0.0) [1:Cindex{Int64}(3)]
├─[:,3]: SparseList (0.0) [1:Cindex{Int64}(3)]
│ ├─[Cindex{Int64}(0)]: 4.4
│ ├─[Cindex{Int64}(2)]: 5.5
```

We can also convert between representations by by copying to or from `Cindex` fibers.