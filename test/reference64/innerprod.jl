begin
    B_lvl = (ex.bodies[1]).tns.tns.lvl
    B_lvl_2 = B_lvl.lvl
    B_lvl_3 = B_lvl_2.lvl
    A_lvl = ((ex.bodies[2]).body.body.body.rhs.args[1]).tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_3 = A_lvl_2.lvl
    B_lvl_2_qos_fill = 0
    B_lvl_2_qos_stop = 0
    p_start_2 = A_lvl.shape
    Finch.resize_if_smaller!(B_lvl_2.ptr, p_start_2 + 1)
    Finch.fill_range!(B_lvl_2.ptr, 0, 1 + 1, p_start_2 + 1)
    for j_4 = 1:A_lvl.shape
        B_lvl_q = (1 - 1) * A_lvl.shape + j_4
        A_lvl_q = (1 - 1) * A_lvl.shape + j_4
        B_lvl_2_qos = B_lvl_2_qos_fill + 1
        for i_4 = 1:A_lvl.shape
            if B_lvl_2_qos > B_lvl_2_qos_stop
                B_lvl_2_qos_stop = max(B_lvl_2_qos_stop << 1, 1)
                Finch.resize_if_smaller!(B_lvl_2.idx, B_lvl_2_qos_stop)
                Finch.resize_if_smaller!(B_lvl_3.val, B_lvl_2_qos_stop)
                Finch.fill_range!(B_lvl_3.val, 0.0, B_lvl_2_qos, B_lvl_2_qos_stop)
            end
            B_lvl_2dirty = false
            A_lvl_q_2 = (1 - 1) * A_lvl.shape + i_4
            A_lvl_2_q = A_lvl_2.ptr[A_lvl_q]
            A_lvl_2_q_stop = A_lvl_2.ptr[A_lvl_q + 1]
            if A_lvl_2_q < A_lvl_2_q_stop
                A_lvl_2_i1 = A_lvl_2.idx[A_lvl_2_q_stop - 1]
            else
                A_lvl_2_i1 = 0
            end
            A_lvl_2_q_2 = A_lvl_2.ptr[A_lvl_q_2]
            A_lvl_2_q_stop_2 = A_lvl_2.ptr[A_lvl_q_2 + 1]
            if A_lvl_2_q_2 < A_lvl_2_q_stop_2
                A_lvl_2_i1_2 = A_lvl_2.idx[A_lvl_2_q_stop_2 - 1]
            else
                A_lvl_2_i1_2 = 0
            end
            phase_stop = min(A_lvl_2.shape, A_lvl_2_i1, A_lvl_2_i1_2)
            if phase_stop >= 1
                k = 1
                if A_lvl_2.idx[A_lvl_2_q] < 1
                    A_lvl_2_q = Finch.scansearch(A_lvl_2.idx, 1, A_lvl_2_q, A_lvl_2_q_stop - 1)
                end
                if A_lvl_2.idx[A_lvl_2_q_2] < 1
                    A_lvl_2_q_2 = Finch.scansearch(A_lvl_2.idx, 1, A_lvl_2_q_2, A_lvl_2_q_stop_2 - 1)
                end
                while k <= phase_stop
                    A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                    A_lvl_2_i_2 = A_lvl_2.idx[A_lvl_2_q_2]
                    phase_stop_2 = min(A_lvl_2_i_2, phase_stop, A_lvl_2_i)
                    if phase_stop_2 >= k
                        if A_lvl_2_i == phase_stop_2 && A_lvl_2_i_2 == phase_stop_2
                            A_lvl_3_val_2 = A_lvl_3.val[A_lvl_2_q]
                            A_lvl_3_val_3 = A_lvl_3.val[A_lvl_2_q_2]
                            B_lvl_2dirty = true
                            B_lvl_3.val[B_lvl_2_qos] = B_lvl_3.val[B_lvl_2_qos] + A_lvl_3_val_3 * A_lvl_3_val_2
                            A_lvl_2_q += 1
                            A_lvl_2_q_2 += 1
                        elseif A_lvl_2_i_2 == phase_stop_2
                            A_lvl_2_q_2 += 1
                        elseif A_lvl_2_i == phase_stop_2
                            A_lvl_2_q += 1
                        end
                        k = phase_stop_2 + 1
                    end
                end
            end
            if B_lvl_2dirty
                B_lvl_2.idx[B_lvl_2_qos] = i_4
                B_lvl_2_qos += 1
            end
        end
        B_lvl_2.ptr[B_lvl_q + 1] = (B_lvl_2_qos - B_lvl_2_qos_fill) - 1
        B_lvl_2_qos_fill = B_lvl_2_qos - 1
    end
    for p = 2:A_lvl.shape + 1
        B_lvl_2.ptr[p] += B_lvl_2.ptr[p - 1]
    end
    qos = 1 * A_lvl.shape
    resize!(B_lvl_2.ptr, qos + 1)
    qos_2 = B_lvl_2.ptr[end] - 1
    resize!(B_lvl_2.idx, qos_2)
    resize!(B_lvl_3.val, qos_2)
    (B = Fiber((DenseLevel){Int64}((SparseListLevel){Int64, Int64}(B_lvl_3, A_lvl.shape, B_lvl_2.ptr, B_lvl_2.idx), A_lvl.shape)),)
end
