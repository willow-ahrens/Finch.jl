begin
    B = ex.body.body.lhs.tns.bind
    B_val = B.val
    A_lvl = ex.body.body.rhs.tns.bind.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_q = A_lvl.ptr[1]
    A_lvl_q_stop = A_lvl.ptr[1 + 1]
    if A_lvl_q < A_lvl_q_stop
        A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
    else
        A_lvl_i1 = 0
    end
    phase_start_2 = max(1, 1 + (3 - 1))
    phase_stop_2 = min(A_lvl.shape, A_lvl_i1, 3)
    if phase_stop_2 >= phase_start_2
        j = phase_start_2
        if A_lvl.idx[A_lvl_q] < phase_start_2
            A_lvl_q = Finch.scansearch(A_lvl.idx, phase_start_2, A_lvl_q, A_lvl_q_stop - 1)
        end
        while j <= phase_stop_2
            A_lvl_i = A_lvl.idx[A_lvl_q]
            phase_stop_3 = min(phase_stop_2, A_lvl_i)
            if A_lvl_i == phase_stop_3
                A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                B_val = A_lvl_2_val_2 + B_val
                A_lvl_q += 1
            end
            j = phase_stop_3 + 1
        end
    end
    (B = (Scalar){0.0, Float64}(B_val),)
end
