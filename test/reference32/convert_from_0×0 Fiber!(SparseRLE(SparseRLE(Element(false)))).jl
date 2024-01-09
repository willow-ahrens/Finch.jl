begin
    res_lvl = (ex.bodies[1]).tns.bind.lvl
    res_lvl_ptr = res_lvl.ptr
    res_lvl_idx = res_lvl.idx
    res_lvl_2 = res_lvl.lvl
    res_lvl_ptr_2 = res_lvl_2.ptr
    res_lvl_idx_2 = res_lvl_2.idx
    res_lvl_3 = res_lvl_2.lvl
    res_lvl_2_val = res_lvl_2.lvl.val
    tmp_lvl = (ex.bodies[2]).body.body.rhs.tns.bind.lvl
    tmp_lvl_ptr = tmp_lvl.ptr
    tmp_lvl_left = tmp_lvl.left
    tmp_lvl_right = tmp_lvl.right
    tmp_lvl_2 = tmp_lvl.lvl
    tmp_lvl_ptr_2 = tmp_lvl_2.ptr
    tmp_lvl_left_2 = tmp_lvl_2.left
    tmp_lvl_right_2 = tmp_lvl_2.right
    tmp_lvl_2_val = tmp_lvl_2.lvl.val
    res_lvl_qos_stop = 0
    res_lvl_2_qos_fill = 0
    res_lvl_2_qos_stop = 0
    res_lvl_2_prev_pos = 0
    Finch.resize_if_smaller!(res_lvl_ptr, 1 + 1)
    Finch.fill_range!(res_lvl_ptr, 0, 1 + 1, 1 + 1)
    res_lvl_qos = 0 + 1
    0 < 1 || throw(FinchProtocolError("SparseListLevels cannot be updated multiple times"))
    tmp_lvl_q = tmp_lvl_ptr[1]
    tmp_lvl_q_stop = tmp_lvl_ptr[1 + 1]
    if tmp_lvl_q < tmp_lvl_q_stop
        tmp_lvl_i_end = tmp_lvl_right[tmp_lvl_q_stop - 1]
    else
        tmp_lvl_i_end = 0
    end
    phase_stop = min(tmp_lvl_i_end, tmp_lvl.shape)
    if phase_stop >= 1
        j = 1
        if tmp_lvl_right[tmp_lvl_q] < 1
            tmp_lvl_q = Finch.scansearch(tmp_lvl_right, 1, tmp_lvl_q, tmp_lvl_q_stop - 1)
        end
        while true
            j_start_2 = j
            tmp_lvl_i_start = tmp_lvl_left[tmp_lvl_q]
            tmp_lvl_i_stop = tmp_lvl_right[tmp_lvl_q]
            if tmp_lvl_i_stop < phase_stop
                phase_start_3 = max(j_start_2, tmp_lvl_i_start)
                if tmp_lvl_i_stop >= phase_start_3
                    for j_8 = phase_start_3:tmp_lvl_i_stop
                        if res_lvl_qos > res_lvl_qos_stop
                            res_lvl_qos_stop = max(res_lvl_qos_stop << 1, 1)
                            Finch.resize_if_smaller!(res_lvl_idx, res_lvl_qos_stop)
                            Finch.resize_if_smaller!(res_lvl_ptr_2, res_lvl_qos_stop + 1)
                            Finch.fill_range!(res_lvl_ptr_2, 0, res_lvl_qos + 1, res_lvl_qos_stop + 1)
                        end
                        res_lvldirty = false
                        res_lvl_2_qos = res_lvl_2_qos_fill + 1
                        res_lvl_2_prev_pos < res_lvl_qos || throw(FinchProtocolError("SparseListLevels cannot be updated multiple times"))
                        tmp_lvl_2_q = tmp_lvl_ptr_2[tmp_lvl_q]
                        tmp_lvl_2_q_stop = tmp_lvl_ptr_2[tmp_lvl_q + 1]
                        if tmp_lvl_2_q < tmp_lvl_2_q_stop
                            tmp_lvl_2_i_end = tmp_lvl_right_2[tmp_lvl_2_q_stop - 1]
                        else
                            tmp_lvl_2_i_end = 0
                        end
                        phase_stop_5 = min(tmp_lvl_2_i_end, tmp_lvl_2.shape)
                        if phase_stop_5 >= 1
                            i = 1
                            if tmp_lvl_right_2[tmp_lvl_2_q] < 1
                                tmp_lvl_2_q = Finch.scansearch(tmp_lvl_right_2, 1, tmp_lvl_2_q, tmp_lvl_2_q_stop - 1)
                            end
                            while true
                                i_start_2 = i
                                tmp_lvl_2_i_start = tmp_lvl_left_2[tmp_lvl_2_q]
                                tmp_lvl_2_i_stop = tmp_lvl_right_2[tmp_lvl_2_q]
                                if tmp_lvl_2_i_stop < phase_stop_5
                                    phase_start_6 = max(i_start_2, tmp_lvl_2_i_start)
                                    if tmp_lvl_2_i_stop >= phase_start_6
                                        tmp_lvl_3_val = tmp_lvl_2_val[tmp_lvl_2_q]
                                        for i_8 = phase_start_6:tmp_lvl_2_i_stop
                                            if res_lvl_2_qos > res_lvl_2_qos_stop
                                                res_lvl_2_qos_stop = max(res_lvl_2_qos_stop << 1, 1)
                                                Finch.resize_if_smaller!(res_lvl_idx_2, res_lvl_2_qos_stop)
                                                Finch.resize_if_smaller!(res_lvl_2_val, res_lvl_2_qos_stop)
                                                Finch.fill_range!(res_lvl_2_val, false, res_lvl_2_qos, res_lvl_2_qos_stop)
                                            end
                                            res = (res_lvl_2_val[res_lvl_2_qos] = tmp_lvl_3_val)
                                            res_lvldirty = true
                                            res_lvl_idx_2[res_lvl_2_qos] = i_8
                                            res_lvl_2_qos += 1
                                            res_lvl_2_prev_pos = res_lvl_qos
                                        end
                                    end
                                    tmp_lvl_2_q += tmp_lvl_2_i_stop == tmp_lvl_2_i_stop
                                    i = tmp_lvl_2_i_stop + 1
                                else
                                    phase_start_7 = i
                                    phase_stop_9 = min(tmp_lvl_2_i_stop, phase_stop_5)
                                    phase_start_9 = max(tmp_lvl_2_i_start, phase_start_7)
                                    if phase_stop_9 >= phase_start_9
                                        tmp_lvl_3_val_2 = tmp_lvl_2_val[tmp_lvl_2_q]
                                        for i_11 = phase_start_9:phase_stop_9
                                            if res_lvl_2_qos > res_lvl_2_qos_stop
                                                res_lvl_2_qos_stop = max(res_lvl_2_qos_stop << 1, 1)
                                                Finch.resize_if_smaller!(res_lvl_idx_2, res_lvl_2_qos_stop)
                                                Finch.resize_if_smaller!(res_lvl_2_val, res_lvl_2_qos_stop)
                                                Finch.fill_range!(res_lvl_2_val, false, res_lvl_2_qos, res_lvl_2_qos_stop)
                                            end
                                            res_lvl_2_val[res_lvl_2_qos] = tmp_lvl_3_val_2
                                            res_lvldirty = true
                                            res_lvl_idx_2[res_lvl_2_qos] = i_11
                                            res_lvl_2_qos += 1
                                            res_lvl_2_prev_pos = res_lvl_qos
                                        end
                                    end
                                    tmp_lvl_2_q += phase_stop_9 == tmp_lvl_2_i_stop
                                    i = phase_stop_9 + 1
                                    break
                                end
                            end
                        end
                        res_lvl_ptr_2[res_lvl_qos + 1] += (res_lvl_2_qos - res_lvl_2_qos_fill) - 1
                        res_lvl_2_qos_fill = res_lvl_2_qos - 1
                        if res_lvldirty
                            res_lvl_idx[res_lvl_qos] = j_8
                            res_lvl_qos += 1
                        end
                    end
                end
                tmp_lvl_q += tmp_lvl_i_stop == tmp_lvl_i_stop
                j = tmp_lvl_i_stop + 1
            else
                phase_start_11 = j
                phase_stop_13 = min(tmp_lvl_i_stop, phase_stop)
                phase_start_13 = max(tmp_lvl_i_start, phase_start_11)
                if phase_stop_13 >= phase_start_13
                    for j_11 = phase_start_13:phase_stop_13
                        if res_lvl_qos > res_lvl_qos_stop
                            res_lvl_qos_stop = max(res_lvl_qos_stop << 1, 1)
                            Finch.resize_if_smaller!(res_lvl_idx, res_lvl_qos_stop)
                            Finch.resize_if_smaller!(res_lvl_ptr_2, res_lvl_qos_stop + 1)
                            Finch.fill_range!(res_lvl_ptr_2, 0, res_lvl_qos + 1, res_lvl_qos_stop + 1)
                        end
                        res_lvldirty = false
                        res_lvl_2_qos_2 = res_lvl_2_qos_fill + 1
                        res_lvl_2_prev_pos < res_lvl_qos || throw(FinchProtocolError("SparseListLevels cannot be updated multiple times"))
                        tmp_lvl_2_q_2 = tmp_lvl_ptr_2[tmp_lvl_q]
                        tmp_lvl_2_q_stop_2 = tmp_lvl_ptr_2[tmp_lvl_q + 1]
                        if tmp_lvl_2_q_2 < tmp_lvl_2_q_stop_2
                            tmp_lvl_2_i_end_2 = tmp_lvl_right_2[tmp_lvl_2_q_stop_2 - 1]
                        else
                            tmp_lvl_2_i_end_2 = 0
                        end
                        phase_stop_16 = min(tmp_lvl_2.shape, tmp_lvl_2_i_end_2)
                        if phase_stop_16 >= 1
                            i = 1
                            if tmp_lvl_right_2[tmp_lvl_2_q_2] < 1
                                tmp_lvl_2_q_2 = Finch.scansearch(tmp_lvl_right_2, 1, tmp_lvl_2_q_2, tmp_lvl_2_q_stop_2 - 1)
                            end
                            while true
                                i_start_6 = i
                                tmp_lvl_2_i_start_2 = tmp_lvl_left_2[tmp_lvl_2_q_2]
                                tmp_lvl_2_i_stop_2 = tmp_lvl_right_2[tmp_lvl_2_q_2]
                                if tmp_lvl_2_i_stop_2 < phase_stop_16
                                    phase_start_16 = max(i_start_6, tmp_lvl_2_i_start_2)
                                    if tmp_lvl_2_i_stop_2 >= phase_start_16
                                        tmp_lvl_3_val_3 = tmp_lvl_2_val[tmp_lvl_2_q_2]
                                        for i_17 = phase_start_16:tmp_lvl_2_i_stop_2
                                            if res_lvl_2_qos_2 > res_lvl_2_qos_stop
                                                res_lvl_2_qos_stop = max(res_lvl_2_qos_stop << 1, 1)
                                                Finch.resize_if_smaller!(res_lvl_idx_2, res_lvl_2_qos_stop)
                                                Finch.resize_if_smaller!(res_lvl_2_val, res_lvl_2_qos_stop)
                                                Finch.fill_range!(res_lvl_2_val, false, res_lvl_2_qos_2, res_lvl_2_qos_stop)
                                            end
                                            res_lvl_2_val[res_lvl_2_qos_2] = tmp_lvl_3_val_3
                                            res_lvldirty = true
                                            res_lvl_idx_2[res_lvl_2_qos_2] = i_17
                                            res_lvl_2_qos_2 += 1
                                            res_lvl_2_prev_pos = res_lvl_qos
                                        end
                                    end
                                    tmp_lvl_2_q_2 += tmp_lvl_2_i_stop_2 == tmp_lvl_2_i_stop_2
                                    i = tmp_lvl_2_i_stop_2 + 1
                                else
                                    phase_start_17 = i
                                    phase_stop_20 = min(tmp_lvl_2_i_stop_2, phase_stop_16)
                                    phase_start_19 = max(tmp_lvl_2_i_start_2, phase_start_17)
                                    if phase_stop_20 >= phase_start_19
                                        tmp_lvl_3_val_4 = tmp_lvl_2_val[tmp_lvl_2_q_2]
                                        for i_20 = phase_start_19:phase_stop_20
                                            if res_lvl_2_qos_2 > res_lvl_2_qos_stop
                                                res_lvl_2_qos_stop = max(res_lvl_2_qos_stop << 1, 1)
                                                Finch.resize_if_smaller!(res_lvl_idx_2, res_lvl_2_qos_stop)
                                                Finch.resize_if_smaller!(res_lvl_2_val, res_lvl_2_qos_stop)
                                                Finch.fill_range!(res_lvl_2_val, false, res_lvl_2_qos_2, res_lvl_2_qos_stop)
                                            end
                                            res_lvl_2_val[res_lvl_2_qos_2] = tmp_lvl_3_val_4
                                            res_lvldirty = true
                                            res_lvl_idx_2[res_lvl_2_qos_2] = i_20
                                            res_lvl_2_qos_2 += 1
                                            res_lvl_2_prev_pos = res_lvl_qos
                                        end
                                    end
                                    tmp_lvl_2_q_2 += phase_stop_20 == tmp_lvl_2_i_stop_2
                                    i = phase_stop_20 + 1
                                    break
                                end
                            end
                        end
                        res_lvl_ptr_2[res_lvl_qos + 1] += (res_lvl_2_qos_2 - res_lvl_2_qos_fill) - 1
                        res_lvl_2_qos_fill = res_lvl_2_qos_2 - 1
                        if res_lvldirty
                            res_lvl_idx[res_lvl_qos] = j_11
                            res_lvl_qos += 1
                        end
                    end
                end
                tmp_lvl_q += phase_stop_13 == tmp_lvl_i_stop
                j = phase_stop_13 + 1
                break
            end
        end
    end
    res_lvl_ptr[1 + 1] += (res_lvl_qos - 0) - 1
    for p = 1:1
        res_lvl_ptr[p + 1] += res_lvl_ptr[p]
    end
    qos_stop = res_lvl_ptr[1 + 1] - 1
    for p_2 = 1:qos_stop
        res_lvl_ptr_2[p_2 + 1] += res_lvl_ptr_2[p_2]
    end
    resize!(res_lvl_ptr, 1 + 1)
    qos = res_lvl_ptr[end] - 1
    resize!(res_lvl_idx, qos)
    resize!(res_lvl_ptr_2, qos + 1)
    qos_2 = res_lvl_ptr_2[end] - 1
    resize!(res_lvl_idx_2, qos_2)
    resize!(res_lvl_2_val, qos_2)
    (res = Tensor((SparseListLevel){Int32}((SparseListLevel){Int32}(res_lvl_3, tmp_lvl_2.shape, res_lvl_ptr_2, res_lvl_idx_2), tmp_lvl.shape, res_lvl_ptr, res_lvl_idx)),)
end
