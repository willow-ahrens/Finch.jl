```@meta
CurrentModule = Finch
```
# Performance Tips for Finch

It's easy to ask Finch to run the same operation in different ways. However,
different approaches have different performance. The right approach really
depends on your particular situation. Here's a collection of general approaches
that help Finch generate faster code in most cases.

## Concordant Iteration

By default, Finch stores arrays in column major order (first index fast). When
the storage order of an array in a Finch expression corresponds to the loop
order, we call this
*concordant* iteration. For example, the following expression represents a
concordant traversal of a sparse matrix, as the outer loops access the higher
levels of the fiber tree:

```jldoctest example1; setup=:(using Finch)
A = @fiber(d(sl(e(0.0))), fsparse(([2, 3, 4, 1, 3], [1, 1, 1, 3, 3]), [1.1, 2.2, 3.3, 4.4, 5.5], (4, 3)))
s = Scalar(0.0)
@finch for j=_, i=_ ; s[] += A[i, j] end

# output

(s = Scalar{0.0, Float64}(16.5),)
```

We can investigate the generated code with `@finch_code`.  This code iterates
over only the nonzeros in order. If our matrix is `m × n` with `nnz` nonzeros,
this takes `O(n + nnz)` time.

```jldoctest example1
@finch_code for j=_, i=_ ; s[] += A[i, j] end

# output

quote
    s = ex.body.body.lhs.tns.tns
    s_val = s.val
    A_lvl = ex.body.body.rhs.tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_3 = A_lvl_2.lvl
    for j_3 = 1:A_lvl.shape
        A_lvl_q = (1 - 1) * A_lvl.shape + j_3
        A_lvl_2_q = A_lvl_2.ptr[A_lvl_q]
        A_lvl_2_q_stop = A_lvl_2.ptr[A_lvl_q + 1]
        if A_lvl_2_q < A_lvl_2_q_stop
            A_lvl_2_i1 = A_lvl_2.idx[A_lvl_2_q_stop - 1]
        else
            A_lvl_2_i1 = 0
        end
        phase_stop = min(A_lvl_2_i1, A_lvl_2.shape)
        if phase_stop >= 1
            i = 1
            if A_lvl_2.idx[A_lvl_2_q] < 1
                A_lvl_2_q = scansearch(A_lvl_2.idx, 1, A_lvl_2_q, A_lvl_2_q_stop - 1)
            end
            while i <= phase_stop
                A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                phase_stop_2 = min(phase_stop, A_lvl_2_i)
                if A_lvl_2_i == phase_stop_2
                    A_lvl_3_val_2 = A_lvl_3.val[A_lvl_2_q]
                    s_val = A_lvl_3_val_2 + s_val
                    A_lvl_2_q += 1
                end
                i = phase_stop_2 + 1
            end
        end
    end
    (s = (Scalar){0.0, Float64}(s_val),)
end
```


When the loop order does not correspond to storage order, we call this
*discordant* iteration. For example, if we swap the loop order in the
above example, then Finch needs to randomly access each sparse column for each
row `i`. We end up needing to find each `(i, j)` pair because we don't know
whether it will be zero until we search for it. In all, this takes time
`O(n * m * log(nnz))`, much less efficient! We shouldn't randomly access sparse
arrays unless we really need to and they support it efficiently!

Note the double for loop in the following code

```jldoctest example1
@finch_code for i=_, j=_ ; s[] += A[i, j] end # DISCORDANT, DO NOT DO THIS

# output

quote
    s = ex.body.body.lhs.tns.tns
    s_val = s.val
    A_lvl = ex.body.body.rhs.tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_3 = A_lvl_2.lvl
    for i_3 = 1:A_lvl_2.shape
        for j_3 = 1:A_lvl.shape
            A_lvl_q = (1 - 1) * A_lvl.shape + j_3
            A_lvl_2_q = A_lvl_2.ptr[A_lvl_q]
            A_lvl_2_q_stop = A_lvl_2.ptr[A_lvl_q + 1]
            if A_lvl_2_q < A_lvl_2_q_stop
                A_lvl_2_i1 = A_lvl_2.idx[A_lvl_2_q_stop - 1]
            else
                A_lvl_2_i1 = 0
            end
            phase_stop = min(A_lvl_2_i1, i_3)
            if phase_stop >= i_3
                s_3 = i_3
                if A_lvl_2.idx[A_lvl_2_q] < i_3
                    A_lvl_2_q = scansearch(A_lvl_2.idx, i_3, A_lvl_2_q, A_lvl_2_q_stop - 1)
                end
                while s_3 <= phase_stop
                    A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                    phase_stop_2 = min(phase_stop, A_lvl_2_i)
                    if A_lvl_2_i == phase_stop_2
                        A_lvl_3_val_2 = A_lvl_3.val[A_lvl_2_q]
                        s_val = A_lvl_3_val_2 + s_val
                        A_lvl_2_q += 1
                    end
                    s_3 = phase_stop_2 + 1
                end
            end
        end
    end
    (s = (Scalar){0.0, Float64}(s_val),)
end
```

