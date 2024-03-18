@staged function copyto_helper!(dst, src)
    ndims(dst) > ndims(src) && throw(DimensionMismatch("more dimensions in destination than source"))
    ndims(dst) < ndims(src) && throw(DimensionMismatch("less dimensions in destination than source"))
    idxs = [Symbol(:i_, n) for n = 1:ndims(dst)]
    exts = Expr(:block, (:($idx = _) for idx in reverse(idxs))...)
    return quote
        @finch mode=fastfinch begin
            dst .= $(default(dst))
            $(Expr(:for, exts, quote
                dst[$(idxs...)] = src[$(idxs...)]
            end))
        end
        return dst
    end
end

function Base.copyto!(dst::Tensor, src::Union{Tensor, AbstractArray})
    return copyto_helper!(dst, src)
end

function Base.copyto!(dst::Array, src::Tensor)
    return copyto_helper!(dst, src)
end

function Base.permutedims(src::Tensor)
    @assert ndims(src) == 2
    permutedims(src, (2, 1))
end
function Base.permutedims(src::Tensor, perm)
    dst = similar(src)
    copyto!(dst, swizzle(src, perm...))
end

# I'm not sure if this is the right way for specializing types (breaking Union from below) but
# without it there's:
# MethodError: copyto!(::Vector{Float64}, ::Finch.SwizzleArray{(2, 3, 1), Tensor{DenseLevel{Int64,
#   DenseLevel{Int64, DenseLevel{Int64, ElementLevel{0.0, Float64, Int64, Vector{Float64}}}}}}}) is ambiguous.
#
function Base.copyto!(dst::AbstractArray, src::SwizzleArray{dims}) where {dims}
    ret = copyto!(swizzle(dst, invperm(dims)...), src.body)
    return ret.body
end

function Base.copyto!(dst::Union{Tensor, AbstractArray}, src::SwizzleArray{dims}) where {dims}
    ret = copyto!(swizzle(dst, invperm(dims)...), src.body)
    return ret.body
end

function Base.copyto!(dst::SwizzleArray{dims1}, src::SwizzleArray{dims2}) where {dims1, dims2}
    ret = copyto!(swizzle(dst, invperm(dims2)...), src.body)
    return swizzle(ret, dims2...)
end

function Base.copyto!(dst::SwizzleArray{dims}, src::Union{Tensor, AbstractArray}) where {dims}
    tmp = Tensor(SparseHash{ndims(src)}(Element(default(src))))
    tmp = copyto_helper!(swizzle(tmp, dims...), src).body
    swizzle(copyto_helper!(dst.body, tmp), dims...)
end

"""
    dropdefaults(src)

Drop the default values from `src` and return a new tensor with the same shape and
format.
"""
dropdefaults(src) = dropdefaults!(similar(src), src)

"""
    dropdefaults!(dst, src)

Copy only the non- default values from `src` into `dst`. The shape and format of
`dst` must match `src`
"""
dropdefaults!(dst::Tensor, src) = dropdefaults_helper!(dst, src)

@staged function dropdefaults_helper!(dst, src)
    ndims(dst) > ndims(src) && throw(DimensionMismatch("more dimensions in destination than source"))
    ndims(dst) < ndims(src) && throw(DimensionMismatch("less dimensions in destination than source"))
    idxs = [Symbol(:i_, n) for n = 1:ndims(dst)]
    exts = Expr(:block, (:($idx = _) for idx in reverse(idxs))...)
    T = eltype(dst)
    d = default(dst)
    return quote
        tmp = Scalar{$d, $T}()
        @finch begin
            dst .= $(default(dst))
            $(Expr(:for, exts, quote
                tmp .= $(default(dst))
                tmp[] = src[$(idxs...)]
                if !isequal(tmp[], $d)
                    dst[$(idxs...)] = tmp[]
                end
            end))
        end
        return dst
    end
end