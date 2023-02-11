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
2×2 @fiber(d(sl(e(0))))

julia> println(summary(fiber(ones(3, 2, 4))))
3×2×4 @fiber(d(d(d(e(0.0)))))
```
"""
function fiber(arr, default=zero(eltype(arr)))
    Base.copyto!(Fiber((DenseLevel^(ndims(arr)))(Element{default}())), arr)
end

@generated function helper_equal(A, B)
    idxs = [Symbol(:i_, n) for n = 1:ndims(A)]
    return quote
        size(A) == size(B) || return false
        check = Scalar(true)
        if check[]
            @finch @loop($(reverse(idxs)...), check[] &= (A[$(idxs...)] == B[$(idxs...)]))
        end
        return check[]
    end
end

function Base.:(==)(A::Fiber, B::Fiber)
    return helper_equal(A, B)
end

function Base.:(==)(A::Fiber, B::AbstractArray)
    return helper_equal(A, B)
end

function Base.:(==)(A::AbstractArray, B::Fiber)
    return helper_equal(A, B)
end

@generated function helper_isequal(A, B)
    idxs = [Symbol(:i_, n) for n = 1:ndims(A)]
    return quote
        size(A) == size(B) || return false
        check = Scalar(true)
        if check[]
            @finch @loop($(reverse(idxs)...), check[] &= isequal(A[$(idxs...)], B[$(idxs...)]))
        end
        return check[]
    end
end

function Base.isequal(A:: Fiber, B::Fiber)
    return helper_isequal(A, B)
end

function Base.isequal(A:: Fiber, B::AbstractArray)
    return helper_isequal(A, B)
end

function Base.isequal(A:: AbstractArray, B::Fiber)
    return helper_isequal(A, B)
end

@generated function copyto_helper!(dst, src)
    idxs = [Symbol(:i_, n) for n = 1:ndims(dst)]
    return quote
        @finch @loop($(reverse(idxs)...), dst[$(idxs...)] = src[$(idxs...)])
        return dst
    end
end

function Base.copyto!(dst::Fiber, src::Union{Fiber, AbstractArray})
    return copyto_helper!(dst, src)
end

function Base.copyto!(dst::Array, src::Fiber)
    return copyto_helper!(dst, src)
end

dropdefaults(src) = dropdefaults!(similar(src), src)

@generated function dropdefaults!(dst::Fiber, src)
    idxs = [Symbol(:i_, n) for n = 1:ndims(dst)]
    T = eltype(dst)
    d = default(dst)
    return quote
        tmp = Scalar{$d, $T}()
        @finch @loop($(reverse(idxs)...), (@sieve (tmp[] != $d) dst[$(idxs...)] = tmp[]) where (tmp[] = src[$(idxs...)]))
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

See also: [`sparse`](https://docs.julialang.org/en/v1/stdlib/SparseArrays/#SparseArrays.sparse)

# Examples

julia> I = (
    [1, 2, 3],
    [1, 2, 3],
    [1, 2, 3]);

julia> V = [1.0; 2.0; 3.0];

julia> fsparse(I, V)
SparseCoo (0.0) [1:3×1:3×1:3]
│ │ │ 
└─└─└─[1, 1, 1] [2, 2, 2] [3, 3, 3]
      1.0       2.0       3.0    
"""
function fsparse(I::Tuple, V::Vector, shape = map(maximum, I), combine = eltype(V) isa Bool ? (|) : (+))
    C = map(tuple, I...)
    updater = false
    if !issorted(C)
        P = sortperm(C)
        C = C[P]
        V = V[P]
        updater = true
    end
    if !allunique(C)
        P = unique(p -> C[p], 1:length(C))
        C = C[P]
        push!(P, length(I[1]) + 1)
        V = map((start, stop) -> foldl(combine, @view V[start:stop - 1]), P[1:end - 1], P[2:end])
        updater = true
    end
    if updater
        I = map(i -> similar(i, length(C)), I)
        foreach(((p, c),) -> ntuple(n->I[n][p] = c[n], length(I)), enumerate(C))
    else
        I = map(copy, I)
    end
    return fsparse!(I, V, shape)
end

"""
    fsparse!(I::Tuple, V,[ M::Tuple])

Like [`fsparse`](@ref), but the coordinates must be sorted and unique, and memory
is reused.
"""
function fsparse!(I::Tuple, V, shape = map(maximum, I))
    return Fiber(SparseCoo{length(I), Tuple{map(eltype, I)...}, Int}(Element{zero(eltype(V))}(V), shape, I, [1, length(V) + 1]))
end

"""
    fsprand([rng],[type], m::Tuple,p::AbstractFloat,[rfn])

Create a random sparse tensor of size `m` in COO format, in which the
probability of any element being nonzero is independently given by `p` (and
hence the mean density of nonzeros is also exactly `p`). Nonzero values are
sampled from the distribution specified by `rfn` and have the type `type`. The
uniform distribution is used in case `rfn` is not specified. The optional `rng`
argument specifies a random number generator.

See also: (`sprand`)(https://docs.julialang.org/en/v1/stdlib/SparseArrays/#SparseArrays.sprand)

# Examples
```jldoctest; setup = :(using Random; Random.seed!(1234))
julia> fsprand(Bool, (3, 3), 0.5)
SparseCoo (false) [1:3×1:3]
│ │
└─└─[1, 1] [3, 1] [2, 2] [3, 2] [3, 3]
    true   true   true   true   true  

