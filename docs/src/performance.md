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
A = @fiber(d(sl(e(0.0))), [0.0 0.0 4.4; 1.1 0.0 0.0; 2.2 0.0 5.5; 3.3 0.0 0.0])
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