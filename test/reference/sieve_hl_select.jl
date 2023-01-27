begin
    B = ex.body.body.lhs.tns.tns
    B_val = B.val
    A_lvl = ex.body.body.rhs.tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_2_val = 0.0
    B_val = 0.0
    s_2 = 3
    A_lvl_q = A_lvl.pos[1]
    A_lvl_q_stop = A_lvl.pos[1 + 1]
    A_lvl_i = if A_lvl_q < A_lvl_q_stop
            A_lvl.idx[A_lvl_q]
        else
            1
        end
    A_lvl_i1 = if A_lvl_q < A_lvl_q_stop
            A_lvl.idx[A_lvl_q_stop - 1]
        else
            0
        end
    j = 1
    j_start = j
    phase_stop = (min)(A_lvl_i1, s_2 - 1, A_lvl.I)
    if phase_stop >= j_start
        j = j
        j = phase_stop + 1
    end
    j_start = j
    phase_stop_2 = (min)(s_2 - 1, A_lvl.I)
    if phase_stop_2 >= j_start
        j_2 = j
        j = phase_stop_2 + 1
    end
    j_start = j
    phase_stop_3 = (min)(A_lvl_i1, A_lvl.I, s_2)
    if phase_stop_3 >= j_start
        j_3 = j
        j = j_start
        while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < j_start
            A_lvl_q += 1
        end
        while j <= phase_stop_3
            j_start_2 = j
            A_lvl_i = A_lvl.idx[A_lvl_q]
            phase_stop_4 = (min)(A_lvl_i, phase_stop_3)
            j_4 = j
            if A_lvl_i == phase_stop_4
                A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                j_5 = phase_stop_4
                B_val = (+)(A_lvl_2_val, B_val)
                A_lvl_q += 1
            else
            end
            j = phase_stop_4 + 1
        end
        j = phase_stop_3 + 1
    end
    j_start = j
    phase_stop_5 = (min)(A_lvl.I, s_2)
    if phase_stop_5 >= j_start
        j_6 = j
        j = phase_stop_5 + 1
    end
    j_start = j
    phase_stop_6 = (min)(A_lvl_i1, A_lvl.I)
    if phase_stop_6 >= j_start
        j_7 = j
        j = phase_stop_6 + 1
    end
    j_start = j
    if A_lvl.I >= j_start
        j_8 = j
        j = A_lvl.I + 1
    end
    (B = (Scalar){0.0, Float64}(B_val),)
end
