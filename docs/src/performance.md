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
A = Fiber!(Dense(SparseList(Element(0.0))), fsparse([2, 3, 4, 1, 3], [1, 1, 1, 3, 3], [1.1, 2.2, 3.3, 4.4, 5.5], (4, 3)))
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
    s = ex.body.body.lhs.tns.bind
    s_val = s.val
    A_lvl = ex.body.body.rhs.tns.bind.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_ptr = A_lvl_2.ptr
    A_lvl_idx = A_lvl_2.idx
    A_lvl_2_val = A_lvl_2.lvl.val
    for j_3 = 1:A_lvl.shape
        A_lvl_q = (1 - 1) * A_lvl.shape + j_3
        A_lvl_2_q = A_lvl_ptr[A_lvl_q]
        A_lvl_2_q_stop = A_lvl_ptr[A_lvl_q + 1]
        if A_lvl_2_q < A_lvl_2_q_stop
            A_lvl_2_i1 = A_lvl_idx[A_lvl_2_q_stop - 1]
        else
            A_lvl_2_i1 = 0
        end
        phase_stop = min(A_lvl_2_i1, A_lvl_2.shape)
        if phase_stop >= 1
            if A_lvl_idx[A_lvl_2_q] < 1
                A_lvl_2_q = Finch.scansearch(A_lvl_idx, 1, A_lvl_2_q, A_lvl_2_q_stop - 1)
            end
            while true
                A_lvl_2_i = A_lvl_idx[A_lvl_2_q]
                if A_lvl_2_i < phase_stop
                    A_lvl_3_val = A_lvl_2_val[A_lvl_2_q]
                    s_val = A_lvl_3_val + s_val
                    A_lvl_2_q += 1
                else
                    phase_stop_3 = min(phase_stop, A_lvl_2_i)
                    if A_lvl_2_i == phase_stop_3
                        A_lvl_3_val = A_lvl_2_val[A_lvl_2_q]
                        s_val = s_val + A_lvl_3_val
                        A_lvl_2_q += 1
                    end
                    break
                end
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
    s = ex.body.body.lhs.tns.bind
    s_val = s.val
    A_lvl = ex.body.body.rhs.tns.bind.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_ptr = A_lvl_2.ptr
    A_lvl_idx = A_lvl_2.idx
    A_lvl_2_val = A_lvl_2.lvl.val
    @warn "Performance Warning: non-concordant traversal of A[i, j] (hint: most arrays prefer column major or first index fast, run in fast mode to ignore this warning)"
    for i_3 = 1:A_lvl_2.shape
        for j_3 = 1:A_lvl.shape
            A_lvl_q = (1 - 1) * A_lvl.shape + j_3
            A_lvl_2_q = A_lvl_ptr[A_lvl_q]
            A_lvl_2_q_stop = A_lvl_ptr[A_lvl_q + 1]
            if A_lvl_2_q < A_lvl_2_q_stop
                A_lvl_2_i1 = A_lvl_idx[A_lvl_2_q_stop - 1]
            else
                A_lvl_2_i1 = 0
            end
            phase_stop = min(i_3, A_lvl_2_i1)
            if phase_stop >= i_3
                if A_lvl_idx[A_lvl_2_q] < i_3
                    A_lvl_2_q = Finch.scansearch(A_lvl_idx, i_3, A_lvl_2_q, A_lvl_2_q_stop - 1)
                end
                while true
                    A_lvl_2_i = A_lvl_idx[A_lvl_2_q]
                    if A_lvl_2_i < phase_stop
                        A_lvl_3_val = A_lvl_2_val[A_lvl_2_q]
                        s_val = A_lvl_3_val + s_val
                        A_lvl_2_q += 1
                    else
                        phase_stop_3 = min(phase_stop, A_lvl_2_i)
                        if A_lvl_2_i == phase_stop_3
                            A_lvl_3_val = A_lvl_2_val[A_lvl_2_q]
                            s_val = s_val + A_lvl_3_val
                            A_lvl_2_q += 1
                        end
                        break
                    end
                end
            end
        end
    end
    (s = (Scalar){0.0, Float64}(s_val),)
