function fill_range!(arr, v, i, j)
    @simd for k = i:j
        arr[k] = v
    end
    arr
end

function resize_if_smaller!(arr, i)
    if length(arr) < i
        resize!(arr, i)
    end
end

"""
    scansearch(v, x, lo, hi)

return the first value of `v` greater than or equal to `x`, within the range
`lo:hi`. Return `hi+1` if all values are less than `x`. This implemantation uses an
exponential search strategy which involves two steps: 1) searching for binary search bounds
via exponential steps rightward 2) binary searching within those bounds.
"""
Base.@propagate_inbounds function scansearch(v, x, lo::T1, hi::T2) where {T1<:Integer, T2<:Integer} # TODO types for `lo` and `hi` #406
    u = T1(1)
    d = T1(1)
    p = lo
    while p < hi && v[p] < x
        d *= 2
        p +=  d
    end
    lo = p - d
    hi = min(p, hi) + u

    while lo < hi - u
        m = lo + ((hi - lo) >>> 0x01)
        if v[m] < x
            lo = m
        else
            hi = m
        end
    end
    return hi
end

Base.@propagate_inbounds function bin_scansearch(v, x, lo::T1, hi::T2) where {T1<:Integer, T2<:Integer} # TODO types for `lo` and `hi` #406
    u = T1(1)
    stop = min(hi, lo + T1(32))
    while lo + u < stop && v[lo] < x
        lo += u
    end
    lo = lo - u
    hi = hi + u
    while lo < hi - u
        m = lo + ((hi - lo) >>> 0x01)
        if v[m] < x
            lo = m
        else
            hi = m
        end
    end
    return hi
end
