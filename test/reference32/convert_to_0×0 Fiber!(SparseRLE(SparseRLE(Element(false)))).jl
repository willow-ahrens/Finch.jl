begin
    tmp_lvl = (ex.bodies[1]).tns.bind.lvl
    tmp_lvl_ptr = tmp_lvl.ptr
    tmp_lvl_left = tmp_lvl.left
    tmp_lvl_right = tmp_lvl.right
    tmp_lvl_2 = tmp_lvl.lvl
    tmp_lvl_ptr_2 = tmp_lvl_2.ptr
    tmp_lvl_left_2 = tmp_lvl_2.left
    tmp_lvl_right_2 = tmp_lvl_2.right
    tmp_lvl_3 = tmp_lvl_2.lvl
    tmp_lvl_2_val = tmp_lvl_2.lvl.val
    ref_lvl = (ex.bodies[2]).body.body.rhs.tns.bind.lvl
    ref_lvl_ptr = ref_lvl.ptr
    ref_lvl_idx = ref_lvl.idx
    ref_lvl_2 = ref_lvl.lvl
    ref_lvl_ptr_2 = ref_lvl_2.ptr
    ref_lvl_idx_2 = ref_lvl_2.idx
    ref_lvl_2_val = ref_lvl_2.lvl.val
    tmp_lvl_qos_stop = 0
    tmp_lvl_2_qos_fill = 0
    tmp_lvl_2_qos_stop = 0
    tmp_lvl_2_prev_pos = 0
    Finch.resize_if_smaller!(tmp_lvl_ptr, 1 + 1)
    Finch.fill_range!(tmp_lvl_ptr, 0, 1 + 1, 1 + 1)
    tmp_lvl_qos = 0 + 1
    0 < 1 || throw(FinchProtocolError("SparseRLELevels cannot be updated multiple times"))
    ref_lvl_q = ref_lvl_ptr[1]
    ref_lvl_q_stop = ref_lvl_ptr[1 + 1]
    if ref_lvl_q < ref_lvl_q_stop
        ref_lvl_i1 = ref_lvl_idx[ref_lvl_q_stop - 1]
    else
        ref_lvl_i1 = 0
    end
    phase_stop = min(ref_lvl_i1, ref_lvl.shape)
    if phase_stop >= 1
        j = 1
        if ref_lvl_idx[ref_lvl_q] < 1
            ref_lvl_q = Finch.scansearch(ref_lvl_idx, 1, ref_lvl_q, ref_lvl_q_stop - 1)
        end
        while j <= phase_stop
            ref_lvl_i = ref_lvl_idx[ref_lvl_q]
            phase_stop_2 = min(phase_stop, ref_lvl_i)
            if ref_lvl_i == phase_stop_2
                if tmp_lvl_qos > tmp_lvl_qos_stop
                    tmp_lvl_qos_stop = max(tmp_lvl_qos_stop << 1, 1)
                    Finch.resize_if_smaller!(tmp_lvl_left, tmp_lvl_qos_stop)
                    Finch.resize_if_smaller!(tmp_lvl_right, tmp_lvl_qos_stop)
                    Finch.resize_if_smaller!(tmp_lvl_ptr_2, tmp_lvl_qos_stop + 1)
                    Finch.fill_range!(tmp_lvl_ptr_2, 0, tmp_lvl_qos + 1, tmp_lvl_qos_stop + 1)
                end
                tmp_lvldirty = false
                tmp_lvl_2_qos = tmp_lvl_2_qos_fill + 1
                tmp_lvl_2_prev_pos < tmp_lvl_qos || throw(FinchProtocolError("SparseRLELevels cannot be updated multiple times"))
                ref_lvl_2_q = ref_lvl_ptr_2[ref_lvl_q]
                ref_lvl_2_q_stop = ref_lvl_ptr_2[ref_lvl_q + 1]
                if ref_lvl_2_q < ref_lvl_2_q_stop
                    ref_lvl_2_i1 = ref_lvl_idx_2[ref_lvl_2_q_stop - 1]
                else
                    ref_lvl_2_i1 = 0
                end
                phase_stop_3 = min(ref_lvl_2_i1, ref_lvl_2.shape)
                if phase_stop_3 >= 1
                    i = 1
                    if ref_lvl_idx_2[ref_lvl_2_q] < 1
                        ref_lvl_2_q = Finch.scansearch(ref_lvl_idx_2, 1, ref_lvl_2_q, ref_lvl_2_q_stop - 1)
                    end
                    while i <= phase_stop_3
                        ref_lvl_2_i = ref_lvl_idx_2[ref_lvl_2_q]
                        phase_stop_4 = min(phase_stop_3, ref_lvl_2_i)
                        if ref_lvl_2_i == phase_stop_4
                            ref_lvl_3_val = ref_lvl_2_val[ref_lvl_2_q]
                            if tmp_lvl_2_qos > tmp_lvl_2_qos_stop
                                tmp_lvl_2_qos_stop = max(tmp_lvl_2_qos_stop << 1, 1)
                                Finch.resize_if_smaller!(tmp_lvl_left_2, tmp_lvl_2_qos_stop)
                                Finch.resize_if_smaller!(tmp_lvl_right_2, tmp_lvl_2_qos_stop)
                                Finch.resize_if_smaller!(tmp_lvl_2_val, tmp_lvl_2_qos_stop)
                                Finch.fill_range!(tmp_lvl_2_val, false, tmp_lvl_2_qos, tmp_lvl_2_qos_stop)
                            end
                            tmp_lvl_2_val[tmp_lvl_2_qos] = ref_lvl_3_val
                            tmp_lvldirty = true
                            tmp_lvl_left_2[tmp_lvl_2_qos] = phase_stop_4
                            tmp_lvl_right_2[tmp_lvl_2_qos] = phase_stop_4
                            tmp_lvl_2_qos += 1
                            tmp_lvl_2_prev_pos = tmp_lvl_qos
                            ref_lvl_2_q += 1
                        end
                        i = phase_stop_4 + 1
                    end
                end
                tmp_lvl_ptr_2[tmp_lvl_qos + 1] = (tmp_lvl_2_qos - tmp_lvl_2_qos_fill) - 1
                tmp_lvl_2_qos_fill = tmp_lvl_2_qos - 1
                if tmp_lvldirty
                    tmp_lvl_left[tmp_lvl_qos] = phase_stop_2
                    tmp_lvl_right[tmp_lvl_qos] = phase_stop_2
                    tmp_lvl_qos += 1
                end
                ref_lvl_q += 1
            end
            j = phase_stop_2 + 1
        end
    end
    tmp_lvl_ptr[1 + 1] = (tmp_lvl_qos - 0) - 1
    for p = 2:1 + 1
        tmp_lvl_ptr[p] += tmp_lvl_ptr[p - 1]
    end
    qos_stop = tmp_lvl_ptr[1 + 1] - 1
    for p_2 = 2:qos_stop + 1
        tmp_lvl_ptr_2[p_2] += tmp_lvl_ptr_2[p_2 - 1]
    end
    resize!(tmp_lvl_ptr, 1 + 1)
    qos = tmp_lvl_ptr[end] - 1
    resize!(tmp_lvl_left, qos)
    resize!(tmp_lvl_right, qos)
    resize!(tmp_lvl_ptr_2, qos + 1)
    qos_2 = tmp_lvl_ptr_2[end] - 1
    resize!(tmp_lvl_left_2, qos_2)
    resize!(tmp_lvl_right_2, qos_2)
    resize!(tmp_lvl_2_val, qos_2)
    (tmp = Fiber((SparseRLELevel){Int32}((SparseRLELevel){Int32}(tmp_lvl_3, ref_lvl_2.shape, tmp_lvl_ptr_2, tmp_lvl_left_2, tmp_lvl_right_2), ref_lvl.shape, tmp_lvl_ptr, tmp_lvl_left, tmp_lvl_right)),)
end