end
```

TL;DR: As a quick heuristic, if your array indices are all in alphabetical order, then
the loop indices should be reverse alphabetical.

## Appropriate Fill Values

The @finch macro requires the user to specify an output format. This is the most
flexibile approach, but can sometimes lead to densification unless the output
fill value is appropriate for the computation.

For example, if `A` is `m × n` with `nnz` nonzeros, the following Finch kernel will
densify `B`, filling it with `m * n` stored values:

```jldoctest example1
A = Fiber!(Dense(SparseList(Element(0.0))), fsparse([2, 3, 4, 1, 3], [1, 1, 1, 3, 3], [1.1, 2.2, 3.3, 4.4, 5.5], (4, 3)))
B = Fiber!(Dense(SparseList(Element(0.0)))) #DO NOT DO THIS, B has the wrong fill value
@finch (B .= 0; for j=_, i=_; B[i, j] = A[i, j] + 1 end)
countstored(B)

# output

12
```

Since `A` is filled with `0.0`, adding `1` to the fill value produces `1.0`. However, `B` can only represent a fill value of `0.0`. Instead, we should specify `1.0` for the fill.

```jldoctest example1
A = Fiber!(Dense(SparseList(Element(0.0))), fsparse([2, 3, 4, 1, 3], [1, 1, 1, 3, 3], [1.1, 2.2, 3.3, 4.4, 5.5], (4, 3)))
B = Fiber!(Dense(SparseList(Element(1.0))))
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
A = Fiber!(Dense(SparseList(Element(0.0))), fsparse([2, 3, 4, 1, 3], [1, 1, 1, 3, 3], [1.1, 2.2, 3.3, 4.4, 5.5], (4, 3)))
B = Fiber!(Dense(SparseList(Element(1.0))))
x = 1 #DO NOT DO THIS, Finch cannot see the value of x anymore
@finch (B .= 1; for j=_, i=_; B[i, j] = A[i, j] + x end)
countstored(B)

# output

12
```

However, there are some situations where you may want a value to be dynamic. For example, consider the function `saxpy(x, a, y) = x .* a .+ y`. Because we do not know the value of `a` until we run the function, we should treat it as dynamic, and the following implementation is reasonable:

```julia
function saxpy(x, a, y)
    z = Fiber!(SparseList(Element(0.0)))
    @finch (z .= 0; for i=_; z[i] = a * x[i] + y[i] end)
end
```

## Use Known Functions

Unless you declare the properties of your functions using Finch's [Custom Functions](@ref) interface, Finch doesn't know how they work. For example, using a lambda obscures
the meaning of `*`.

```jldoctest example1
A = Fiber!(Dense(SparseList(Element(0.0))), fsparse([2, 3, 4, 1, 3], [1, 1, 1, 3, 3], [1.1, 2.2, 3.3, 4.4, 5.5], (4, 3)))
B = ones(4, 3)
C = Scalar(0.0)
f(x, y) = x * y # DO NOT DO THIS, Obscures *
@finch (C .= 0; for j=_, i=_; C[] += f(A[i, j], B[i, j]) end)

# output

(C = Scalar{0.0, Float64}(16.5),)
```

Checking the generated code, we see that this code is indeed densifying (notice the for-loop which repeatedly evaluates `f(B[i, j], 0.0)`).

```jldoctest example1
@finch_code (C .= 0; for j=_, i=_; C[] += f(A[i, j], B[i, j]) end)

# output

