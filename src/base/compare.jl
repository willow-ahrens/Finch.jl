@generated function helper_equal(A, B)
    idxs = [Symbol(:i_, n) for n = 1:ndims(A)]
    return quote
        size(A) == size(B) || return false
        check = Scalar(true)
        @finch @loop($(reverse(idxs)...), check[] &= (A[$(idxs...)] == B[$(idxs...)]))
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
        @finch @loop($(reverse(idxs)...), check[] &= isequal(A[$(idxs...)], B[$(idxs...)]))
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