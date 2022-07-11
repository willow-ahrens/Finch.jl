fiber!(arr, default=zero(eltype(arr))) = fiber(arr, default=default)
function fiber(arr, default=zero(eltype(arr)))
    Base.copyto!(Fiber(SolidLevel^(ndims(arr))(Element(default))), src)
end

@generated function Base.copyto!(dst::Fiber, src)
    dst = virtualize(:dst, dst, LowerJulia())
    idxs = [Symbol(:i_, n) for n = getsites(dst)]
    return quote
        @index @loop($(idxs...), dst[$(idxs...)] = src[$(idxs...)])
        return dst
    end
end