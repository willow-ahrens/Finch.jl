begin
    B_lvl = (ex.bodies[1]).tns.tns.lvl
    B_lvl_2 = B_lvl.lvl
    B_lvl_3 = B_lvl_2.lvl
    B_lvl_4 = (ex.bodies[2]).body.body.body.lhs.tns.tns.lvl
    B_lvl_5 = B_lvl_4.lvl
    B_lvl_6 = B_lvl_5.lvl
    A_lvl = ((ex.bodies[2]).body.body.body.rhs.args[1]).tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_3 = A_lvl_2.lvl
    A_lvl_4 = ((ex.bodies[2]).body.body.body.rhs.args[2]).tns.tns.lvl
    A_lvl_5 = A_lvl_4.lvl
    A_lvl_6 = A_lvl_5.lvl
    B_lvl_2_qos_fill = 0
    B_lvl_2_qos_stop = 0
    p_start = (+)((*)((-)(1, 1), A_lvl.I), 1)
    p_start_2 = (*)(1, A_lvl.I)
    (Finch.resize_if_smaller!)(B_lvl_2.ptr, p_start_2 + 1)
    (Finch.fill_range!)(B_lvl_2.ptr, 0, p_start + 1, p_start_2 + 1)
    for j_4 = 1:A_lvl.I
        B_lvl_q = (1 - 1) * A_lvl.I + j_4
        A_lvl_q = (1 - 1) * A_lvl.I + j_4
        B_lvl_2_qos = B_lvl_2_qos_fill + 1
        for i_4 = 1:A_lvl.I
            if B_lvl_2_qos > B_lvl_2_qos_stop
                B_lvl_2_qos_stop = max(B_lvl_2_qos_stop << 1, 1)
                (Finch.resize_if_smaller!)(B_lvl_2.idx, B_lvl_2_qos_stop)
                resize_if_smaller!(B_lvl_3.val, B_lvl_2_qos_stop)
                fill_range!(B_lvl_3.val, 0.0, B_lvl_2_qos, B_lvl_2_qos_stop)
            end
            B_lvl_2dirty = false
            A_lvl_q_2 = (1 - 1) * A_lvl.I + i_4
            B_lvl_3_val_2 = B_lvl_3.val[B_lvl_2_qos]
            A_lvl_2_q = A_lvl_2.ptr[A_lvl_q]
            A_lvl_2_q_stop = A_lvl_2.ptr[A_lvl_q + 1]
            if A_lvl_2_q < A_lvl_2_q_stop
                A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                A_lvl_2_i1 = A_lvl_2.idx[A_lvl_2_q_stop - 1]
            else
                A_lvl_2_i = 1
                A_lvl_2_i1 = 0
            end
            A_lvl_2_q_2 = A_lvl_2.ptr[A_lvl_q_2]
            A_lvl_2_q_stop_2 = A_lvl_2.ptr[A_lvl_q_2 + 1]
            if A_lvl_2_q_2 < A_lvl_2_q_stop_2
                A_lvl_2_i_2 = A_lvl_2.idx[A_lvl_2_q_2]
                A_lvl_2_i1_2 = A_lvl_2.idx[A_lvl_2_q_stop_2 - 1]
            else
                A_lvl_2_i_2 = 1
                A_lvl_2_i1_2 = 0
            end
            k = 1
            k_start = k
            phase_stop = (min)(A_lvl_2.I, A_lvl_2_i1_2, A_lvl_2_i1)
            if phase_stop >= k_start
                k_4 = k
                k = k_start
                while A_lvl_2_q + 1 < A_lvl_2_q_stop && A_lvl_2.idx[A_lvl_2_q] < k_start
                    A_lvl_2_q += 1
                end
                while A_lvl_2_q_2 + 1 < A_lvl_2_q_stop_2 && A_lvl_2.idx[A_lvl_2_q_2] < k_start
                    A_lvl_2_q_2 += 1
                end
                while k <= phase_stop
                    k_start_2 = k
                    A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                    A_lvl_2_i_2 = A_lvl_2.idx[A_lvl_2_q_2]
                    phase_stop_2 = (min)(A_lvl_2_i_2, A_lvl_2_i, phase_stop)
                    k_5 = k
                    if A_lvl_2_i == phase_stop_2 && A_lvl_2_i_2 == phase_stop_2
                        A_lvl_3_val_2 = A_lvl_3.val[A_lvl_2_q]
                        A_lvl_3_val_3 = A_lvl_3.val[A_lvl_2_q_2]
                        k_6 = phase_stop_2
                        B_lvl_2dirty = true
                        B_lvl_2dirty = true
                        B_lvl_3_val_2 = (+)(B_lvl_3_val_2, (*)(A_lvl_3_val_3, A_lvl_3_val_2))
                        A_lvl_2_q += 1
                        A_lvl_2_q_2 += 1
                    elseif A_lvl_2_i_2 == phase_stop_2
                        A_lvl_3_val_3 = A_lvl_3.val[A_lvl_2_q_2]
                        A_lvl_2_q_2 += 1
                    elseif A_lvl_2_i == phase_stop_2
                        A_lvl_3_val_2 = A_lvl_3.val[A_lvl_2_q]
                        A_lvl_2_q += 1
                    else
                    end
                    k = phase_stop_2 + 1
                end
                k = phase_stop + 1
            end
            k_start = k
            phase_stop_3 = (min)(A_lvl_2.I, A_lvl_2_i1)
            if phase_stop_3 >= k_start
                k_7 = k
                k = phase_stop_3 + 1
            end
            k_start = k
            phase_stop_4 = (min)(A_lvl_2.I, A_lvl_2_i1_2)
            if phase_stop_4 >= k_start
                k_8 = k
                k = phase_stop_4 + 1
            end
            k_start = k
            if A_lvl_2.I >= k_start
                k_9 = k
                k = A_lvl_2.I + 1
            end
            B_lvl_3.val[B_lvl_2_qos] = B_lvl_3_val_2
            if B_lvl_2dirty
                null = true
                B_lvl_2.idx[B_lvl_2_qos] = i_4
                B_lvl_2_qos += 1
            end
        end
        B_lvl_2.ptr[B_lvl_q + 1] = (B_lvl_2_qos - B_lvl_2_qos_fill) - 1
        B_lvl_2_qos_fill = B_lvl_2_qos - 1
    end
    for p = 2:A_lvl.I + 1
        B_lvl_2.ptr[p] += B_lvl_2.ptr[p - 1]
    end
    qos_stop = B_lvl_2.ptr[A_lvl.I + 1] - 1
    qos = 1 * A_lvl.I
    resize!(B_lvl_2.ptr, qos + 1)
    qos_2 = B_lvl_2.ptr[end] - 1
    resize!(B_lvl_2.idx, qos_2)
    resize!(B_lvl_3.val, qos_2)
    (B = Fiber((Finch.DenseLevel){Int32}((Finch.SparseListLevel){Int32}(B_lvl_3, A_lvl.I, B_lvl_2.ptr, B_lvl_2.idx), A_lvl.I)),)
end
