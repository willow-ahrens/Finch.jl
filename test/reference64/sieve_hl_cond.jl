begin
    B = (ex.bodies[1]).tns.tns
    A_lvl = (ex.bodies[2]).body.body.rhs.tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    B_val = 0
    A_lvl_q = A_lvl.ptr[1]
    A_lvl_q_stop = A_lvl.ptr[1 + 1]
    if A_lvl_q < A_lvl_q_stop
        A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
    else
        A_lvl_i1 = 0
    end
    j = 1
    j_start = j
    phase_stop = (min)(A_lvl_i1, A_lvl.shape)
    if phase_stop >= j_start
        j = j_start
        if A_lvl.idx[A_lvl_q] < j_start
            A_lvl_q = scansearch(A_lvl.idx, j_start, A_lvl_q, A_lvl_q_stop - 1)
        end
        while j <= phase_stop
            A_lvl_i = A_lvl.idx[A_lvl_q]
            phase_stop_2 = (min)(phase_stop, A_lvl_i)
            if A_lvl_i == phase_stop_2
                A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                j_7 = phase_stop_2
                cond_2 = (==)(j_7, 1)
                if cond_2
                    B_val = (+)(A_lvl_2_val_2, B_val)
                end
                A_lvl_q += 1
            else
            end
            j = phase_stop_2 + 1
        end
    end
    (B = (Scalar){0.0, Float64}(B_val),)
end
