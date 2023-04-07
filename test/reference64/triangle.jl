begin
    B = (ex.bodies[1]).tns.tns
    A_lvl = ((ex.bodies[2]).body.body.body.rhs.args[1]).tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_3 = A_lvl_2.lvl
    A_lvl.shape == A_lvl_2.shape || throw(DimensionMismatch("mismatched dimension limits ($(A_lvl.shape) != $(A_lvl_2.shape))"))
    B_val = 0
    for i_4 = 1:A_lvl.shape
        A_lvl_q = (1 - 1) * A_lvl.shape + i_4
        A_lvl_q_2 = (1 - 1) * A_lvl.shape + i_4
        A_lvl_2_q = A_lvl_2.ptr[A_lvl_q]
        A_lvl_2_q_stop = A_lvl_2.ptr[A_lvl_q + 1]
        if A_lvl_2_q < A_lvl_2_q_stop
            A_lvl_2_i1 = A_lvl_2.idx[A_lvl_2_q_stop - 1]
        else
            A_lvl_2_i1 = 0
        end
        j = 1
        j_start = j
        phase_stop = (min)(A_lvl.shape, A_lvl_2_i1)
        if phase_stop >= j_start
            j = j_start
            if A_lvl_2.idx[A_lvl_2_q] < j_start
                A_lvl_2_q = scansearch(A_lvl_2.idx, j_start, A_lvl_2_q, A_lvl_2_q_stop - 1)
            end
            while j <= phase_stop
                A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                phase_stop_2 = (min)(phase_stop, A_lvl_2_i)
                if A_lvl_2_i == phase_stop_2
                    A_lvl_3_val_2 = A_lvl_3.val[A_lvl_2_q]
                    j_6 = phase_stop_2
                    A_lvl_q_3 = (1 - 1) * A_lvl.shape + j_6
                    A_lvl_2_q_2 = A_lvl_2.ptr[A_lvl_q_2]
                    A_lvl_2_q_stop_2 = A_lvl_2.ptr[A_lvl_q_2 + 1]
                    if A_lvl_2_q_2 < A_lvl_2_q_stop_2
                        A_lvl_2_i1_2 = A_lvl_2.idx[A_lvl_2_q_stop_2 - 1]
                    else
                        A_lvl_2_i1_2 = 0
                    end
                    A_lvl_2_q_3 = A_lvl_2.ptr[A_lvl_q_3]
                    A_lvl_2_q_stop_3 = A_lvl_2.ptr[A_lvl_q_3 + 1]
                    if A_lvl_2_q_3 < A_lvl_2_q_stop_3
                        A_lvl_2_i1_3 = A_lvl_2.idx[A_lvl_2_q_stop_3 - 1]
                    else
                        A_lvl_2_i1_3 = 0
                    end
                    k = 1
                    k_start = k
                    phase_stop_3 = (min)(A_lvl_2.shape, A_lvl_2_i1_3, A_lvl_2_i1_2)
                    if phase_stop_3 >= k_start
                        k = k_start
                        if A_lvl_2.idx[A_lvl_2_q_2] < k_start
                            A_lvl_2_q_2 = scansearch(A_lvl_2.idx, k_start, A_lvl_2_q_2, A_lvl_2_q_stop_2 - 1)
                        end
                        if A_lvl_2.idx[A_lvl_2_q_3] < k_start
                            A_lvl_2_q_3 = scansearch(A_lvl_2.idx, k_start, A_lvl_2_q_3, A_lvl_2_q_stop_3 - 1)
                        end
                        while k <= phase_stop_3
                            A_lvl_2_i_2 = A_lvl_2.idx[A_lvl_2_q_2]
                            A_lvl_2_i_3 = A_lvl_2.idx[A_lvl_2_q_3]
                            phase_stop_4 = (min)(A_lvl_2_i_2, A_lvl_2_i_3, phase_stop_3)
                            if A_lvl_2_i_2 == phase_stop_4 && A_lvl_2_i_3 == phase_stop_4
                                A_lvl_3_val_3 = A_lvl_3.val[A_lvl_2_q_2]
                                A_lvl_3_val_4 = A_lvl_3.val[A_lvl_2_q_3]
                                B_val = (+)((*)(A_lvl_3_val_2, A_lvl_3_val_3, A_lvl_3_val_4), B_val)
                                A_lvl_2_q_2 += 1
                                A_lvl_2_q_3 += 1
                            elseif A_lvl_2_i_3 == phase_stop_4
                                A_lvl_2_q_3 += 1
                            elseif A_lvl_2_i_2 == phase_stop_4
                                A_lvl_2_q_2 += 1
                            else
                            end
                            k = phase_stop_4 + 1
                        end
                        k = phase_stop_3 + 1
                    end
                    k_start = k
                    phase_stop_5 = (min)(A_lvl_2.shape, A_lvl_2_i1_2)
                    A_lvl_2_q += 1
                else
                end
                j = phase_stop_2 + 1
            end
        end
    end
    (B = (Scalar){0.0, Float64}(B_val),)
end
