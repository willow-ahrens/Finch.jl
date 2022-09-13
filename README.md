# Finch.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://willow-ahrens.github.io/Finch.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://willow-ahrens.github.io/Finch.jl/dev)
[![Build Status](https://github.com/willow-ahrens/Finch.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/willow-ahrens/Finch.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/willow-ahrens/Finch.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/willow-ahrens/Finch.jl)

Finch is an adaptable Julia-to-Julia compiler for loop nests over sparse or structured
multidimensional arrays. In addition to supporting [sparse
arrays](https://en.wikipedia.org/wiki/Sparse_matrix), Finch can also handle
[custom operators and fill values other than zero](https://en.wikipedia.org/wiki/GraphBLAS),
[runs](https://en.wikipedia.org/wiki/Run-length_encoding) of repeated values, or
even [special
structures](https://en.wikipedia.org/wiki/Sparse_matrix#Special_structure) such
as clustered nonzeros or triangular patterns.

Finch supports loops and reductions over pointwise expressions on arrays,
incorporating arbitrary element types and operators. Users can add rewrite rules
to inform the compiler about any special properties or optimizations that might
apply to the situation at hand. You can even modify indexing expressions to 
express sparse convolution, or to describe windows into structured
arrays.

Finch is very experimental. There are known bugs, and some interfaces will change dramatically.

More documentation is incoming, in the meantime, check this out:

```julia
using Finch
using SparseArrays
A = copyto!(@fiber(sl(e(0.0))), sprand(42, 0.1));
B = copyto!(@fiber(sl(e(0.0))), sprand(42, 0.1));
C = similar(A);
F = copyto!(@fiber(d(e(0.0))), [1, 1, 1, 1, 1]);

#Sparse Convolution
@finch @∀ i j C[i] += (A[i] != 0) * coalesce(A[permit[offset[3-i, j]]], 0) * coalesce(F[permit[j]], 0)
 
#Print Sparse Addition Code
println(@finch_code @∀ i C[i] += A[i] + B[i])
```

```julia
@inbounds begin
    C_lvl = ex.body.lhs.tns.tns.lvl
    C_lvl_pos_alloc = length(C_lvl.pos)
    C_lvl_idx_alloc = length(C_lvl.idx)
    C_lvl_2 = C_lvl.lvl
    C_lvl_2_val_alloc = length(C_lvl.lvl.val)
    C_lvl_2_val = 0.0
    A_lvl = (ex.body.rhs.args[1]).tns.tns.lvl
    A_lvl_pos_alloc = length(A_lvl.pos)
    A_lvl_idx_alloc = length(A_lvl.idx)
    A_lvl_2 = A_lvl.lvl
    A_lvl_2_val_alloc = length(A_lvl.lvl.val)
    A_lvl_2_val = 0.0
    B_lvl = (ex.body.rhs.args[2]).tns.tns.lvl
    B_lvl_pos_alloc = length(B_lvl.pos)
    B_lvl_idx_alloc = length(B_lvl.idx)
    B_lvl_2 = B_lvl.lvl
    B_lvl_2_val_alloc = length(B_lvl.lvl.val)
    B_lvl_2_val = 0.0
    i_stop = A_lvl.I
    C_lvl_pos_alloc = length(C_lvl.pos)
    C_lvl_pos_fill = 1
    C_lvl.pos[1] = 1
    C_lvl.pos[2] = 1
    C_lvl_idx_alloc = length(C_lvl.idx)
    C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, 0, 4)
    C_lvl_pos_alloc < 1 + 1 && (C_lvl_pos_alloc = (Finch).refill!(C_lvl.pos, 0, C_lvl_pos_alloc, 1 + 1))
    C_lvl_q = C_lvl.pos[C_lvl_pos_fill]
    for C_lvl_p = C_lvl_pos_fill:1
        C_lvl.pos[C_lvl_p] = C_lvl_q
    end
    A_lvl_q = A_lvl.pos[1]
    A_lvl_q_stop = A_lvl.pos[1 + 1]
    if A_lvl_q < A_lvl_q_stop
        A_lvl_i = A_lvl.idx[A_lvl_q]
        A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
    else
        A_lvl_i = 1
        A_lvl_i1 = 0
    end
    B_lvl_q = B_lvl.pos[1]
    B_lvl_q_stop = B_lvl.pos[1 + 1]
    if B_lvl_q < B_lvl_q_stop
        B_lvl_i = B_lvl.idx[B_lvl_q]
        B_lvl_i1 = B_lvl.idx[B_lvl_q_stop - 1]
    else
        B_lvl_i = 1
        B_lvl_i1 = 0
    end
    i = 1
    i_start = i
    phase_start = max(i_start)
    phase_stop = min(A_lvl_i1, B_lvl_i1, i_stop)
    if phase_stop >= phase_start
        i = i
        i = phase_start
        while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start
            A_lvl_q += 1
        end
        while B_lvl_q < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < phase_start
            B_lvl_q += 1
        end
        while i <= phase_stop
            i_start_2 = i
            A_lvl_i = A_lvl.idx[A_lvl_q]
            B_lvl_i = B_lvl.idx[B_lvl_q]
            phase_start_2 = max(i_start_2)
            phase_stop_2 = min(A_lvl_i, B_lvl_i, phase_stop)
            if phase_stop_2 >= phase_start_2
                i_2 = i
                if A_lvl_i == phase_stop_2 && B_lvl_i == phase_stop_2
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    i_3 = phase_stop_2
                    C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                    C_lvl_isdefault = true
                    C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                    C_lvl_isdefault = false
                    C_lvl_isdefault = false
                    C_lvl_2_val = C_lvl_2_val + (A_lvl_2_val + B_lvl_2_val)
                    C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                    if !C_lvl_isdefault
                        C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                        C_lvl.idx[C_lvl_q] = i_3
                        C_lvl_q += 1
                    end
                    A_lvl_q += 1
                    B_lvl_q += 1
                elseif B_lvl_i == phase_stop_2
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    i_4 = phase_stop_2
                    C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                    C_lvl_isdefault = true
                    C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                    C_lvl_isdefault = false
                    C_lvl_isdefault = false
                    C_lvl_2_val = C_lvl_2_val + B_lvl_2_val
                    C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                    if !C_lvl_isdefault
                        C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                        C_lvl.idx[C_lvl_q] = i_4
                        C_lvl_q += 1
                    end
                    B_lvl_q += 1
                elseif A_lvl_i == phase_stop_2
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    i_5 = phase_stop_2
                    C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                    C_lvl_isdefault = true
                    C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                    C_lvl_isdefault = false
                    C_lvl_isdefault = false
                    C_lvl_2_val = C_lvl_2_val + A_lvl_2_val
                    C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                    if !C_lvl_isdefault
                        C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                        C_lvl.idx[C_lvl_q] = i_5
                        C_lvl_q += 1
                    end
                    A_lvl_q += 1
                else
                end
                i = phase_stop_2 + 1
            end
        end
        i = phase_stop + 1
    end
    i_start = i
    phase_start_3 = max(i_start)
    phase_stop_3 = min(A_lvl_i1, i_stop)
    if phase_stop_3 >= phase_start_3
        i_6 = i
        i = phase_start_3
        while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start_3
            A_lvl_q += 1
        end
        while i <= phase_stop_3
            i_start_3 = i
            A_lvl_i = A_lvl.idx[A_lvl_q]
            phase_stop_4 = min(A_lvl_i, phase_stop_3)
            i_7 = i
            if A_lvl_i == phase_stop_4
                A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                i_8 = phase_stop_4
                C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                C_lvl_isdefault = true
                C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                C_lvl_isdefault = false
                C_lvl_isdefault = false
                C_lvl_2_val = C_lvl_2_val + A_lvl_2_val
                C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                if !C_lvl_isdefault
                    C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                    C_lvl.idx[C_lvl_q] = i_8
                    C_lvl_q += 1
                end
                A_lvl_q += 1
            else
            end
            i = phase_stop_4 + 1
        end
        i = phase_stop_3 + 1
    end
    i_start = i
    phase_start_5 = max(i_start)
    phase_stop_5 = min(B_lvl_i1, i_stop)
    if phase_stop_5 >= phase_start_5
        i_9 = i
        i = phase_start_5
        while B_lvl_q < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < phase_start_5
            B_lvl_q += 1
        end
        while i <= phase_stop_5
            i_start_4 = i
            B_lvl_i = B_lvl.idx[B_lvl_q]
            phase_stop_6 = min(B_lvl_i, phase_stop_5)
            i_10 = i
            if B_lvl_i == phase_stop_6
                B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                i_11 = phase_stop_6
                C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                C_lvl_isdefault = true
                C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                C_lvl_isdefault = false
                C_lvl_isdefault = false
                C_lvl_2_val = C_lvl_2_val + B_lvl_2_val
                C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                if !C_lvl_isdefault
                    C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                    C_lvl.idx[C_lvl_q] = i_11
                    C_lvl_q += 1
                end
                B_lvl_q += 1
            else
            end
            i = phase_stop_6 + 1
        end
        i = phase_stop_5 + 1
    end
    i_start = i
    phase_start_7 = max(i_start)
    phase_stop_7 = min(i_stop)
    if phase_stop_7 >= phase_start_7
        i_12 = i
        i = phase_stop_7 + 1
    end
    C_lvl.pos[1 + 1] = C_lvl_q
    C_lvl_pos_fill = 1 + 1
    (C = Fiber((Finch.SparseListLevel){Int64}(A_lvl.I, C_lvl.pos, C_lvl.idx, C_lvl_2), (Finch.Environment)(; name = :C)),)
end
```

Array formats in Finch are described recursively mode by mode, using a
relaxation of TACO's [level format
abstraction](https://dl.acm.org/doi/pdf/10.1145/3276493).  Semantically, an
array in Finch can be understood as a tree, where each level in the tree
corresponds to a dimension and each edge corresponds to an index. In addition
to choosing a data storage format, Finch allows users to choose an access **protocol**,
determining which strategy should be used to traverse the array.

The input to Finch is an extended form of [concrete index
notation](https://arxiv.org/abs/1802.10574). In addition to simple loops and
pointwise expressions, Finch supports the where, multi, and sieve statements.
The where statement describes temporary tensors, the multi statements describe
computations with multiple outputs, and the sieve statement filters out
iterations.

At it's heart, Finch is powered by a new domain specific language for
coiteration, breaking structured iterators into control flow units we call
**Looplets**. Looplets are lowered progressively, leaving several opportunities to
rewrite and simplify intermediate expressions.

The technologies enabling Finch are described in our [manuscript](https://arxiv.org/abs/2209.05250).
