begin
    tmp_lvl = ((ex.bodies[1]).bodies[1]).tns.bind.lvl
    tmp_lvl_ptr = tmp_lvl.ptr
    tmp_lvl_left = tmp_lvl.left
    tmp_lvl_right = tmp_lvl.right
    tmp_lvl_2 = tmp_lvl.lvl
    tmp_lvl_ptr_2 = tmp_lvl_2.ptr
    tmp_lvl_left_2 = tmp_lvl_2.left
    tmp_lvl_right_2 = tmp_lvl_2.right
    tmp_lvl_3 = tmp_lvl_2.lvl
    tmp_lvl_2_val = tmp_lvl_2.lvl.val
    tmp_lvl_4 = tmp_lvl_2.buf
    tmp_lvl_2_val_2 = tmp_lvl_2.buf.val
    tmp_lvl_5 = tmp_lvl.buf
    tmp_lvl_ptr_3 = tmp_lvl_5.ptr
    tmp_lvl_left_3 = tmp_lvl_5.left
    tmp_lvl_right_3 = tmp_lvl_5.right
    tmp_lvl_6 = tmp_lvl_5.lvl
    tmp_lvl_5_val = tmp_lvl_5.lvl.val
    tmp_lvl_7 = tmp_lvl_5.buf
    tmp_lvl_5_val_2 = tmp_lvl_5.buf.val
    ref_lvl = ((ex.bodies[1]).bodies[2]).body.body.rhs.tns.bind.lvl
    ref_lvl_ptr = ref_lvl.ptr
    ref_lvl_idx = ref_lvl.idx
    ref_lvl_2 = ref_lvl.lvl
    ref_lvl_ptr_2 = ref_lvl_2.ptr
    ref_lvl_idx_2 = ref_lvl_2.idx
    ref_lvl_2_val = ref_lvl_2.lvl.val
    result = nothing
    tmp_lvl_qos_stop = 0
    tmp_lvl_5_qos_fill = 0
    tmp_lvl_5_qos_stop = 0
    tmp_lvl_5_prev_pos = 0
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
        if ref_lvl_idx[ref_lvl_q] < 1
            ref_lvl_q = Finch.scansearch(ref_lvl_idx, 1, ref_lvl_q, ref_lvl_q_stop - 1)
        end
        while true
            ref_lvl_i = ref_lvl_idx[ref_lvl_q]
            if ref_lvl_i < phase_stop
                if tmp_lvl_qos > tmp_lvl_qos_stop
                    tmp_lvl_qos_stop = max(tmp_lvl_qos_stop << 1, 1)
                    Finch.resize_if_smaller!(tmp_lvl_left, tmp_lvl_qos_stop)
                    Finch.resize_if_smaller!(tmp_lvl_right, tmp_lvl_qos_stop)
                    Finch.resize_if_smaller!(tmp_lvl_ptr_3, tmp_lvl_qos_stop + 1)
                    Finch.fill_range!(tmp_lvl_ptr_3, 0, tmp_lvl_qos + 1, tmp_lvl_qos_stop + 1)
                end
                tmp_lvldirty = false
                tmp_lvl_5_qos = tmp_lvl_5_qos_fill + 1
                tmp_lvl_5_prev_pos < tmp_lvl_qos || throw(FinchProtocolError("SparseRLELevels cannot be updated multiple times"))
                ref_lvl_2_q = ref_lvl_ptr_2[ref_lvl_q]
                ref_lvl_2_q_stop = ref_lvl_ptr_2[ref_lvl_q + 1]
                if ref_lvl_2_q < ref_lvl_2_q_stop
                    ref_lvl_2_i1 = ref_lvl_idx_2[ref_lvl_2_q_stop - 1]
                else
                    ref_lvl_2_i1 = 0
                end
                phase_stop_3 = min(ref_lvl_2_i1, ref_lvl_2.shape)
                if phase_stop_3 >= 1
                    if ref_lvl_idx_2[ref_lvl_2_q] < 1
                        ref_lvl_2_q = Finch.scansearch(ref_lvl_idx_2, 1, ref_lvl_2_q, ref_lvl_2_q_stop - 1)
                    end
                    while true
                        ref_lvl_2_i = ref_lvl_idx_2[ref_lvl_2_q]
                        if ref_lvl_2_i < phase_stop_3
                            ref_lvl_3_val = ref_lvl_2_val[ref_lvl_2_q]
                            if tmp_lvl_5_qos > tmp_lvl_5_qos_stop
                                tmp_lvl_5_qos_stop = max(tmp_lvl_5_qos_stop << 1, 1)
                                Finch.resize_if_smaller!(tmp_lvl_left_3, tmp_lvl_5_qos_stop)
                                Finch.resize_if_smaller!(tmp_lvl_right_3, tmp_lvl_5_qos_stop)
                                Finch.resize_if_smaller!(tmp_lvl_5_val_2, tmp_lvl_5_qos_stop)
                                Finch.fill_range!(tmp_lvl_5_val_2, false, tmp_lvl_5_qos, tmp_lvl_5_qos_stop)
                            end
                            tmp_lvl_5_val_2[tmp_lvl_5_qos] = ref_lvl_3_val
                            tmp_lvldirty = true
                            tmp_lvl_left_3[tmp_lvl_5_qos] = ref_lvl_2_i
                            tmp_lvl_right_3[tmp_lvl_5_qos] = ref_lvl_2_i
                            tmp_lvl_5_qos += 1
                            tmp_lvl_5_prev_pos = tmp_lvl_qos
                            ref_lvl_2_q += 1
                        else
                            phase_stop_5 = min(ref_lvl_2_i, phase_stop_3)
                            if ref_lvl_2_i == phase_stop_5
                                ref_lvl_3_val = ref_lvl_2_val[ref_lvl_2_q]
                                if tmp_lvl_5_qos > tmp_lvl_5_qos_stop
                                    tmp_lvl_5_qos_stop = max(tmp_lvl_5_qos_stop << 1, 1)
                                    Finch.resize_if_smaller!(tmp_lvl_left_3, tmp_lvl_5_qos_stop)
                                    Finch.resize_if_smaller!(tmp_lvl_right_3, tmp_lvl_5_qos_stop)
                                    Finch.resize_if_smaller!(tmp_lvl_5_val_2, tmp_lvl_5_qos_stop)
                                    Finch.fill_range!(tmp_lvl_5_val_2, false, tmp_lvl_5_qos, tmp_lvl_5_qos_stop)
                                end
                                tmp_lvl_5_val_2[tmp_lvl_5_qos] = ref_lvl_3_val
                                tmp_lvldirty = true
                                tmp_lvl_left_3[tmp_lvl_5_qos] = phase_stop_5
                                tmp_lvl_right_3[tmp_lvl_5_qos] = phase_stop_5
                                tmp_lvl_5_qos += 1
                                tmp_lvl_5_prev_pos = tmp_lvl_qos
                                ref_lvl_2_q += 1
                            end
                            break
                        end
                    end
                end
                tmp_lvl_ptr_3[tmp_lvl_qos + 1] += (tmp_lvl_5_qos - tmp_lvl_5_qos_fill) - 1
                tmp_lvl_5_qos_fill = tmp_lvl_5_qos - 1
                if tmp_lvldirty
                    tmp_lvl_left[tmp_lvl_qos] = ref_lvl_i
                    tmp_lvl_right[tmp_lvl_qos] = ref_lvl_i
                    tmp_lvl_qos += 1
                end
                ref_lvl_q += 1
            else
                phase_stop_7 = min(ref_lvl_i, phase_stop)
                if ref_lvl_i == phase_stop_7
                    if tmp_lvl_qos > tmp_lvl_qos_stop
                        tmp_lvl_qos_stop = max(tmp_lvl_qos_stop << 1, 1)
                        Finch.resize_if_smaller!(tmp_lvl_left, tmp_lvl_qos_stop)
                        Finch.resize_if_smaller!(tmp_lvl_right, tmp_lvl_qos_stop)
                        Finch.resize_if_smaller!(tmp_lvl_ptr_3, tmp_lvl_qos_stop + 1)
                        Finch.fill_range!(tmp_lvl_ptr_3, 0, tmp_lvl_qos + 1, tmp_lvl_qos_stop + 1)
                    end
                    tmp_lvldirty = false
                    tmp_lvl_5_qos_2 = tmp_lvl_5_qos_fill + 1
                    tmp_lvl_5_prev_pos < tmp_lvl_qos || throw(FinchProtocolError("SparseRLELevels cannot be updated multiple times"))
                    ref_lvl_2_q = ref_lvl_ptr_2[ref_lvl_q]
                    ref_lvl_2_q_stop = ref_lvl_ptr_2[ref_lvl_q + 1]
                    if ref_lvl_2_q < ref_lvl_2_q_stop
                        ref_lvl_2_i1 = ref_lvl_idx_2[ref_lvl_2_q_stop - 1]
                    else
                        ref_lvl_2_i1 = 0
                    end
                    phase_stop_8 = min(ref_lvl_2_i1, ref_lvl_2.shape)
                    if phase_stop_8 >= 1
                        if ref_lvl_idx_2[ref_lvl_2_q] < 1
                            ref_lvl_2_q = Finch.scansearch(ref_lvl_idx_2, 1, ref_lvl_2_q, ref_lvl_2_q_stop - 1)
                        end
                        while true
                            ref_lvl_2_i = ref_lvl_idx_2[ref_lvl_2_q]
                            if ref_lvl_2_i < phase_stop_8
                                ref_lvl_3_val_2 = ref_lvl_2_val[ref_lvl_2_q]
                                if tmp_lvl_5_qos_2 > tmp_lvl_5_qos_stop
                                    tmp_lvl_5_qos_stop = max(tmp_lvl_5_qos_stop << 1, 1)
                                    Finch.resize_if_smaller!(tmp_lvl_left_3, tmp_lvl_5_qos_stop)
                                    Finch.resize_if_smaller!(tmp_lvl_right_3, tmp_lvl_5_qos_stop)
                                    Finch.resize_if_smaller!(tmp_lvl_5_val_2, tmp_lvl_5_qos_stop)
                                    Finch.fill_range!(tmp_lvl_5_val_2, false, tmp_lvl_5_qos_2, tmp_lvl_5_qos_stop)
                                end
                                tmp_lvl_5_val_2[tmp_lvl_5_qos_2] = ref_lvl_3_val_2
                                tmp_lvldirty = true
                                tmp_lvl_left_3[tmp_lvl_5_qos_2] = ref_lvl_2_i
                                tmp_lvl_right_3[tmp_lvl_5_qos_2] = ref_lvl_2_i
                                tmp_lvl_5_qos_2 += 1
                                tmp_lvl_5_prev_pos = tmp_lvl_qos
                                ref_lvl_2_q += 1
                            else
                                phase_stop_10 = min(ref_lvl_2_i, phase_stop_8)
                                if ref_lvl_2_i == phase_stop_10
                                    ref_lvl_3_val_2 = ref_lvl_2_val[ref_lvl_2_q]
                                    if tmp_lvl_5_qos_2 > tmp_lvl_5_qos_stop
                                        tmp_lvl_5_qos_stop = max(tmp_lvl_5_qos_stop << 1, 1)
                                        Finch.resize_if_smaller!(tmp_lvl_left_3, tmp_lvl_5_qos_stop)
                                        Finch.resize_if_smaller!(tmp_lvl_right_3, tmp_lvl_5_qos_stop)
                                        Finch.resize_if_smaller!(tmp_lvl_5_val_2, tmp_lvl_5_qos_stop)
                                        Finch.fill_range!(tmp_lvl_5_val_2, false, tmp_lvl_5_qos_2, tmp_lvl_5_qos_stop)
                                    end
                                    tmp_lvl_5_val_2[tmp_lvl_5_qos_2] = ref_lvl_3_val_2
                                    tmp_lvldirty = true
                                    tmp_lvl_left_3[tmp_lvl_5_qos_2] = phase_stop_10
                                    tmp_lvl_right_3[tmp_lvl_5_qos_2] = phase_stop_10
                                    tmp_lvl_5_qos_2 += 1
                                    tmp_lvl_5_prev_pos = tmp_lvl_qos
                                    ref_lvl_2_q += 1
                                end
                                break
                            end
                        end
                    end
                    tmp_lvl_ptr_3[tmp_lvl_qos + 1] += (tmp_lvl_5_qos_2 - tmp_lvl_5_qos_fill) - 1
                    tmp_lvl_5_qos_fill = tmp_lvl_5_qos_2 - 1
                    if tmp_lvldirty
                        tmp_lvl_left[tmp_lvl_qos] = phase_stop_7
                        tmp_lvl_right[tmp_lvl_qos] = phase_stop_7
                        tmp_lvl_qos += 1
                    end
                    ref_lvl_q += 1
                end
                break
            end
        end
    end
    tmp_lvl_ptr[1 + 1] += (tmp_lvl_qos - 0) - 1
    resize!(tmp_lvl_ptr, 1 + 1)
    for p = 1:1
        tmp_lvl_ptr[p + 1] += tmp_lvl_ptr[p]
    end
    qos_stop = tmp_lvl_ptr[1 + 1] - 1
    resize!(tmp_lvl_ptr_3, qos_stop + 1)
    for p_2 = 1:qos_stop
        tmp_lvl_ptr_3[p_2 + 1] += tmp_lvl_ptr_3[p_2]
    end
    qos_stop_2 = tmp_lvl_ptr_3[qos_stop + 1] - 1
    resize!(tmp_lvl_5_val_2, qos_stop_2)
    Finch.resize_if_smaller!(tmp_lvl_5_val, qos_stop_2)
    Finch.fill_range!(tmp_lvl_5_val, false, 1, qos_stop_2)
    q = 1
    q_2 = 1
    for p_3 = 1:qos_stop
        q_stop = tmp_lvl_ptr_3[p_3 + 1]
        while q < q_stop
            q_head = q
            while q + 1 < q_stop && tmp_lvl_right_3[q] == tmp_lvl_left_3[q + 1] - 1
                tmp_lvl_7_val = tmp_lvl_5_val_2[q_head]
                tmp_lvl_7_val_2 = tmp_lvl_5_val_2[1 + q]
                check = isequal(tmp_lvl_7_val, tmp_lvl_7_val_2) && true
                if !check
                    break
                else
                    q += 1
                end
            end
            tmp_lvl_left_3[q_2] = tmp_lvl_left_3[q_head]
            tmp_lvl_right_3[q_2] = tmp_lvl_right_3[q]
            tmp_lvl_7_val_3 = tmp_lvl_5_val_2[q_head]
            tmp_lvl_5_val[q_2] = tmp_lvl_7_val_3
            q_2 += 1
            q += 1
        end
        tmp_lvl_ptr_3[p_3 + 1] = q_2
    end
    resize!(tmp_lvl_left_3, q_2 - 1)
    resize!(tmp_lvl_right_3, q_2 - 1)
    qos_stop_2 = q_2 - 1
    resize!(tmp_lvl_5_val, qos_stop_2)
    resize!(tmp_lvl_5_val_2, 0)
    tmp_lvl_2_qos_fill = 0
    tmp_lvl_2_qos_stop = 0
    tmp_lvl_2_prev_pos = 0
    Finch.resize_if_smaller!(tmp_lvl_ptr_2, qos_stop + 1)
    Finch.fill_range!(tmp_lvl_ptr_2, 0, 1 + 1, qos_stop + 1)
    q_3 = 1
    q_4 = 1
    for p_4 = 1:1
        q_stop_2 = tmp_lvl_ptr[p_4 + 1]
        while q_3 < q_stop_2
            q_head_2 = q_3
            while q_3 + 1 < q_stop_2 && tmp_lvl_right[q_3] == tmp_lvl_left[q_3 + 1] - 1
                check_2 = true
                tmp_lvl_5_q = tmp_lvl_ptr_3[q_head_2]
                tmp_lvl_5_q_stop = tmp_lvl_ptr_3[q_head_2 + 1]
                if tmp_lvl_5_q < tmp_lvl_5_q_stop
                    tmp_lvl_5_i_end = tmp_lvl_right_3[tmp_lvl_5_q_stop - 1]
                else
                    tmp_lvl_5_i_end = 0
                end
                tmp_lvl_5_q_2 = tmp_lvl_ptr_3[1 + q_3]
                tmp_lvl_5_q_stop_2 = tmp_lvl_ptr_3[(1 + q_3) + 1]
                if tmp_lvl_5_q_2 < tmp_lvl_5_q_stop_2
                    tmp_lvl_5_i_end_2 = tmp_lvl_right_3[tmp_lvl_5_q_stop_2 - 1]
                else
                    tmp_lvl_5_i_end_2 = 0
                end
                phase_stop_13 = min(ref_lvl_2.shape, tmp_lvl_5_i_end, tmp_lvl_5_i_end_2)
                if phase_stop_13 >= 1
                    i1 = 1
                    if tmp_lvl_right_3[tmp_lvl_5_q] < 1
                        tmp_lvl_5_q = Finch.scansearch(tmp_lvl_right_3, 1, tmp_lvl_5_q, tmp_lvl_5_q_stop - 1)
                    end
                    if tmp_lvl_right_3[tmp_lvl_5_q_2] < 1
                        tmp_lvl_5_q_2 = Finch.scansearch(tmp_lvl_right_3, 1, tmp_lvl_5_q_2, tmp_lvl_5_q_stop_2 - 1)
                    end
                    while i1 <= phase_stop_13
                        tmp_lvl_5_i_start = tmp_lvl_left_3[tmp_lvl_5_q]
                        tmp_lvl_5_i_stop = tmp_lvl_right_3[tmp_lvl_5_q]
                        tmp_lvl_5_i_start_2 = tmp_lvl_left_3[tmp_lvl_5_q_2]
                        tmp_lvl_5_i_stop_2 = tmp_lvl_right_3[tmp_lvl_5_q_2]
                        phase_start_11 = i1
                        phase_stop_14 = min(tmp_lvl_5_i_stop_2, phase_stop_13, tmp_lvl_5_i_stop)
                        phase_start_13 = max(phase_start_11, tmp_lvl_5_i_start)
                        phase_stop_16 = min(phase_stop_14, -1 + tmp_lvl_5_i_start_2)
                        if phase_stop_16 >= phase_start_13
                            tmp_lvl_6_val = tmp_lvl_5_val[tmp_lvl_5_q]
                            for i1_6 = phase_start_13:phase_stop_16
                                check_2 = isequal(tmp_lvl_6_val, false) && check_2
                            end
                        end
                        phase_start_14 = max(phase_start_11, tmp_lvl_5_i_start_2)
                        phase_stop_17 = min(phase_stop_14, -1 + tmp_lvl_5_i_start)
                        if phase_stop_17 >= phase_start_14
                            tmp_lvl_6_val_2 = tmp_lvl_5_val[tmp_lvl_5_q_2]
                            for i1_8 = phase_start_14:phase_stop_17
                                check_2 = check_2 && isequal(false, tmp_lvl_6_val_2)
                            end
                        end
                        phase_start_15 = max(phase_start_11, tmp_lvl_5_i_start, tmp_lvl_5_i_start_2)
                        if phase_stop_14 >= phase_start_15
                            tmp_lvl_6_val_3 = tmp_lvl_5_val[tmp_lvl_5_q]
                            tmp_lvl_6_val_4 = tmp_lvl_5_val[tmp_lvl_5_q_2]
                            for i1_10 = phase_start_15:phase_stop_14
                                check_2 = check_2 && isequal(tmp_lvl_6_val_3, tmp_lvl_6_val_4)
                            end
                        end
                        tmp_lvl_5_q += phase_stop_14 == tmp_lvl_5_i_stop
                        tmp_lvl_5_q_2 += phase_stop_14 == tmp_lvl_5_i_stop_2
                        i1 = phase_stop_14 + 1
                    end
                end
                phase_start_16 = max(1, 1 + tmp_lvl_5_i_end)
                phase_stop_19 = min(ref_lvl_2.shape, tmp_lvl_5_i_end_2)
                if phase_stop_19 >= phase_start_16
                    i1 = phase_start_16
                    if tmp_lvl_right_3[tmp_lvl_5_q_2] < phase_start_16
                        tmp_lvl_5_q_2 = Finch.scansearch(tmp_lvl_right_3, phase_start_16, tmp_lvl_5_q_2, tmp_lvl_5_q_stop_2 - 1)
                    end
                    while true
                        i1_start_4 = i1
                        tmp_lvl_5_i_start_2 = tmp_lvl_left_3[tmp_lvl_5_q_2]
                        tmp_lvl_5_i_stop_2 = tmp_lvl_right_3[tmp_lvl_5_q_2]
                        if tmp_lvl_5_i_stop_2 < phase_stop_19
                            phase_start_18 = max(tmp_lvl_5_i_start_2, i1_start_4)
                            if tmp_lvl_5_i_stop_2 >= phase_start_18
                                tmp_lvl_6_val_5 = tmp_lvl_5_val[tmp_lvl_5_q_2]
                                for i1_15 = phase_start_18:tmp_lvl_5_i_stop_2
                                    check_2 = check_2 && isequal(false, tmp_lvl_6_val_5)
                                end
                            end
                            tmp_lvl_5_q_2 += tmp_lvl_5_i_stop_2 == tmp_lvl_5_i_stop_2
                            i1 = tmp_lvl_5_i_stop_2 + 1
                        else
                            phase_start_19 = i1
                            phase_stop_23 = min(tmp_lvl_5_i_stop_2, phase_stop_19)
                            phase_start_21 = max(tmp_lvl_5_i_start_2, phase_start_19)
                            if phase_stop_23 >= phase_start_21
                                tmp_lvl_6_val_6 = tmp_lvl_5_val[tmp_lvl_5_q_2]
                                for i1_18 = phase_start_21:phase_stop_23
                                    check_2 = check_2 && isequal(false, tmp_lvl_6_val_6)
                                end
                            end
                            tmp_lvl_5_q_2 += phase_stop_23 == tmp_lvl_5_i_stop_2
                            i1 = phase_stop_23 + 1
                            break
                        end
                    end
                end
                phase_start_22 = max(1, 1 + tmp_lvl_5_i_end_2)
                phase_stop_26 = min(ref_lvl_2.shape, tmp_lvl_5_i_end)
                if phase_stop_26 >= phase_start_22
                    i1 = phase_start_22
                    if tmp_lvl_right_3[tmp_lvl_5_q] < phase_start_22
                        tmp_lvl_5_q = Finch.scansearch(tmp_lvl_right_3, phase_start_22, tmp_lvl_5_q, tmp_lvl_5_q_stop - 1)
                    end
                    while true
                        i1_start_7 = i1
                        tmp_lvl_5_i_start = tmp_lvl_left_3[tmp_lvl_5_q]
                        tmp_lvl_5_i_stop = tmp_lvl_right_3[tmp_lvl_5_q]
                        if tmp_lvl_5_i_stop < phase_stop_26
                            phase_start_24 = max(tmp_lvl_5_i_start, i1_start_7)
                            if tmp_lvl_5_i_stop >= phase_start_24
                                tmp_lvl_6_val_7 = tmp_lvl_5_val[tmp_lvl_5_q]
                                for i1_23 = phase_start_24:tmp_lvl_5_i_stop
                                    check_2 = check_2 && isequal(tmp_lvl_6_val_7, false)
                                end
                            end
                            tmp_lvl_5_q += tmp_lvl_5_i_stop == tmp_lvl_5_i_stop
                            i1 = tmp_lvl_5_i_stop + 1
                        else
                            phase_start_25 = i1
                            phase_stop_30 = min(tmp_lvl_5_i_stop, phase_stop_26)
                            phase_start_27 = max(tmp_lvl_5_i_start, phase_start_25)
                            if phase_stop_30 >= phase_start_27
                                tmp_lvl_6_val_8 = tmp_lvl_5_val[tmp_lvl_5_q]
                                for i1_26 = phase_start_27:phase_stop_30
                                    check_2 = check_2 && isequal(tmp_lvl_6_val_8, false)
                                end
                            end
                            tmp_lvl_5_q += phase_stop_30 == tmp_lvl_5_i_stop
                            i1 = phase_stop_30 + 1
                            break
                        end
                    end
                end
                if !check_2
                    break
                else
                    q_3 += 1
                end
            end
            tmp_lvl_left[q_4] = tmp_lvl_left[q_head_2]
            tmp_lvl_right[q_4] = tmp_lvl_right[q_3]
            tmp_lvl_2_qos = tmp_lvl_2_qos_fill + 1
            tmp_lvl_2_prev_pos < q_4 || throw(FinchProtocolError("SparseRLELevels cannot be updated multiple times"))
            tmp_lvl_5_q_3 = tmp_lvl_ptr_3[q_head_2]
            tmp_lvl_5_q_stop_3 = tmp_lvl_ptr_3[q_head_2 + 1]
            if tmp_lvl_5_q_3 < tmp_lvl_5_q_stop_3
                tmp_lvl_5_i_end_3 = tmp_lvl_right_3[tmp_lvl_5_q_stop_3 - 1]
            else
                tmp_lvl_5_i_end_3 = 0
            end
            phase_stop_34 = min(ref_lvl_2.shape, tmp_lvl_5_i_end_3)
            if phase_stop_34 >= 1
                i1_28 = 1
                if tmp_lvl_right_3[tmp_lvl_5_q_3] < 1
                    tmp_lvl_5_q_3 = Finch.scansearch(tmp_lvl_right_3, 1, tmp_lvl_5_q_3, tmp_lvl_5_q_stop_3 - 1)
                end
                while true
                    i1_28_start_2 = i1_28
                    tmp_lvl_5_i_start_3 = tmp_lvl_left_3[tmp_lvl_5_q_3]
                    tmp_lvl_5_i_stop_3 = tmp_lvl_right_3[tmp_lvl_5_q_3]
                    if tmp_lvl_5_i_stop_3 < phase_stop_34
                        phase_start_31 = max(i1_28_start_2, tmp_lvl_5_i_start_3)
                        if tmp_lvl_5_i_stop_3 >= phase_start_31
                            tmp_lvl_6_val_9 = tmp_lvl_5_val[tmp_lvl_5_q_3]
                            if tmp_lvl_2_qos > tmp_lvl_2_qos_stop
                                tmp_lvl_2_qos_stop = max(tmp_lvl_2_qos_stop << 1, 1)
                                Finch.resize_if_smaller!(tmp_lvl_left_2, tmp_lvl_2_qos_stop)
                                Finch.resize_if_smaller!(tmp_lvl_right_2, tmp_lvl_2_qos_stop)
                                Finch.resize_if_smaller!(tmp_lvl_2_val_2, tmp_lvl_2_qos_stop)
                                Finch.fill_range!(tmp_lvl_2_val_2, false, tmp_lvl_2_qos, tmp_lvl_2_qos_stop)
                            end
                            tmp_lvl_2_val_2[tmp_lvl_2_qos] = tmp_lvl_6_val_9
                            tmp_lvl_left_2[tmp_lvl_2_qos] = phase_start_31
                            tmp_lvl_right_2[tmp_lvl_2_qos] = tmp_lvl_5_i_stop_3
                            tmp_lvl_2_qos += 1
                            tmp_lvl_2_prev_pos = q_4
                        end
                        tmp_lvl_5_q_3 += tmp_lvl_5_i_stop_3 == tmp_lvl_5_i_stop_3
                        i1_28 = tmp_lvl_5_i_stop_3 + 1
                    else
                        phase_start_32 = i1_28
                        phase_stop_38 = min(tmp_lvl_5_i_stop_3, phase_stop_34)
                        phase_start_34 = max(tmp_lvl_5_i_start_3, phase_start_32)
                        if phase_stop_38 >= phase_start_34
                            tmp_lvl_6_val_10 = tmp_lvl_5_val[tmp_lvl_5_q_3]
                            if tmp_lvl_2_qos > tmp_lvl_2_qos_stop
                                tmp_lvl_2_qos_stop = max(tmp_lvl_2_qos_stop << 1, 1)
                                Finch.resize_if_smaller!(tmp_lvl_left_2, tmp_lvl_2_qos_stop)
                                Finch.resize_if_smaller!(tmp_lvl_right_2, tmp_lvl_2_qos_stop)
                                Finch.resize_if_smaller!(tmp_lvl_2_val_2, tmp_lvl_2_qos_stop)
                                Finch.fill_range!(tmp_lvl_2_val_2, false, tmp_lvl_2_qos, tmp_lvl_2_qos_stop)
                            end
                            tmp_lvl_2_val_2[tmp_lvl_2_qos] = tmp_lvl_6_val_10
                            tmp_lvl_left_2[tmp_lvl_2_qos] = phase_start_34
                            tmp_lvl_right_2[tmp_lvl_2_qos] = phase_stop_38
                            tmp_lvl_2_qos += 1
                            tmp_lvl_2_prev_pos = q_4
                        end
                        tmp_lvl_5_q_3 += phase_stop_38 == tmp_lvl_5_i_stop_3
                        i1_28 = phase_stop_38 + 1
                        break
                    end
                end
            end
            tmp_lvl_ptr_2[q_4 + 1] += (tmp_lvl_2_qos - tmp_lvl_2_qos_fill) - 1
            tmp_lvl_2_qos_fill = tmp_lvl_2_qos - 1
            q_4 += 1
            q_3 += 1
        end
        tmp_lvl_ptr[p_4 + 1] = q_4
    end
    resize!(tmp_lvl_left, q_4 - 1)
    resize!(tmp_lvl_right, q_4 - 1)
    qos_stop = q_4 - 1
    resize!(tmp_lvl_ptr_2, qos_stop + 1)
    for p_5 = 1:qos_stop
        tmp_lvl_ptr_2[p_5 + 1] += tmp_lvl_ptr_2[p_5]
    end
    qos_stop_3 = tmp_lvl_ptr_2[qos_stop + 1] - 1
    resize!(tmp_lvl_2_val_2, qos_stop_3)
    Finch.resize_if_smaller!(tmp_lvl_2_val, qos_stop_3)
    Finch.fill_range!(tmp_lvl_2_val, false, 1, qos_stop_3)
    q_5 = 1
    q_6 = 1
    for p_6 = 1:qos_stop
        q_stop_3 = tmp_lvl_ptr_2[p_6 + 1]
        while q_5 < q_stop_3
            q_head_3 = q_5
            while q_5 + 1 < q_stop_3 && tmp_lvl_right_2[q_5] == tmp_lvl_left_2[q_5 + 1] - 1
                tmp_lvl_4_val = tmp_lvl_2_val_2[q_head_3]
                tmp_lvl_4_val_2 = tmp_lvl_2_val_2[1 + q_5]
                check_3 = isequal(tmp_lvl_4_val, tmp_lvl_4_val_2) && true
                if !check_3
                    break
                else
                    q_5 += 1
                end
            end
            tmp_lvl_left_2[q_6] = tmp_lvl_left_2[q_head_3]
            tmp_lvl_right_2[q_6] = tmp_lvl_right_2[q_5]
            tmp_lvl_4_val_3 = tmp_lvl_2_val_2[q_head_3]
            tmp_lvl_2_val[q_6] = tmp_lvl_4_val_3
            q_6 += 1
            q_5 += 1
        end
        tmp_lvl_ptr_2[p_6 + 1] = q_6
    end
    resize!(tmp_lvl_left_2, q_6 - 1)
    resize!(tmp_lvl_right_2, q_6 - 1)
    qos_stop_3 = q_6 - 1
    resize!(tmp_lvl_2_val, qos_stop_3)
    resize!(tmp_lvl_2_val_2, 0)
    resize!(tmp_lvl_ptr_3, 0 + 1)
    for p_7 = 1:0
        tmp_lvl_ptr_3[p_7 + 1] += tmp_lvl_ptr_3[p_7]
    end
    qos_stop_4 = tmp_lvl_ptr_3[0 + 1] - 1
    resize!(tmp_lvl_5_val_2, qos_stop_4)
    Finch.resize_if_smaller!(tmp_lvl_5_val, qos_stop_4)
    Finch.fill_range!(tmp_lvl_5_val, false, 1, qos_stop_4)
    q_7 = 1
    q_8 = 1
    for p_8 = 1:0
        q_stop_4 = tmp_lvl_ptr_3[p_8 + 1]
        while q_7 < q_stop_4
            q_head_4 = q_7
            while q_7 + 1 < q_stop_4 && tmp_lvl_right_3[q_7] == tmp_lvl_left_3[q_7 + 1] - 1
                tmp_lvl_7_val_4 = tmp_lvl_5_val_2[q_head_4]
                tmp_lvl_7_val_5 = tmp_lvl_5_val_2[1 + q_7]
                check_4 = isequal(tmp_lvl_7_val_4, tmp_lvl_7_val_5) && true
                if !check_4
                    break
                else
                    q_7 += 1
                end
            end
            tmp_lvl_left_3[q_8] = tmp_lvl_left_3[q_head_4]
            tmp_lvl_right_3[q_8] = tmp_lvl_right_3[q_7]
            tmp_lvl_7_val_6 = tmp_lvl_5_val_2[q_head_4]
            tmp_lvl_5_val[q_8] = tmp_lvl_7_val_6
            q_8 += 1
            q_7 += 1
        end
        tmp_lvl_ptr_3[p_8 + 1] = q_8
    end
    resize!(tmp_lvl_left_3, q_8 - 1)
    resize!(tmp_lvl_right_3, q_8 - 1)
    qos_stop_4 = q_8 - 1
    resize!(tmp_lvl_5_val, qos_stop_4)
    resize!(tmp_lvl_5_val_2, 0)
    result = (tmp = Tensor((SparseRLELevel){Int32}((SparseRLELevel){Int32}(tmp_lvl_3, ref_lvl_2.shape, tmp_lvl_ptr_2, tmp_lvl_left_2, tmp_lvl_right_2, tmp_lvl_4), ref_lvl.shape, tmp_lvl_ptr, tmp_lvl_left, tmp_lvl_right, (SparseRLELevel){Int32}(tmp_lvl_6, ref_lvl_2.shape, tmp_lvl_ptr_3, tmp_lvl_left_3, tmp_lvl_right_3, tmp_lvl_7))),)
    result
end