### TL;DR
As a quick heuristic, if your array indices are all in alphabetical order, then
the loop indices should be reverse alphabetical.

## Appropriate Fill Values

The @finch macro requires the user to specify an output format. This is the most
flexibile approach, but can sometimes lead to densification unless the output
fill value is appropriate for the computation.

For example, if `A` is `m × n` with `nnz` nonzeros, the following Finch kernel will
densify `B`, filling it with `m * n` stored values:

```jldoctest example1
A = @fiber(d(sl(e(0.0))), fsparse(([2, 3, 4, 1, 3], [1, 1, 1, 3, 3]), [1.1, 2.2, 3.3, 4.4, 5.5], (4, 3)))
B = @fiber(d(sl(e(0.0)))) #DO NOT DO THIS, B has the wrong fill value
@finch (B .= 0; for j=_, i=_; B[i, j] = A[i, j] + 1 end)
countstored(B)

# output

12
```

Since `A` is filled with `0.0`, adding `1` to the fill value produces `1.0`. However, `B` can only represent a fill value of `0.0`. Instead, we should specify `1.0` for the fill.

```jldoctest example1
A = @fiber(d(sl(e(0.0))), fsparse(([2, 3, 4, 1, 3], [1, 1, 1, 3, 3]), [1.1, 2.2, 3.3, 4.4, 5.5], (4, 3)))
B = @fiber(d(sl(e(1.0))))
@finch (B .= 1; for j=_, i=_; B[i, j] = A[i, j] + 1 end)
countstored(B)

# output

5
```

## Static Versus Dynamic Values

In order to skip some computations, Finch must be able to determine the value of
program variables. Continuing our above example, if we obscure the value of `1`
behind a variable `x`, Finch can only determine that `x` has type `Int`, not that it is `1`.

```jldoctest example1
A = @fiber(d(sl(e(0.0))), fsparse(([2, 3, 4, 1, 3], [1, 1, 1, 3, 3]), [1.1, 2.2, 3.3, 4.4, 5.5], (4, 3)))
B = @fiber(d(sl(e(1.0))))
x = 1 #DO NOT DO THIS, Finch cannot see the value of x anymore
@finch (B .= 1; for j=_, i=_; B[i, j] = A[i, j] + x end)
countstored(B)

# output

12
```

However, there are some situations where you may want a value to be dynamic. For example, consider the function `saxpy(x, a, y) = x .* a .+ y`. Because we do not know the value of `a` until we run the function, we should treat it as dynamic, and the following implementation is reasonable:

```julia
function saxpy(x, a, y)
    z = @fiber(sl(e(0.0)))
    @finch (z .= 0; for i=_; z[i] = a * x[i] + y[i] end)
end
```

## Use Known Functions

Unless you declare the properties of your functions using Finch's [algebra
traits system](@ref /algebra), Finch doesn't know how they work. For example, using a lambda obscures
the meaning of `*`.

```jldoctest example1
A = @fiber(d(sl(e(0.0))), fsparse(([2, 3, 4, 1, 3], [1, 1, 1, 3, 3]), [1.1, 2.2, 3.3, 4.4, 5.5], (4, 3)))
B = ones(4, 3)
C = @fiber(d(sl(e(0.0))))
f(x, y) = x * y # DO NOT DO THIS, Obscures *
@finch (C .= 0; for j=_, i=_; C[i, j] = f(A[i, j], B[i, j]) end)
countstored(C)

# output

12
```

Checking the generated code, we see that this code is indeed densifying (notice the for-loop which repeatedly evaluates `f(B[i, j], 0.0)`).

