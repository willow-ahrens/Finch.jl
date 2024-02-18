begin
    B = ((ex.bodies[1]).bodies[1]).tns.bind
    A_lvl = (((ex.bodies[1]).bodies[2]).body.body.body.rhs.args[1]).tns.bind.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_ptr = A_lvl_2.ptr
    A_lvl_idx = A_lvl_2.idx
    A_lvl_2_val = A_lvl_2.lvl.val
    A_lvl.shape == A_lvl_2.shape || throw(DimensionMismatch("mismatched dimension limits ($(A_lvl.shape) != $(A_lvl_2.shape))"))
    B_val = 0
    for i_4 = 1:A_lvl.shape
        A_lvl_q = (1 - 1) * A_lvl.shape + i_4
        A_lvl_q_2 = (1 - 1) * A_lvl.shape + i_4
        A_lvl_2_q = A_lvl_ptr[A_lvl_q]
        A_lvl_2_q_stop = A_lvl_ptr[A_lvl_q + 1]
        if A_lvl_2_q < A_lvl_2_q_stop
            A_lvl_2_i1 = A_lvl_idx[A_lvl_2_q_stop - 1]
        else
            A_lvl_2_i1 = 0
        end
        phase_stop = min(A_lvl.shape, A_lvl_2_i1)
        if phase_stop >= 1
            if A_lvl_idx[A_lvl_2_q] < 1
                A_lvl_2_q = Finch.scansearch(A_lvl_idx, 1, A_lvl_2_q, A_lvl_2_q_stop - 1)
            end
            while true
                A_lvl_2_i = A_lvl_idx[A_lvl_2_q]
                if A_lvl_2_i < phase_stop
                    A_lvl_3_val = A_lvl_2_val[A_lvl_2_q]
                    A_lvl_q_3 = (1 - 1) * A_lvl.shape + A_lvl_2_i
                    A_lvl_2_q_2 = A_lvl_ptr[A_lvl_q_2]
                    A_lvl_2_q_stop_2 = A_lvl_ptr[A_lvl_q_2 + 1]
                    if A_lvl_2_q_2 < A_lvl_2_q_stop_2
                        A_lvl_2_i1_2 = A_lvl_idx[A_lvl_2_q_stop_2 - 1]
                    else
                        A_lvl_2_i1_2 = 0
                    end
                    A_lvl_2_q_3 = A_lvl_ptr[A_lvl_q_3]
                    A_lvl_2_q_stop_3 = A_lvl_ptr[A_lvl_q_3 + 1]
                    if A_lvl_2_q_3 < A_lvl_2_q_stop_3
                        A_lvl_2_i1_3 = A_lvl_idx[A_lvl_2_q_stop_3 - 1]
                    else
                        A_lvl_2_i1_3 = 0
                    end
                    phase_stop_3 = min(A_lvl_2.shape, A_lvl_2_i1_2, A_lvl_2_i1_3)
                    if phase_stop_3 >= 1
                        k = 1
                        if A_lvl_idx[A_lvl_2_q_2] < 1
                            A_lvl_2_q_2 = Finch.scansearch(A_lvl_idx, 1, A_lvl_2_q_2, A_lvl_2_q_stop_2 - 1)
                        end
                        if A_lvl_idx[A_lvl_2_q_3] < 1
                            A_lvl_2_q_3 = Finch.scansearch(A_lvl_idx, 1, A_lvl_2_q_3, A_lvl_2_q_stop_3 - 1)
                        end
                        while k <= phase_stop_3
                            A_lvl_2_i_2 = A_lvl_idx[A_lvl_2_q_2]
                            A_lvl_2_i_3 = A_lvl_idx[A_lvl_2_q_3]
                            phase_stop_4 = min(A_lvl_2_i_3, phase_stop_3, A_lvl_2_i_2)
                            if A_lvl_2_i_2 == phase_stop_4 && A_lvl_2_i_3 == phase_stop_4
                                A_lvl_3_val_2 = A_lvl_2_val[A_lvl_2_q_2]
                                A_lvl_3_val_3 = A_lvl_2_val[A_lvl_2_q_3]
                                B_val = A_lvl_3_val * A_lvl_3_val_2 * A_lvl_3_val_3 + B_val
                                A_lvl_2_q_2 += 1
                                A_lvl_2_q_3 += 1
                            elseif A_lvl_2_i_3 == phase_stop_4
                                A_lvl_2_q_3 += 1
                            elseif A_lvl_2_i_2 == phase_stop_4
                                A_lvl_2_q_2 += 1
                            end
                            k = phase_stop_4 + 1
                        end
                    end
                    A_lvl_2_q += 1
                else
                    phase_stop_8 = min(A_lvl_2_i, phase_stop)
                    if A_lvl_2_i == phase_stop_8
                        A_lvl_3_val = A_lvl_2_val[A_lvl_2_q]
                        A_lvl_q_3 = (1 - 1) * A_lvl.shape + phase_stop_8
                        A_lvl_2_q_2 = A_lvl_ptr[A_lvl_q_2]
                        A_lvl_2_q_stop_2 = A_lvl_ptr[A_lvl_q_2 + 1]
                        if A_lvl_2_q_2 < A_lvl_2_q_stop_2
                            A_lvl_2_i1_2 = A_lvl_idx[A_lvl_2_q_stop_2 - 1]
                        else
                            A_lvl_2_i1_2 = 0
                        end
                        A_lvl_2_q_4 = A_lvl_ptr[A_lvl_q_3]
                        A_lvl_2_q_stop_4 = A_lvl_ptr[A_lvl_q_3 + 1]
                        if A_lvl_2_q_4 < A_lvl_2_q_stop_4
                            A_lvl_2_i1_4 = A_lvl_idx[A_lvl_2_q_stop_4 - 1]
                        else
                            A_lvl_2_i1_4 = 0
                        end
                        phase_stop_9 = min(A_lvl_2.shape, A_lvl_2_i1_2, A_lvl_2_i1_4)
                        if phase_stop_9 >= 1
                            k = 1
                            if A_lvl_idx[A_lvl_2_q_2] < 1
                                A_lvl_2_q_2 = Finch.scansearch(A_lvl_idx, 1, A_lvl_2_q_2, A_lvl_2_q_stop_2 - 1)
                            end
                            if A_lvl_idx[A_lvl_2_q_4] < 1
                                A_lvl_2_q_4 = Finch.scansearch(A_lvl_idx, 1, A_lvl_2_q_4, A_lvl_2_q_stop_4 - 1)
                            end
                            while k <= phase_stop_9
                                A_lvl_2_i_2 = A_lvl_idx[A_lvl_2_q_2]
                                A_lvl_2_i_4 = A_lvl_idx[A_lvl_2_q_4]
                                phase_stop_10 = min(A_lvl_2_i_2, A_lvl_2_i_4, phase_stop_9)
                                if A_lvl_2_i_2 == phase_stop_10 && A_lvl_2_i_4 == phase_stop_10
                                    A_lvl_3_val_6 = A_lvl_2_val[A_lvl_2_q_2]
                                    A_lvl_3_val_7 = A_lvl_2_val[A_lvl_2_q_4]
                                    B_val = B_val + A_lvl_3_val * A_lvl_3_val_6 * A_lvl_3_val_7
                                    A_lvl_2_q_2 += 1
                                    A_lvl_2_q_4 += 1
                                elseif A_lvl_2_i_4 == phase_stop_10
                                    A_lvl_2_q_4 += 1
                                elseif A_lvl_2_i_2 == phase_stop_10
                                    A_lvl_2_q_2 += 1
                                end
                                k = phase_stop_10 + 1
                            end
                        end
                        A_lvl_2_q += 1
                    end
                    break
                end
            end
        end
    end
    result = something(nothing, (B = B,))
    B.val = B_val
    result
end
