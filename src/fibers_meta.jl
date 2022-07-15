fiber!(arr, default=zero(eltype(arr))) = fiber(arr, default=default)
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

function SparseArrays.sparse(I::Tuple, V::Vector, shape = map(maximum, I), combine = eltype(V) isa Bool ? (|) : (+))
    C = map(tuple, I)
    update = false
    if !issorted(C)
        P = sortperm!(C)
        C = C[P]
        V = V[P]
        update = true
    end
    if !isunique(C)
        P = unique!(p -> C, 1:length(C))
        C = C[P]
        push!(P, length(C))
        V = map((start, stop) -> foldl(combine, @view V[start:stop]), P[1:end - 1], P[2:end])
        update = true
    end
    I = map(copy, I)
    update && foreach((p, c) -> ntuple(n->I[n][p] = c[n]), enumerate(C))
    return fsparse!(I, V, shape)
end
function sparse!(I::Tuple, V, shape = map(maximum, I))
    return Fiber(HollowCoo{length(I), Tuple{map(eltype, I)...}, Int}(shape, I, [1, length(I[1]) + 1], Element{zero(eltype(V))}(V)))
end

SparseArrays.sprand(n::Tuple, args...) = _sprand_impl(n, sprand(mapfoldl(BigInt, *, n), args...))
SparseArrays.sprand(r::SparseArrays.AbstractRNG, n::Tuple, args...) = _sprand_impl(r, n, sprand(mapfoldl(BigInt, *, n), args...))
SparseArrays.sprand(r::SparseArrays.AbstractRNG, T::Type, n::Tuple, args...) = _sprand_impl(r, T, n, sprand(mapfoldl(BigInt, *, n), args...))
function _sprand_impl(shape::Tuple, vec::SparseVector{Ti, Tv}) where {Ti, Tv}
    I = ((Vector(undef, length(vec.nzind)) for _ in shape)...,)
    for (p, ind) in enumerate(vec.nzind)
        c = CartesianIndices(reverse(shape))[ind]
        ntuple(n->I[n][p] = c[length(shape) - n + 1], length(shape))
    end
    return sparse!(I, vec.nzval, shape)
end

SparseArrays.spzeros(shape) = spzeros(Float64, shape)
function SparseArrays.spzeros(::Type{T}, shape) where {T}
    return sparse!(((Int[] for _ in shape)...,), T[], shape)
end