@staged function copyto_helper!(dst, src)
    ndims(dst) > ndims(src) && throw(DimensionMismatch("more dimensions in destination than source"))
    ndims(dst) < ndims(src) && throw(DimensionMismatch("less dimensions in destination than source"))
    idxs = [Symbol(:i_, n) for n = 1:ndims(dst)]
    exts = Expr(:block, (:($idx = _) for idx in reverse(idxs))...)
    return quote
        @finch begin
            dst .= $(default(dst))
            $(Expr(:for, exts, quote
                dst[$(idxs...)] = src[$(idxs...)]
            end))
        end
        return dst
    end
end

function Base.copyto!(dst::Fiber, src::Union{Fiber, AbstractArray})
    return copyto_helper!(dst, src)
end

function Base.copyto!(dst::Array, src::Fiber)
    return copyto_helper!(dst, src)
end

function permutedims(src::Fiber, perm)
    dst = similar(src)
    copyto!(dst, swizzle(src, perm...))
end

function Base.copyto!(dst::Fiber, src::SwizzleArray)
    copyto!(swizzle(dst, (1:ndims(dst))...), src)
end

function Base.copyto!(dst::SwizzleArray, src::Union{Fiber, AbstractArray})
    copyto!(dst, swizzle(src, (1:ndims(src))...))
end

function Base.copyto!(dst::SwizzleArray{dims}, src::SwizzleArray) where {dims}
    tmp = Fiber!(SparseHash{ndims(src)}(Element(default(src))))
    tmp = copyto_helper!(tmp, swizzle(src, dims...))
    copyto_helper!(dst.body, tmp)
    dst
end

dropdefaults(src) = dropdefaults!(similar(src), src)

dropdefaults!(dst::Fiber, src) = dropdefaults_helper!(dst, src)

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