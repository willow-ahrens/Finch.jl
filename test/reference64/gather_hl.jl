begin
    B = ex.lhs.tns.bind
    B_val = B.val
    A_lvl = ex.rhs.tns.bind.lvl
    val = A_lvl.lvl.val
    A_lvl_ptr = A_lvl.ptr
    A_lvl_idx = A_lvl.idx
    A_lvl_q = A_lvl_ptr[1]
    A_lvl_q_stop = A_lvl_ptr[1 + 1]
    if A_lvl_q < A_lvl_q_stop
        A_lvl_i1 = A_lvl_idx[A_lvl_q_stop - 1]
    else
        A_lvl_i1 = 0
    end
    phase_stop = min(5, A_lvl_i1)
    if phase_stop >= 5
        s = 5
        if A_lvl_idx[A_lvl_q] < 5
            A_lvl_q = Finch.scansearch(A_lvl_idx, 5, A_lvl_q, A_lvl_q_stop - 1)
        end
        while s <= phase_stop
            A_lvl_i = A_lvl_idx[A_lvl_q]
            phase_stop_2 = min(phase_stop, A_lvl_i)
            if A_lvl_i == phase_stop_2
                A_lvl_2_val = val[A_lvl_q]
                B_val = A_lvl_2_val + B_val
                A_lvl_q += 1
            end
            s = phase_stop_2 + 1
        end
    end
    (B = (Scalar){0.0, Float64}(B_val),)
end
