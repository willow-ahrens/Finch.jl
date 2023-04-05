begin
    B = ex.body.body.lhs.tns.tns
    B_val = B.val
    A_lvl = ex.body.body.rhs.tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
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
    phase_stop = (min)(A_lvl_i1, A_lvl.shape)
    if phase_stop >= j_start
        j_4 = j
        j = j_start
        if A_lvl.idx[A_lvl_q] < j_start
            A_lvl_q = scansearch(A_lvl.idx, j_start, A_lvl_q, A_lvl_q_stop - 1)
        end
        while j <= phase_stop
            j_start_2 = j
            A_lvl_i = A_lvl.idx[A_lvl_q]
            phase_stop_2 = (min)(phase_stop, A_lvl_i)
            j_5 = j
            if A_lvl_i == phase_stop_2
                for j_6 = j_start_2:(-)(phase_stop_2, 1)
                    s = 3
                    s_start = s
                    phase_stop_3 = (min)(j_6 - 1, 3)
                    if phase_stop_3 >= s_start
                        s_2 = s
                        s = phase_stop_3 + 1
                    end
                    s_start = s
                    phase_stop_4 = (min)(3, j_6)
                    if phase_stop_4 >= s_start
                        s_3 = s
                        s = phase_stop_4 + 1
                    end
                    s_start = s
                    if 3 >= s_start
                        s_4 = s
                        s = 3 + 1
                    end
                end
                A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                j_7 = phase_stop_2
                s_5 = 3
                s_5_start = s_5
                phase_stop_5 = (min)(3, j_7 - 1)
                if phase_stop_5 >= s_5_start
                    s_6 = s_5
                    s_5 = phase_stop_5 + 1
                end
                s_5_start = s_5
                phase_stop_6 = (min)(3, j_7)
                if phase_stop_6 >= s_5_start
                    s_7 = s_5
                    B_val = (+)(B_val, (*)(A_lvl_2_val_2, (+)(1, (-)(s_5_start), phase_stop_6)))
                    s_5 = phase_stop_6 + 1
                end
                s_5_start = s_5
                if 3 >= s_5_start
                    s_8 = s_5
                    s_5 = 3 + 1
                end
                A_lvl_q += 1
            else
                for j_8 = j_start_2:phase_stop_2
                    s_9 = 3
                    s_9_start = s_9
                    phase_stop_7 = (min)(3, j_8 - 1)
                    if phase_stop_7 >= s_9_start
                        s_10 = s_9
                        s_9 = phase_stop_7 + 1
                    end
                    s_9_start = s_9
                    phase_stop_8 = (min)(3, j_8)
                    if phase_stop_8 >= s_9_start
                        s_11 = s_9
                        s_9 = phase_stop_8 + 1
                    end
                    s_9_start = s_9
                    if 3 >= s_9_start
                        s_12 = s_9
                        s_9 = 3 + 1
                    end
                end
            end
            j = phase_stop_2 + 1
        end
        j = phase_stop + 1
    end
    j_start = j
    if A_lvl.shape >= j_start
        j_9 = j
        for j_10 = j_start:A_lvl.shape
            s_13 = 3
            s_13_start = s_13
            phase_stop_9 = (min)(3, j_10 - 1)
            if phase_stop_9 >= s_13_start
                s_14 = s_13
                s_13 = phase_stop_9 + 1
            end
            s_13_start = s_13
            phase_stop_10 = (min)(3, j_10)
            if phase_stop_10 >= s_13_start
                s_15 = s_13
                s_13 = phase_stop_10 + 1
            end
            s_13_start = s_13
            if 3 >= s_13_start
                s_16 = s_13
                s_13 = 3 + 1
            end
        end
        j = A_lvl.shape + 1
    end
    (B = (Scalar){0.0, Float64}(B_val),)
end
