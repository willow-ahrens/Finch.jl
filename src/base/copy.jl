@generated function copyto_helper!(dst, src)
    ndims(dst) > ndims(src) && throw(DimensionMismatch("more dimensions in destination than source"))
    ndims(dst) < ndims(src) && throw(DimensionMismatch("less dimensions in destination than source"))
    idxs = [Symbol(:i_, n) for n = 1:ndims(dst)]
    return quote
        @finch begin
            dst .= $(default(dst))
            @loop($(reverse(idxs)...), dst[$(idxs...)] = src[$(idxs...)])
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

dropdefaults(src) = dropdefaults!(similar(src), src)

@generated function dropdefaults!(dst::Fiber, src)
    ndims(dst) > ndims(src) && throw(DimensionMismatch("more dimensions in destination than source"))
    ndims(dst) < ndims(src) && throw(DimensionMismatch("less dimensions in destination than source"))
    idxs = [Symbol(:i_, n) for n = 1:ndims(dst)]
    T = eltype(dst)
    d = default(dst)
    return quote
        tmp = Scalar{$d, $T}()
        @finch begin
            dst .= $(default(dst))
            @loop $(reverse(idxs)...) begin
                tmp .= $(default(dst))
                tmp[] = src[$(idxs...)]
                if !isequal(tmp[], $d)
                    dst[$(idxs...)] = tmp[]
                end
            end
        end
        return dst
    end
end