```jldoctest example1
@finch_code (C .= 0; for j=_, i=_; C[i, j] = f(A[i, j], B[i, j]) end)

# output

quote
    C_lvl = (ex.bodies[1]).tns.tns.lvl
    C_lvl_2 = C_lvl.lvl
    C_lvl_3 = C_lvl_2.lvl
    A_lvl = ((ex.bodies[2]).body.body.rhs.args[1]).tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_3 = A_lvl_2.lvl
    B = ((ex.bodies[2]).body.body.rhs.args[2]).tns.tns
    sugar_1 = size(B)
    B_mode1_stop = sugar_1[1]
    B_mode2_stop = sugar_1[2]
    A_lvl_2.shape == B_mode1_stop || throw(DimensionMismatch("mismatched dimension limits ($(A_lvl_2.shape) != $(B_mode1_stop))"))
    A_lvl.shape == B_mode2_stop || throw(DimensionMismatch("mismatched dimension limits ($(A_lvl.shape) != $(B_mode2_stop))"))
    C_lvl_2_qos_fill = 0
    C_lvl_2_qos_stop = 0
    p_start_2 = A_lvl.shape
    resize_if_smaller!(C_lvl_2.ptr, p_start_2 + 1)
    fill_range!(C_lvl_2.ptr, 0, 1 + 1, p_start_2 + 1)
    for j_5 = 1:A_lvl.shape
        C_lvl_q = (1 - 1) * A_lvl.shape + j_5
        A_lvl_q = (1 - 1) * A_lvl.shape + j_5
        C_lvl_2_qos = C_lvl_2_qos_fill + 1
        A_lvl_2_q = A_lvl_2.ptr[A_lvl_q]
        A_lvl_2_q_stop = A_lvl_2.ptr[A_lvl_q + 1]
        if A_lvl_2_q < A_lvl_2_q_stop
            A_lvl_2_i1 = A_lvl_2.idx[A_lvl_2_q_stop - 1]
        else
            A_lvl_2_i1 = 0
        end
        i = 1
        phase_stop = min(A_lvl_2.shape, A_lvl_2_i1)
        if phase_stop >= 1
            i = 1
            if A_lvl_2.idx[A_lvl_2_q] < 1
                A_lvl_2_q = scansearch(A_lvl_2.idx, 1, A_lvl_2_q, A_lvl_2_q_stop - 1)
            end
            while i <= phase_stop
                A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                phase_stop_2 = min(phase_stop, A_lvl_2_i)
                if A_lvl_2_i == phase_stop_2
                    for i_7 = i:phase_stop_2 - 1
                        if C_lvl_2_qos > C_lvl_2_qos_stop
                            C_lvl_2_qos_stop = max(C_lvl_2_qos_stop << 1, 1)
                            resize_if_smaller!(C_lvl_2.idx, C_lvl_2_qos_stop)
                            resize_if_smaller!(C_lvl_3.val, C_lvl_2_qos_stop)
                            fill_range!(C_lvl_3.val, 0.0, C_lvl_2_qos, C_lvl_2_qos_stop)
                        end
                        C_lvl_3.val[C_lvl_2_qos] = f(0.0, B[i_7, j_5])
                        C_lvl_2.idx[C_lvl_2_qos] = i_7
                        C_lvl_2_qos += 1
                    end
                    A_lvl_3_val_2 = A_lvl_3.val[A_lvl_2_q]
                    if C_lvl_2_qos > C_lvl_2_qos_stop
                        C_lvl_2_qos_stop = max(C_lvl_2_qos_stop << 1, 1)
                        resize_if_smaller!(C_lvl_2.idx, C_lvl_2_qos_stop)
                        resize_if_smaller!(C_lvl_3.val, C_lvl_2_qos_stop)
                        fill_range!(C_lvl_3.val, 0.0, C_lvl_2_qos, C_lvl_2_qos_stop)
                    end
                    C_lvl_3.val[C_lvl_2_qos] = f(A_lvl_3_val_2, B[phase_stop_2, j_5])
                    C_lvl_2.idx[C_lvl_2_qos] = phase_stop_2
                    C_lvl_2_qos += 1
                    A_lvl_2_q += 1
                else
                    for i_9 = i:phase_stop_2
                        if C_lvl_2_qos > C_lvl_2_qos_stop
                            C_lvl_2_qos_stop = max(C_lvl_2_qos_stop << 1, 1)
                            resize_if_smaller!(C_lvl_2.idx, C_lvl_2_qos_stop)
                            resize_if_smaller!(C_lvl_3.val, C_lvl_2_qos_stop)
                            fill_range!(C_lvl_3.val, 0.0, C_lvl_2_qos, C_lvl_2_qos_stop)
                        end
                        C_lvl_3.val[C_lvl_2_qos] = f(0.0, B[i_9, j_5])
                        C_lvl_2.idx[C_lvl_2_qos] = i_9
                        C_lvl_2_qos += 1
                    end
                end
                i = phase_stop_2 + 1
            end
            i = phase_stop + 1
        end
        phase_stop_3 = A_lvl_2.shape
        if phase_stop_3 >= i
            for i_11 = i:phase_stop_3
                if C_lvl_2_qos > C_lvl_2_qos_stop
                    C_lvl_2_qos_stop = max(C_lvl_2_qos_stop << 1, 1)
                    resize_if_smaller!(C_lvl_2.idx, C_lvl_2_qos_stop)
                    resize_if_smaller!(C_lvl_3.val, C_lvl_2_qos_stop)
                    fill_range!(C_lvl_3.val, 0.0, C_lvl_2_qos, C_lvl_2_qos_stop)
                end
                C_lvl_3.val[C_lvl_2_qos] = f(0.0, B[i_11, j_5])
                C_lvl_2.idx[C_lvl_2_qos] = i_11
                C_lvl_2_qos += 1
            end
        end
        C_lvl_2.ptr[C_lvl_q + 1] = (C_lvl_2_qos - C_lvl_2_qos_fill) - 1
        C_lvl_2_qos_fill = C_lvl_2_qos - 1
    end
    for p = 2:A_lvl.shape + 1
        C_lvl_2.ptr[p] += C_lvl_2.ptr[p - 1]
    end
    qos = 1 * A_lvl.shape
    resize!(C_lvl_2.ptr, qos + 1)
    qos_2 = C_lvl_2.ptr[end] - 1
    resize!(C_lvl_2.idx, qos_2)
    resize!(C_lvl_3.val, qos_2)
    (C = Fiber((DenseLevel){Int64}((SparseListLevel){Int64, Int64}(C_lvl_3, A_lvl_2.shape, C_lvl_2.ptr, C_lvl_2.idx), A_lvl.shape)),)
end

```