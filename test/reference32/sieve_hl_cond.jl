begin
    B = (ex.bodies[1]).tns.bind
    A_lvl = (ex.bodies[2]).body.body.rhs.tns.bind.lvl
    A_lvl_2 = A_lvl.lvl
    B_val = 0
    A_lvl_q = A_lvl.ptr[1]
    A_lvl_q_stop = A_lvl.ptr[1 + 1]
    if A_lvl_q < A_lvl_q_stop
        A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
    else
        A_lvl_i1 = 0
    end
    phase_stop = min(A_lvl_i1, A_lvl.shape)
    if phase_stop >= 1
        j = 1
        if A_lvl.idx[A_lvl_q] < 1
            A_lvl_q = Finch.scansearch(A_lvl.idx, 1, A_lvl_q, A_lvl_q_stop - 1)
        end
        while j <= phase_stop
            A_lvl_i = A_lvl.idx[A_lvl_q]
            phase_stop_2 = min(phase_stop, A_lvl_i)
            if A_lvl_i == phase_stop_2
                A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                cond_2 = phase_stop_2 == 1
                if cond_2
                    B_val = A_lvl_2_val_2 + B_val
                end
                A_lvl_q += 1
            end
            j = phase_stop_2 + 1
        end
    end
    (B = (Scalar){0.0, Float64}(B_val),)
end
