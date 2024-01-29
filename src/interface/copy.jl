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

function permutedims(src::Tensor, perm)
    dst = similar(src)
    return copyto!(dst, swizzle(src, perm...))
end

function Base.copyto!(dst::Union{Tensor, AbstractArray}, src::SwizzleArray{dims}) where {dims}
    ret = copyto!(swizzle(dst, invperm(dims)...), src.body)
    return ret
end

function Base.copyto!(dst::SwizzleArray{dims1}, src::SwizzleArray{dims2}) where {dims1, dims2}
    ret = copyto!(swizzle(dst, invperm(dims2)[collect(dims1)]...), src.body)
    return ret
end

function Base.copyto!(dst::SwizzleArray{dims}, src::Union{Tensor, AbstractArray}) where {dims}
    tmp = Tensor(SparseHash{ndims(src)}(Element(default(src))))
    tmp = copyto_helper!(swizzle(tmp, dims...), src)
    return copyto_helper!(swizzle(dst.body, dims...), tmp)
end

dropdefaults(src) = dropdefaults!(similar(src), src)

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