julia> fsprand(Float64, (2, 2, 2), 0.5)
SparseCoo (0.0) [1:2×1:2×1:2]
│ │ │
└─└─└─[2, 2, 1] [1, 1, 2] [2, 1, 2]
      0.647855  0.996665  0.749194 
```
"""
fsprand(n::Tuple, args...) = _fsprand_impl(n, sprand(mapfoldl(BigInt, *, n), args...))
fsprand(T::Type, n::Tuple, args...) = _fsprand_impl(n, sprand(T, mapfoldl(BigInt, *, n), args...))
fsprand(r::SparseArrays.AbstractRNG, n::Tuple, args...) = _fsprand_impl(n, sprand(r, mapfoldl(BigInt, *, n), args...))
fsprand(r::SparseArrays.AbstractRNG, T::Type, n::Tuple, args...) = _fsprand_impl(n, sprand(r, T, mapfoldl(BigInt, *, n), args...))
function _fsprand_impl(shape::Tuple, vec::SparseVector{Tv, Ti}) where {Tv, Ti}
    I = ((Vector{Ti}(undef, length(vec.nzind)) for _ in shape)...,)
    for (p, ind) in enumerate(vec.nzind)
        c = CartesianIndices(shape)[ind]
        ntuple(n->I[n][p] = c[n], length(shape))
    end
    return fsparse!(I, vec.nzval, shape)
end

"""
    fspzeros([type], shape::Tuple)

Create a random zero tensor of size `m`, with elements of type `type`. The
tensor is in COO format.

See also: (`spzeros`)(https://docs.julialang.org/en/v1/stdlib/SparseArrays/#SparseArrays.spzeros)

# Examples
```jldoctest
julia> fspzeros(Bool, (3, 3))
SparseCoo (false) [1:3×1:3]
│ │
└─└─
    
julia> fspzeros(Float64, (2, 2, 2))
SparseCoo (0.0) [1:2×1:2×1:2]
│ │ │
└─└─└─
```
"""
fspzeros(shape) = fspzeros(Float64, shape)
function fspzeros(::Type{T}, shape) where {T}
    return fsparse!(((Int[] for _ in shape)...,), T[], shape)
end

"""
    ffindnz(arr)

Return the nonzero elements of `arr`, as Finch understands `arr`. Returns `(I,
V)`, where `I` is a tuple of coordinate vectors, one for each mode of `arr`, and
`V` is a vector of corresponding nonzero values, which can be passed to
[`fsparse`](@ref).

See also: (`findnz`)(https://docs.julialang.org/en/v1/stdlib/SparseArrays/#SparseArrays.findnz)
"""
function ffindnz(src)
    tmp = Fiber(
        SparseCooLevel{ndims(src)}(
        ElementLevel{zero(eltype(src)), eltype(src)}()))
    tmp = copyto!(tmp, src)
    nnz = tmp.lvl.pos[2] - 1
    tbl = tmp.lvl.tbl
    val = tmp.lvl.lvl.val
    (ntuple(n->tbl[n][1:nnz], ndims(src)), val[1:nnz])
end