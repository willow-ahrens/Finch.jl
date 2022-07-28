"""
    fiber!(arr, default = zero(eltype(arr)))

Like [`fiber`](@ref), copies an array-like object `arr` into a corresponding,
similar `Fiber` datastructure. However, `fiber!` reuses memory whenever
possible, meaning `arr` may be rendered unusable.
"""
fiber!(arr, default=zero(eltype(arr))) = fiber(arr, default=default)

"""
    fiber(arr, default = zero(eltype(arr)))

Copies an array-like object `arr` into a corresponding, similar `Fiber`
datastructure. `default` is the default value to use for initialization and
sparse compression.

See also: [`fiber!`](@ref)

# Examples

```jldoctest
julia> println(summary(fiber(sparse([1 0; 0 1]))))
2×2 Fiber f"sl"(0)

julia> println(summary(fiber(ones(3, 2, 4))))
3×2×4 Fiber f"sss"(0.0)
```
"""
function fiber(arr, default=zero(eltype(arr)))
    Base.copyto!(Fiber((SolidLevel^(ndims(arr)))(Element{default}())), arr)
end

@generated function Base.copyto!(dst::Fiber, src)
    dst = virtualize(:dst, dst, LowerJulia())
    idxs = [Symbol(:i_, n) for n = getsites(dst)]
    return quote
        @index @loop($(idxs...), dst[$(idxs...)] = src[$(idxs...)])
        return dst
    end
end

"""
    fsparse(I::Tuple, V,[ M::Tuple, combine])

Create a sparse COO fiber `S` such that `size(S) == M` and `S[(i[q] for i =
I)...] = V[q]`. The combine function is used to combine duplicates. If `M` is
not specified, it is set to `map(maximum, I)`. If the combine function is not
supplied, combine defaults to `+` unless the elements of V are Booleans in which
case combine defaults to `|`. All elements of I must satisfy 1 <= I[n][q] <=
M[n].  Numerical zeros are retained as structural nonzeros; to drop numerical
zeros, use dropzeros!.

# Examples

julia> I = (
    [1, 2, 3],
    [1, 2, 3],
    [1, 2, 3]);

julia> V = [1.0; 2.0; 3.0];

julia> fsparse(I, V)
HollowCoo (0.0) [1:3×1:3×1:3]
│ │ │ 
└─└─└─[1, 1, 1] [2, 2, 2] [3, 3, 3]
      1.0       2.0       3.0    
"""
function fsparse(I::Tuple, V::Vector, shape = map(maximum, I), combine = eltype(V) isa Bool ? (|) : (+))
    C = map(tuple, I...)
    update = false
    if !issorted(C)
        P = sortperm(C)
        C = C[P]
        V = V[P]
        update = true
    end
    if !allunique(C)
        P = unique(p -> C[p], 1:length(C))
        C = C[P]
        push!(P, length(I[1]) + 1)
        V = map((start, stop) -> foldl(combine, @view V[start:stop - 1]), P[1:end - 1], P[2:end])
        update = true
    end
    if update
        I = map(i -> similar(i, length(C)), I)
        foreach(((p, c),) -> ntuple(n->I[n][p] = c[n], length(I)), enumerate(C))
    else
        I = map(copy, I)
    end
    return fsparse!(I, V, shape)
end

"""
    fsparse!(I::Tuple, V,[ M::Tuple])

Like [`fsparse`](https://docs.julialang.org/en/v1/stdlib/SparseArrays/#SparseArrays.sparse), but the coordinates must be sorted and unique, and memory
is reused.
"""
function fsparse!(I::Tuple, V, shape = map(maximum, I))
    return Fiber(HollowCoo{length(I), Tuple{map(eltype, I)...}, Int}(shape, I, [1, length(I[1]) + 1], Element{zero(eltype(V))}(V)))
end

fsprand(n::Tuple, args...) = _fsprand_impl(n, sprand(mapfoldl(BigInt, *, n), args...))
fsprand(r::SparseArrays.AbstractRNG, n::Tuple, args...) = _fsprand_impl(r, n, sprand(mapfoldl(BigInt, *, n), args...))
fsprand(r::SparseArrays.AbstractRNG, T::Type, n::Tuple, args...) = _fsprand_impl(r, T, n, sprand(mapfoldl(BigInt, *, n), args...))
function _fsprand_impl(shape::Tuple, vec::SparseVector{Ti, Tv}) where {Ti, Tv}
    I = ((Vector(undef, length(vec.nzind)) for _ in shape)...,)
    for (p, ind) in enumerate(vec.nzind)
        c = CartesianIndices(reverse(shape))[ind]
        ntuple(n->I[n][p] = c[length(shape) - n + 1], length(shape))
    end
    return fsparse!(I, vec.nzval, shape)
end

fspzeros(shape) = spzeros(Float64, shape)
function fspzeros(::Type{T}, shape) where {T}
    return sparse!(((Int[] for _ in shape)...,), T[], shape)
end

function ffindnz(src)
    tmp = Fiber(
        HollowCooLevel{ndims(src)}(
        ElementLevel{zero(eltype(src)), eltype(src)}()))
    tmp = copyto!(tmp, src)
    nnz = tmp.lvl.pos[2] - 1
    tbl = tmp.lvl.tbl
    val = tmp.lvl.lvl.val
    (ntuple(n->tmp.lvl.tbl[n][1:nnz], ndims(src)), val[1:nnz])
end