quote
    C = (ex.bodies[1]).tns.bind
    A_lvl = ((ex.bodies[2]).body.body.rhs.args[1]).tns.bind.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_ptr = A_lvl_2.ptr
    A_lvl_idx = A_lvl_2.idx
    A_lvl_2_val = A_lvl_2.lvl.val
    B = ((ex.bodies[2]).body.body.rhs.args[2]).tns.bind
    sugar_1 = size(B)
    B_mode1_stop = sugar_1[1]
    B_mode2_stop = sugar_1[2]
    B_mode1_stop == A_lvl_2.shape || throw(DimensionMismatch("mismatched dimension limits ($(B_mode1_stop) != $(A_lvl_2.shape))"))
    B_mode2_stop == A_lvl.shape || throw(DimensionMismatch("mismatched dimension limits ($(B_mode2_stop) != $(A_lvl.shape))"))
    C_val = 0
    for j_4 = 1:B_mode2_stop
        sugar_2 = size(B)
        B_mode1_stop = sugar_2[1]
        B_mode2_stop = sugar_2[2]
        A_lvl_q = (1 - 1) * A_lvl.shape + j_4
        A_lvl_2_q = A_lvl_ptr[A_lvl_q]
        A_lvl_2_q_stop = A_lvl_ptr[A_lvl_q + 1]
        if A_lvl_2_q < A_lvl_2_q_stop
            A_lvl_2_i1 = A_lvl_idx[A_lvl_2_q_stop - 1]
        else
            A_lvl_2_i1 = 0
        end
        phase_stop = min(B_mode1_stop, A_lvl_2_i1)
        if phase_stop >= 1
            i = 1
            if A_lvl_idx[A_lvl_2_q] < 1
                A_lvl_2_q = Finch.scansearch(A_lvl_idx, 1, A_lvl_2_q, A_lvl_2_q_stop - 1)
            end
            while true
                A_lvl_2_i = A_lvl_idx[A_lvl_2_q]
                if A_lvl_2_i < phase_stop
                    for i_6 = i:A_lvl_2_i - 1
                        val = B[i_6, j_4]
                        C_val = f(0.0, val) + C_val
                    end
                    A_lvl_3_val = A_lvl_2_val[A_lvl_2_q]
                    sugar_4 = size(B)
                    B_mode1_stop = sugar_4[1]
                    B_mode2_stop = sugar_4[2]
                    val = B[A_lvl_2_i, j_4]
                    C_val = C_val + f(A_lvl_3_val, val)
                    A_lvl_2_q += 1
                    i = A_lvl_2_i + 1
                else
                    phase_stop_3 = min(phase_stop, A_lvl_2_i)
                    if A_lvl_2_i == phase_stop_3
                        for i_8 = i:phase_stop_3 - 1
                            val = B[i_8, j_4]
                            C_val = C_val + f(0.0, val)
                        end
                        A_lvl_3_val = A_lvl_2_val[A_lvl_2_q]
                        sugar_6 = size(B)
                        B_mode1_stop = sugar_6[1]
                        B_mode2_stop = sugar_6[2]
                        val = B[phase_stop_3, j_4]
                        C_val = C_val + f(A_lvl_3_val, val)
                        A_lvl_2_q += 1
                    else
                        for i_10 = i:phase_stop_3
                            sugar_7 = size(B)
                            B_mode1_stop = sugar_7[1]
                            B_mode2_stop = sugar_7[2]
                            val = B[i_10, j_4]
                            C_val = C_val + f(0.0, val)
                        end
                    end
                    i = phase_stop_3 + 1
                    break
                end
            end
        end
        phase_start = max(1, 1 + A_lvl_2_i1)
        if B_mode1_stop >= phase_start
            for i_12 = phase_start:B_mode1_stop
                sugar_8 = size(B)
                B_mode1_stop = sugar_8[1]
                B_mode2_stop = sugar_8[2]
                val = B[i_12, j_4]
                C_val = C_val + f(0.0, val)
            end
        end
    end
    (C = (Scalar){0.0, Float64}(C_val),)
end

```