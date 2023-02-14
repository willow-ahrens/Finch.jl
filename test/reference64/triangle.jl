begin
    B = ex.body.body.body.lhs.tns.tns
    B_val = B.val
    A_lvl = (ex.body.body.body.rhs.args[1]).tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_3 = A_lvl_2.lvl
    A_lvl_4 = (ex.body.body.body.rhs.args[2]).tns.tns.lvl
    A_lvl_5 = A_lvl_4.lvl
    A_lvl_6 = A_lvl_5.lvl
    A_lvl_7 = (ex.body.body.body.rhs.args[3]).tns.tns.lvl
    A_lvl_8 = A_lvl_7.lvl
    A_lvl_9 = A_lvl_8.lvl
    B_val = 0.0
    for i_4 = 1:A_lvl.I
        A_lvl_q_2 = (1 - 1) * A_lvl.I + i_4
        A_lvl_q = (1 - 1) * A_lvl.I + i_4
        A_lvl_2_q = A_lvl_2.ptr[A_lvl_q_2]
        A_lvl_2_q_stop = A_lvl_2.ptr[A_lvl_q_2 + 1]
        if A_lvl_2_q < A_lvl_2_q_stop
            A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
            A_lvl_2_i1 = A_lvl_2.idx[A_lvl_2_q_stop - 1]
        else
            A_lvl_2_i = 1
            A_lvl_2_i1 = 0
        end
        j = 1
        j_start = j
        phase_stop = (min)(A_lvl.I, A_lvl_2_i1)
        if phase_stop >= j_start
            j_4 = j
            j = j_start
            while A_lvl_2_q + 1 < A_lvl_2_q_stop && A_lvl_2.idx[A_lvl_2_q] < j_start
                A_lvl_2_q += 1
            end
            while j <= phase_stop
                j_start_2 = j
                A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                phase_stop_2 = (min)(A_lvl_2_i, phase_stop)
                j_5 = j
                if A_lvl_2_i == phase_stop_2
                    A_lvl_3_val_2 = A_lvl_3.val[A_lvl_2_q]
                    j_6 = phase_stop_2
                    A_lvl_q_3 = (1 - 1) * A_lvl.I + j_6
                    A_lvl_2_q_2 = A_lvl_2.ptr[A_lvl_q]
                    A_lvl_2_q_stop_2 = A_lvl_2.ptr[A_lvl_q + 1]
                    if A_lvl_2_q_2 < A_lvl_2_q_stop_2
                        A_lvl_2_i_2 = A_lvl_2.idx[A_lvl_2_q_2]
                        A_lvl_2_i1_2 = A_lvl_2.idx[A_lvl_2_q_stop_2 - 1]
                    else
                        A_lvl_2_i_2 = 1
                        A_lvl_2_i1_2 = 0
                    end
                    A_lvl_2_q_3 = A_lvl_2.ptr[A_lvl_q_3]
                    A_lvl_2_q_stop_3 = A_lvl_2.ptr[A_lvl_q_3 + 1]
                    if A_lvl_2_q_3 < A_lvl_2_q_stop_3
                        A_lvl_2_i_3 = A_lvl_2.idx[A_lvl_2_q_3]
                        A_lvl_2_i1_3 = A_lvl_2.idx[A_lvl_2_q_stop_3 - 1]
                    else
                        A_lvl_2_i_3 = 1
                        A_lvl_2_i1_3 = 0
                    end
                    k = 1
                    k_start = k
                    phase_stop_3 = (min)(A_lvl_2.I, A_lvl_2_i1_3, A_lvl_2_i1_2)
                    if phase_stop_3 >= k_start
                        k_4 = k
                        k = k_start
                        while A_lvl_2_q_2 + 1 < A_lvl_2_q_stop_2 && A_lvl_2.idx[A_lvl_2_q_2] < k_start
                            A_lvl_2_q_2 += 1
                        end
                        while A_lvl_2_q_3 + 1 < A_lvl_2_q_stop_3 && A_lvl_2.idx[A_lvl_2_q_3] < k_start
                            A_lvl_2_q_3 += 1
                        end
                        while k <= phase_stop_3
                            k_start_2 = k
                            A_lvl_2_i_2 = A_lvl_2.idx[A_lvl_2_q_2]
                            A_lvl_2_i_3 = A_lvl_2.idx[A_lvl_2_q_3]
                            phase_stop_4 = (min)(A_lvl_2_i_3, A_lvl_2_i_2, phase_stop_3)
                            k_5 = k
                            if A_lvl_2_i_2 == phase_stop_4 && A_lvl_2_i_3 == phase_stop_4
                                A_lvl_3_val_3 = A_lvl_3.val[A_lvl_2_q_2]
                                A_lvl_3_val_4 = A_lvl_3.val[A_lvl_2_q_3]
                                k_6 = phase_stop_4
                                B_val = (+)((*)(A_lvl_3_val_2, A_lvl_3_val_3, A_lvl_3_val_4), B_val)
                                A_lvl_2_q_2 += 1
                                A_lvl_2_q_3 += 1
                            elseif A_lvl_2_i_3 == phase_stop_4
                                A_lvl_3_val_4 = A_lvl_3.val[A_lvl_2_q_3]
                                A_lvl_2_q_3 += 1
                            elseif A_lvl_2_i_2 == phase_stop_4
                                A_lvl_3_val_3 = A_lvl_3.val[A_lvl_2_q_2]
                                A_lvl_2_q_2 += 1
                            else
                            end
                            k = phase_stop_4 + 1
                        end
                        k = phase_stop_3 + 1
                    end
                    k_start = k
                    phase_stop_5 = (min)(A_lvl_2.I, A_lvl_2_i1_2)
                    if phase_stop_5 >= k_start
                        k_7 = k
                        k = phase_stop_5 + 1
                    end
                    k_start = k
                    phase_stop_6 = (min)(A_lvl_2.I, A_lvl_2_i1_3)
                    if phase_stop_6 >= k_start
                        k_8 = k
                        k = phase_stop_6 + 1
                    end
                    k_start = k
                    if A_lvl_2.I >= k_start
                        k_9 = k
                        k = A_lvl_2.I + 1
                    end
                    A_lvl_2_q += 1
                else
                end
                j = phase_stop_2 + 1
            end
            j = phase_stop + 1
        end
        j_start = j
        if A_lvl.I >= j_start
            j_7 = j
            j = A_lvl.I + 1
        end
    end
    (B = (Scalar){0.0, Float64}(B_val),)
end
