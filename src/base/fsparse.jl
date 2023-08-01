"""
    fiber!(arr, default = zero(eltype(arr)))

Like [`fiber`](@ref), copies an array-like object `arr` into a corresponding,
similar `Fiber` datastructure. However, `fiber!` reuses memory whenever
possible, meaning `arr` may be rendered unusable.
"""
fiber!(arr; default=zero(eltype(arr))) = fiber(arr, default=default)

"""
    fiber(arr, default = zero(eltype(arr)))

Copies an array-like object `arr` into a corresponding, similar `Fiber`
datastructure. `default` is the default value to use for initialization and
sparse compression.

See also: [`fiber!`](@ref)

# Examples

```jldoctest
julia> println(summary(fiber(sparse([1 0; 0 1]))))
2×2 Fiber!(Dense(SparseList(Element(0))))

julia> println(summary(fiber(ones(3, 2, 4))))
3×2×4 Fiber!(Dense(Dense(Dense(Element(0.0)))))
```
"""
function fiber(arr; default=zero(eltype(arr)))
    Base.copyto!(Fiber((DenseLevel^(ndims(arr)))(Element{default}())), arr)
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
SparseCOO (0.0) [1:3×1:3×1:3]
│ │ │ 
└─└─└─[1, 1, 1] [2, 2, 2] [3, 3, 3]
      1.0       2.0       3.0    
"""
function fsparse(I::Tuple, V::Vector, shape = map(maximum, I), combine = eltype(V) isa Bool ? (|) : (+))
    C = map(tuple, reverse(I)...)
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
    return Fiber(SparseCOO{length(I), Tuple{map(eltype, I)...}, Int}(Element{zero(eltype(V))}(V), shape, I, [1, length(V) + 1]))
end
#, filter = r".*"s
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
```julia
julia> fsprand(Bool, (3, 3), 0.5)
SparseCOO (false) [1:3,1:3]
├─├─[1, 1]: true
├─├─[3, 1]: true
├─├─[2, 2]: true
├─├─[3, 2]: true
├─├─[3, 3]: true  

julia> fsprand(Float64, (2, 2, 2), 0.5)
SparseCOO (0.0) [1:2,1:2,1:2]
├─├─├─[2, 2, 1]: 0.6478553157718558
├─├─├─[1, 1, 2]: 0.996665291437684
├─├─├─[2, 1, 2]: 0.7491940599574348 
```
"""
fsprand(shape::Tuple, p::AbstractFloat, rfn::Function, ::Type{T}) where {T} = fsprand(default_rng(), shape, p, rfn, T)
function fsprand(r::AbstractRNG, shape::Tuple, p::AbstractFloat, rfn::Function, ::Type{T}) where T
    I = fsprand_helper(r, shape, p)
    V = rfn(r, T, length(I[1]))
    return fsparse!(I, V, shape)
end

fsprand(shape::Tuple, p::AbstractFloat, rfn::Function) = fsprand(default_rng(), shape, p, rfn)
function fsprand(r::AbstractRNG, shape::Tuple, p::AbstractFloat, rfn::Function)
    I = fsprand_helper(r, shape, p)
    V = rfn(r, length(I[1]))
    return fsparse!(I, V, shape)
end

function fsprand_helper(r::AbstractRNG, shape::Tuple, p::AbstractFloat)
    I = map(shape -> Vector{typeof(shape)}(), shape)
    for i in randsubseq(r, CartesianIndices(shape), p)
        for r = 1:length(shape)
            push!(I[r], i[r])
        end
    end
    I
end

fsprand(shape::Tuple, p::AbstractFloat) = fsprand(default_rng(), shape, p, rand)

fsprand(r::AbstractRNG, shape::Tuple, p::AbstractFloat) = fsprand(r, shape, p, rand)
fsprand(r::AbstractRNG, ::Type{T}, shape::Tuple, p::AbstractFloat) where {T} = fsprand(r, shape, p, (r, i) -> rand(r, T, i))
fsprand(r::AbstractRNG, ::Type{Bool}, shape::Tuple, p::AbstractFloat) = fsprand(r, shape, p, (r, i) -> fill(true, i))
fsprand(::Type{T}, shape::Tuple, p::AbstractFloat) where {T} = fsprand(default_rng(), T, shape, p)

fsprandn(shape::Tuple, p::AbstractFloat) = fsprand(default_rng(), shape, p, randn)
fsprandn(r::AbstractRNG, shape::Tuple, p::AbstractFloat) = fsprand(r, shape, p, randn)
fsprandn(::Type{T}, shape::Tuple, p::AbstractFloat) where T = fsprand(default_rng(), shape, p, (r, i) -> randn(r, T, i))
fsprandn(r::AbstractRNG, ::Type{T}, shape::Tuple, p::AbstractFloat) where T = fsprand(r, shape, p, (r, i) -> randn(r, T, i))

"""
    fspzeros([type], shape::Tuple)

Create a random zero tensor of size `m`, with elements of type `type`. The
tensor is in COO format.

See also: (`spzeros`)(https://docs.julialang.org/en/v1/stdlib/SparseArrays/#SparseArrays.spzeros)

# Examples
```jldoctest
julia> fspzeros(Bool, (3, 3))
SparseCOO (false) [1:3,1:3]
    
julia> fspzeros(Float64, (2, 2, 2))
SparseCOO (0.0) [1:2,1:2,1:2]
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
        SparseCOOLevel{ndims(src)}(
        ElementLevel{zero(eltype(src)), eltype(src)}()))
    tmp = copyto!(tmp, src)
    nnz = tmp.lvl.ptr[2] - 1
    tbl = tmp.lvl.tbl
    val = tmp.lvl.lvl.val
    (ntuple(n->tbl[n][1:nnz], ndims(src)), val[1:nnz])
end