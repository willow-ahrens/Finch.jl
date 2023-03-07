begin
    B = (ex.bodies[1]).tns.tns
    B_val = B.val
    B_3 = (ex.bodies[2]).body.body.lhs.tns.tns
    B_val = B_3.val
    A_lvl = (ex.bodies[2]).body.body.rhs.tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    B_val = 0
    A_lvl_q = A_lvl.ptr[1]
    A_lvl_q_stop = A_lvl.ptr[1 + 1]
    if A_lvl_q < A_lvl_q_stop
        A_lvl_i = A_lvl.idx[A_lvl_q]
        A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
    else
        A_lvl_i = 1
        A_lvl_i1 = 0
    end
    j = 1
    j_start = j
    phase_stop = (min)(A_lvl_i1, A_lvl.I)
    if phase_stop >= j_start
        j_4 = j
        j = j_start
        while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < j_start
            A_lvl_q += 1
        end
        while j <= phase_stop
            j_start_2 = j
            A_lvl_i = A_lvl.idx[A_lvl_q]
            phase_stop_2 = (min)(A_lvl_i, phase_stop)
            j_5 = j
            if A_lvl_i == phase_stop_2
                for j_6 = j_start_2:phase_stop_2 - 1
                    cond = (==)(j_6, 1)
                    if cond
                    end
                end
                A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                j_7 = phase_stop_2
                cond_2 = (==)(j_7, 1)
                if cond_2
                    B_val = (+)(A_lvl_2_val_2, B_val)
                end
                A_lvl_q += 1
            else
                for j_8 = j_start_2:phase_stop_2
                    cond_3 = (==)(j_8, 1)
                    if cond_3
                    end
                end
            end
            j = phase_stop_2 + 1
        end
        j = phase_stop + 1
    end
    j_start = j
    if A_lvl.I >= j_start
        j_9 = j
        for j_10 = j_start:A_lvl.I
            cond_4 = (==)(j_10, 1)
            if cond_4
            end
        end
        j = A_lvl.I + 1
    end
    (B = (Scalar){0.0, Float64}(B_val),)
end
