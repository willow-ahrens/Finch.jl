"""
    fsparse(I::Tuple, V,[ M::Tuple, combine])

Create a sparse COO tensor `S` such that `size(S) == M` and `S[(i[q] for i =
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
fsparse(iV::AbstractVector, args...) = fsparse_parse((), iV, args...)
fsparse_parse(I, i::AbstractVector, args...) = fsparse_parse((I..., i), args...)
fsparse_parse(I, V::AbstractVector) = fsparse_impl(I, V)
fsparse_parse(I, V::AbstractVector, m::Tuple) = fsparse_impl(I, V, m)
fsparse_parse(I, V::AbstractVector, m::Tuple, combine) = fsparse_impl(I, V, m, combine)
function fsparse_impl(I::Tuple, V::Vector, shape = map(maximum, I), combine = eltype(V) isa Bool ? (|) : (+))
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
        I = reverse(I)
    else
        I = map(copy, I)
    end
    return fsparse!(I..., V, shape)
end

"""
    fsparse!(I..., V,[ M::Tuple])

Like [`fsparse`](@ref), but the coordinates must be sorted and unique, and memory
is reused.
"""
fsparse!(args...) = fsparse!_parse((), args...)
fsparse!_parse(I, i::AbstractVector, args...) = fsparse!_parse((I..., i), args...)
fsparse!_parse(I, V::AbstractVector) = fsparse!_impl(I, V)
fsparse!_parse(I, V::AbstractVector, M::Tuple) = fsparse!_impl(I, V, M)
function fsparse!_impl(I::Tuple, V, shape = map(maximum, I))
    return Tensor(SparseCOO{length(I), Tuple{map(eltype, I)...}}(Element{zero(eltype(V)), eltype(V), Int}(V), shape, [1, length(V) + 1], I))
end

"""
    fsprand([rng],[type], M..., p::AbstractFloat,[rfn])

Create a random sparse tensor of size `m` in COO format, in which the
probability of any element being nonzero is independently given by `p` (and
hence the mean density of nonzeros is also exactly `p`). Nonzero values are
sampled from the distribution specified by `rfn` and have the type `type`. The
uniform distribution is used in case `rfn` is not specified. The optional `rng`
argument specifies a random number generator.

See also: (`sprand`)(https://docs.julialang.org/en/v1/stdlib/SparseArrays/#SparseArrays.sprand)

# Examples
```julia
julia> fsprand(Bool, 3, 3, 0.5)
SparseCOO (false) [1:3,1:3]
├─├─[1, 1]: true
├─├─[3, 1]: true
├─├─[2, 2]: true
├─├─[3, 2]: true
├─├─[3, 3]: true

julia> fsprand(Float64, 2, 2, 2, 0.5)
SparseCOO (0.0) [1:2,1:2,1:2]
├─├─├─[2, 2, 1]: 0.6478553157718558
├─├─├─[1, 1, 2]: 0.996665291437684
├─├─├─[2, 1, 2]: 0.7491940599574348
```
"""
fsprand(args...) = fsprand_parse_rng(args...)

fsprand_parse_rng(r::AbstractRNG, args...) = fsprand_parse_type(r, args...)
fsprand_parse_rng(args...) = fsprand_parse_type(default_rng(), args...)

fsprand_parse_type(r, T::Type, args...) = fsprand_parse_shape(r, (T,), (), args...)
fsprand_parse_type(r, args...) = fsprand_parse_shape(r, (), (), args...)

fsprand_parse_shape(r, T, M, m, args...) = fsprand_parse_shape(r, T, (M..., m), args...)
fsprand_parse_shape(r, T, M, p::AbstractFloat, rfn=rand) = fsprand_impl(r, T, M, p, rfn)
fsprand_parse_shape(r, T, M) = ArgumentError("No float p given to fsprand")

function fsprand_impl(r::AbstractRNG, T, M::Tuple, p::AbstractFloat, rfn)
    I = fsprand_helper(r, M, p)
    V = rfn(r, T..., length(I[1]))
    return fsparse!(I..., V, M)
end

function fsprand_helper(r::AbstractRNG, M::Tuple, p::AbstractFloat)
    I = map(shape -> Vector{typeof(shape)}(), M)
    for i in randsubseq(r, CartesianIndices(M), p)
        for r = 1:length(M)
            push!(I[r], i[r])
        end
    end
    I
end

fsprandn(args...) = fsprand(args..., randn)

"""
    fspzeros([type], M::Tuple)

Create a random zero tensor of size `M`, with elements of type `type`. The
tensor is in COO format.

See also: (`spzeros`)(https://docs.julialang.org/en/v1/stdlib/SparseArrays/#SparseArrays.spzeros)

# Examples
```jldoctest
julia> fspzeros(Bool, 3, 3)
SparseCOO{2} (false) [:,1:3]

julia> fspzeros(Float64, 2, 2, 2)
SparseCOO{3} (0.0) [:,:,1:2]
```
"""
fspzeros(M...) = fspzeros(Float64, M...)
function fspzeros(::Type{T}, M...) where {T}
    return fsparse!((Int[] for _ in M)..., T[], M)
end

"""
    ffindnz(arr)

Return the nonzero elements of `arr`, as Finch understands `arr`. Returns `(I...,
V)`, where `I` are the coordinate vectors, one for each mode of `arr`, and
`V` is a vector of corresponding nonzero values, which can be passed to
[`fsparse`](@ref).

See also: (`findnz`)(https://docs.julialang.org/en/v1/stdlib/SparseArrays/#SparseArrays.findnz)
"""
function ffindnz(src)
    tmp = Tensor(
        SparseCOOLevel{ndims(src)}(
            ElementLevel{zero(eltype(src)), eltype(src)}()))
    tmp = copyto!(tmp, src)
    nnz = tmp.lvl.ptr[2] - 1
    tbl = tmp.lvl.tbl
    val = tmp.lvl.lvl.val
    (ntuple(n->tbl[n][1:nnz], ndims(src))..., val[1:nnz])
end
