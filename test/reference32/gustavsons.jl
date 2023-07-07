begin
    B_lvl = (ex.bodies[1]).tns.tns.lvl
    B_lvl_2 = B_lvl.lvl
    B_lvl_3 = B_lvl_2.lvl
    w_lvl = ((ex.bodies[2]).body.bodies[1]).tns.tns.lvl
    w_lvl_qos_stop = (w_lvl_qos_fill = length(w_lvl.srt))
    w_lvl_2 = w_lvl.lvl
    A_lvl = (((ex.bodies[2]).body.bodies[2]).body.body.rhs.args[1]).tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_3 = A_lvl_2.lvl
    A_lvl_2.shape == A_lvl.shape || throw(DimensionMismatch("mismatched dimension limits ($(A_lvl_2.shape) != $(A_lvl.shape))"))
    B_lvl_2_qos_fill = 0
    B_lvl_2_qos_stop = 0
    p_start_2 = A_lvl.shape
    resize_if_smaller!(B_lvl_2.ptr, p_start_2 + 1)
    fill_range!(B_lvl_2.ptr, 0, 1 + 1, p_start_2 + 1)
    for j_4 = 1:A_lvl.shape
        A_lvl_q = (1 - 1) * A_lvl.shape + j_4
        B_lvl_q = (1 - 1) * A_lvl.shape + j_4
        for w_lvl_r = 1:w_lvl_qos_fill
            w_lvl_p = first(w_lvl.srt[w_lvl_r])
            w_lvl.ptr[w_lvl_p] = 0
            w_lvl.ptr[w_lvl_p + 1] = 0
            w_lvl_i = last(w_lvl.srt[w_lvl_r])
            w_lvl_q = (w_lvl_p - 1) * A_lvl_2.shape + w_lvl_i
            w_lvl.tbl[w_lvl_q] = false
            resize_if_smaller!(w_lvl_2.val, w_lvl_q)
            fill_range!(w_lvl_2.val, 0.0, w_lvl_q, w_lvl_q)
        end
        w_lvl_qos_fill = 0
        w_lvl.ptr[1] = 1
        w_lvlq_start = (1 - 1) * A_lvl_2.shape + 1
        w_lvlq_stop = 1 * A_lvl_2.shape
        resize_if_smaller!(w_lvl.ptr, 1 + 1)
        fill_range!(w_lvl.ptr, 0, 1 + 1, 1 + 1)
        resize_if_smaller!(w_lvl.tbl, w_lvlq_stop)
        fill_range!(w_lvl.tbl, false, w_lvlq_start, w_lvlq_stop)
        resize_if_smaller!(w_lvl_2.val, w_lvlq_stop)
        fill_range!(w_lvl_2.val, 0.0, w_lvlq_start, w_lvlq_stop)
        A_lvl_2_q = A_lvl_2.ptr[A_lvl_q]
        A_lvl_2_q_stop = A_lvl_2.ptr[A_lvl_q + 1]
        if A_lvl_2_q < A_lvl_2_q_stop
            A_lvl_2_i1 = A_lvl_2.idx[A_lvl_2_q_stop - 1]
        else
            A_lvl_2_i1 = 0
        end
        phase_stop = min(A_lvl_2.shape, A_lvl_2_i1)
        if phase_stop >= 1
            k = 1
            if A_lvl_2.idx[A_lvl_2_q] < 1
                A_lvl_2_q = scansearch(A_lvl_2.idx, 1, A_lvl_2_q, A_lvl_2_q_stop - 1)
            end
            while k <= phase_stop
                A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                phase_stop_2 = min(phase_stop, A_lvl_2_i)
                if A_lvl_2_i == phase_stop_2
                    A_lvl_3_val_2 = A_lvl_3.val[A_lvl_2_q]
                    A_lvl_q_2 = (1 - 1) * A_lvl.shape + phase_stop_2
                    A_lvl_2_q_2 = A_lvl_2.ptr[A_lvl_q_2]
                    A_lvl_2_q_stop_2 = A_lvl_2.ptr[A_lvl_q_2 + 1]
                    if A_lvl_2_q_2 < A_lvl_2_q_stop_2
                        A_lvl_2_i1_2 = A_lvl_2.idx[A_lvl_2_q_stop_2 - 1]
                    else
                        A_lvl_2_i1_2 = 0
                    end
                    phase_stop_3 = min(A_lvl_2.shape, A_lvl_2_i1_2)
                    if phase_stop_3 >= 1
                        i = 1
                        if A_lvl_2.idx[A_lvl_2_q_2] < 1
                            A_lvl_2_q_2 = scansearch(A_lvl_2.idx, 1, A_lvl_2_q_2, A_lvl_2_q_stop_2 - 1)
                        end
                        while i <= phase_stop_3
                            A_lvl_2_i_2 = A_lvl_2.idx[A_lvl_2_q_2]
                            phase_stop_4 = min(phase_stop_3, A_lvl_2_i_2)
                            if A_lvl_2_i_2 == phase_stop_4
                                A_lvl_3_val_3 = A_lvl_3.val[A_lvl_2_q_2]
                                w_lvl_q_2 = (1 - 1) * A_lvl_2.shape + phase_stop_4
                                w_lvl_2.val[w_lvl_q_2] = A_lvl_3_val_2 * A_lvl_3_val_3 + w_lvl_2.val[w_lvl_q_2]
                                if !(w_lvl.tbl[w_lvl_q_2])
                                    w_lvl.tbl[w_lvl_q_2] = true
                                    w_lvl_qos_fill += 1
                                    if w_lvl_qos_fill > w_lvl_qos_stop
                                        w_lvl_qos_stop = max(w_lvl_qos_stop << 1, 1)
                                        resize_if_smaller!(w_lvl.srt, w_lvl_qos_stop)
                                    end
                                    w_lvl.srt[w_lvl_qos_fill] = (1, phase_stop_4)
                                end
                                A_lvl_2_q_2 += 1
                            end
                            i = phase_stop_4 + 1
                        end
                    end
                    A_lvl_2_q += 1
                end
                k = phase_stop_2 + 1
            end
        end
        sort!(view(w_lvl.srt, 1:w_lvl_qos_fill))
        w_lvl_p_prev = 0
        for w_lvl_r_2 = 1:w_lvl_qos_fill
            w_lvl_p_2 = first(w_lvl.srt[w_lvl_r_2])
            if w_lvl_p_2 != w_lvl_p_prev
                w_lvl.ptr[w_lvl_p_prev + 1] = w_lvl_r_2
                w_lvl.ptr[w_lvl_p_2] = w_lvl_r_2
            end
            w_lvl_p_prev = w_lvl_p_2
        end
        w_lvl.ptr[w_lvl_p_2 + 1] = w_lvl_qos_fill + 1
        B_lvl_2_qos = B_lvl_2_qos_fill + 1
        w_lvl_r_3 = w_lvl.ptr[1]
        w_lvl_r_stop = w_lvl.ptr[1 + 1]
        if w_lvl_r_3 != 0 && w_lvl_r_3 < w_lvl_r_stop
            w_lvl_i_stop = last(w_lvl.srt[w_lvl_r_stop - 1])
        else
            w_lvl_i_stop = 0
        end
        phase_stop_7 = min(A_lvl_2.shape, w_lvl_i_stop)
        if phase_stop_7 >= 1
            i_2 = 1
            while w_lvl_r_3 + 1 < w_lvl_r_stop && last(w_lvl.srt[w_lvl_r_3]) < 1
                w_lvl_r_3 += 1
            end
            while i_2 <= phase_stop_7
                w_lvl_i_2 = last(w_lvl.srt[w_lvl_r_3])
                phase_stop_8 = min(phase_stop_7, w_lvl_i_2)
                if w_lvl_i_2 == phase_stop_8
                    w_lvl_q_3 = (1 - 1) * A_lvl_2.shape + w_lvl_i_2
                    w_lvl_2_val_2 = w_lvl_2.val[w_lvl_q_3]
                    if B_lvl_2_qos > B_lvl_2_qos_stop
                        B_lvl_2_qos_stop = max(B_lvl_2_qos_stop << 1, 1)
                        resize_if_smaller!(B_lvl_2.idx, B_lvl_2_qos_stop)
                        resize_if_smaller!(B_lvl_3.val, B_lvl_2_qos_stop)
                        fill_range!(B_lvl_3.val, 0.0, B_lvl_2_qos, B_lvl_2_qos_stop)
                    end
                    B_lvl_3.val[B_lvl_2_qos] = w_lvl_2_val_2
                    B_lvl_2.idx[B_lvl_2_qos] = phase_stop_8
                    B_lvl_2_qos += 1
                    w_lvl_r_3 += 1
                end
                i_2 = phase_stop_8 + 1
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
    (B = Fiber((DenseLevel){Int32}((SparseListLevel){Int32, Int32}(B_lvl_3, A_lvl_2.shape, B_lvl_2.ptr, B_lvl_2.idx), A_lvl.shape)),)
end
