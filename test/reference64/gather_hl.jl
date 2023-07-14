begin
    B = ex.lhs.tns.tns
    B_val = B.val
    A_lvl = ex.rhs.tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_q = A_lvl.ptr[1]
    A_lvl_q_stop = A_lvl.ptr[1 + 1]
    if A_lvl_q < A_lvl_q_stop
        A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
    else
        A_lvl_i1 = 0
    end
    phase_stop = min(5, A_lvl_i1)
    if phase_stop >= 5
        s = 5
        if A_lvl.idx[A_lvl_q] < 5
            A_lvl_q = Finch.scansearch(A_lvl.idx, 5, A_lvl_q, A_lvl_q_stop - 1)
        end
        while s <= phase_stop
            A_lvl_i = A_lvl.idx[A_lvl_q]
            phase_stop_2 = min(phase_stop, A_lvl_i)
            if A_lvl_i == phase_stop_2
                A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                B_val = A_lvl_2_val_2 + B_val
                A_lvl_q += 1
            end
            s = phase_stop_2 + 1
        end
    end
    (B = (Scalar){0.0, Float64}(B_val),)
end
