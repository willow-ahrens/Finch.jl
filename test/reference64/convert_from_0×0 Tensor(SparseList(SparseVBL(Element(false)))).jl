begin
    res_lvl = ((ex.bodies[1]).bodies[1]).tns.bind.lvl
    res_lvl_ptr = res_lvl.ptr
    res_lvl_idx = res_lvl.idx
    res_lvl_2 = res_lvl.lvl
    res_lvl_ptr_2 = res_lvl_2.ptr
    res_lvl_idx_2 = res_lvl_2.idx
    res_lvl_3 = res_lvl_2.lvl
    res_lvl_2_val = res_lvl_2.lvl.val
    tmp_lvl = ((ex.bodies[1]).bodies[2]).body.body.rhs.tns.bind.lvl
    tmp_lvl_ptr = tmp_lvl.ptr
    tmp_lvl_idx = tmp_lvl.idx
    tmp_lvl_2 = tmp_lvl.lvl
    tmp_lvl_ptr_2 = tmp_lvl_2.ptr
    tmp_lvl_idx_2 = tmp_lvl_2.idx
    tmp_lvl_ofs = tmp_lvl_2.ofs
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
        tmp_lvl_i1 = tmp_lvl_idx[tmp_lvl_q_stop - 1]
    else
        tmp_lvl_i1 = 0
    end
    phase_stop = min(tmp_lvl_i1, tmp_lvl.shape)
    if phase_stop >= 1
        if tmp_lvl_idx[tmp_lvl_q] < 1
            tmp_lvl_q = Finch.scansearch(tmp_lvl_idx, 1, tmp_lvl_q, tmp_lvl_q_stop - 1)
        end
        while true
            tmp_lvl_i = tmp_lvl_idx[tmp_lvl_q]
            if tmp_lvl_i < phase_stop
                if res_lvl_qos > res_lvl_qos_stop
                    res_lvl_qos_stop = max(res_lvl_qos_stop << 1, 1)
                    Finch.resize_if_smaller!(res_lvl_idx, res_lvl_qos_stop)
                    Finch.resize_if_smaller!(res_lvl_ptr_2, res_lvl_qos_stop + 1)
                    Finch.fill_range!(res_lvl_ptr_2, 0, res_lvl_qos + 1, res_lvl_qos_stop + 1)
                end
                res_lvldirty = false
                res_lvl_2_qos = res_lvl_2_qos_fill + 1
                res_lvl_2_prev_pos < res_lvl_qos || throw(FinchProtocolError("SparseListLevels cannot be updated multiple times"))
                tmp_lvl_2_r = tmp_lvl_ptr_2[tmp_lvl_q]
                tmp_lvl_2_r_stop = tmp_lvl_ptr_2[tmp_lvl_q + 1]
                if tmp_lvl_2_r < tmp_lvl_2_r_stop
                    tmp_lvl_2_i1 = tmp_lvl_idx_2[tmp_lvl_2_r_stop - 1]
                else
                    tmp_lvl_2_i1 = 0
                end
                phase_stop_3 = min(tmp_lvl_2_i1, tmp_lvl_2.shape)
                if phase_stop_3 >= 1
                    i = 1
                    if tmp_lvl_idx_2[tmp_lvl_2_r] < 1
                        tmp_lvl_2_r = Finch.scansearch(tmp_lvl_idx_2, 1, tmp_lvl_2_r, tmp_lvl_2_r_stop - 1)
                    end
                    while true
                        i_start_2 = i
                        tmp_lvl_2_i = tmp_lvl_idx_2[tmp_lvl_2_r]
                        tmp_lvl_2_q_stop = tmp_lvl_ofs[tmp_lvl_2_r + 1]
                        tmp_lvl_2_i_2 = tmp_lvl_2_i - (tmp_lvl_2_q_stop - tmp_lvl_ofs[tmp_lvl_2_r])
                        tmp_lvl_2_q_ofs = (tmp_lvl_2_q_stop - tmp_lvl_2_i) - 1
                        if tmp_lvl_2_i < phase_stop_3
                            phase_start_4 = max(i_start_2, 1 + tmp_lvl_2_i_2)
                            if tmp_lvl_2_i >= phase_start_4
                                for i_8 = phase_start_4:tmp_lvl_2_i
                                    if res_lvl_2_qos > res_lvl_2_qos_stop
                                        res_lvl_2_qos_stop = max(res_lvl_2_qos_stop << 1, 1)
                                        Finch.resize_if_smaller!(res_lvl_idx_2, res_lvl_2_qos_stop)
                                        Finch.resize_if_smaller!(res_lvl_2_val, res_lvl_2_qos_stop)
                                        Finch.fill_range!(res_lvl_2_val, false, res_lvl_2_qos, res_lvl_2_qos_stop)
                                    end
                                    tmp_lvl_2_q = tmp_lvl_2_q_ofs + i_8
                                    tmp_lvl_3_val = tmp_lvl_2_val[tmp_lvl_2_q]
                                    res = (res_lvl_2_val[res_lvl_2_qos] = tmp_lvl_3_val)
                                    res_lvldirty = true
                                    res_lvl_idx_2[res_lvl_2_qos] = i_8
                                    res_lvl_2_qos += 1
                                    res_lvl_2_prev_pos = res_lvl_qos
                                end
                            end
                            tmp_lvl_2_r += tmp_lvl_2_i == tmp_lvl_2_i
                            i = tmp_lvl_2_i + 1
                        else
                            phase_start_5 = i
                            phase_stop_7 = min(tmp_lvl_2_i, phase_stop_3)
                            phase_start_7 = max(1 + tmp_lvl_2_i_2, phase_start_5)
                            if phase_stop_7 >= phase_start_7
                                for i_11 = phase_start_7:phase_stop_7
                                    if res_lvl_2_qos > res_lvl_2_qos_stop
                                        res_lvl_2_qos_stop = max(res_lvl_2_qos_stop << 1, 1)
                                        Finch.resize_if_smaller!(res_lvl_idx_2, res_lvl_2_qos_stop)
                                        Finch.resize_if_smaller!(res_lvl_2_val, res_lvl_2_qos_stop)
                                        Finch.fill_range!(res_lvl_2_val, false, res_lvl_2_qos, res_lvl_2_qos_stop)
                                    end
                                    tmp_lvl_2_q = tmp_lvl_2_q_ofs + i_11
                                    tmp_lvl_3_val_2 = tmp_lvl_2_val[tmp_lvl_2_q]
                                    res_lvl_2_val[res_lvl_2_qos] = tmp_lvl_3_val_2
                                    res_lvldirty = true
                                    res_lvl_idx_2[res_lvl_2_qos] = i_11
                                    res_lvl_2_qos += 1
                                    res_lvl_2_prev_pos = res_lvl_qos
                                end
                            end
                            tmp_lvl_2_r += phase_stop_7 == tmp_lvl_2_i
                            i = phase_stop_7 + 1
                            break
                        end
                    end
                end
                res_lvl_ptr_2[res_lvl_qos + 1] += (res_lvl_2_qos - res_lvl_2_qos_fill) - 1
                res_lvl_2_qos_fill = res_lvl_2_qos - 1
                if res_lvldirty
                    res_lvl_idx[res_lvl_qos] = tmp_lvl_i
                    res_lvl_qos += 1
                end
                tmp_lvl_q += 1
            else
                phase_stop_11 = min(tmp_lvl_i, phase_stop)
                if tmp_lvl_i == phase_stop_11
                    if res_lvl_qos > res_lvl_qos_stop
                        res_lvl_qos_stop = max(res_lvl_qos_stop << 1, 1)
                        Finch.resize_if_smaller!(res_lvl_idx, res_lvl_qos_stop)
                        Finch.resize_if_smaller!(res_lvl_ptr_2, res_lvl_qos_stop + 1)
                        Finch.fill_range!(res_lvl_ptr_2, 0, res_lvl_qos + 1, res_lvl_qos_stop + 1)
                    end
                    res_lvldirty = false
                    res_lvl_2_qos_2 = res_lvl_2_qos_fill + 1
                    res_lvl_2_prev_pos < res_lvl_qos || throw(FinchProtocolError("SparseListLevels cannot be updated multiple times"))
                    tmp_lvl_2_r = tmp_lvl_ptr_2[tmp_lvl_q]
                    tmp_lvl_2_r_stop = tmp_lvl_ptr_2[tmp_lvl_q + 1]
                    if tmp_lvl_2_r < tmp_lvl_2_r_stop
                        tmp_lvl_2_i1 = tmp_lvl_idx_2[tmp_lvl_2_r_stop - 1]
                    else
                        tmp_lvl_2_i1 = 0
                    end
                    phase_stop_12 = min(tmp_lvl_2_i1, tmp_lvl_2.shape)
                    if phase_stop_12 >= 1
                        i = 1
                        if tmp_lvl_idx_2[tmp_lvl_2_r] < 1
                            tmp_lvl_2_r = Finch.scansearch(tmp_lvl_idx_2, 1, tmp_lvl_2_r, tmp_lvl_2_r_stop - 1)
                        end
                        while true
                            i_start_6 = i
                            tmp_lvl_2_i = tmp_lvl_idx_2[tmp_lvl_2_r]
                            tmp_lvl_2_q_stop = tmp_lvl_ofs[tmp_lvl_2_r + 1]
                            tmp_lvl_2_i_2 = tmp_lvl_2_i - (tmp_lvl_2_q_stop - tmp_lvl_ofs[tmp_lvl_2_r])
                            tmp_lvl_2_q_ofs = (tmp_lvl_2_q_stop - tmp_lvl_2_i) - 1
                            if tmp_lvl_2_i < phase_stop_12
                                phase_start_12 = max(1 + tmp_lvl_2_i_2, i_start_6)
                                if tmp_lvl_2_i >= phase_start_12
                                    for i_17 = phase_start_12:tmp_lvl_2_i
                                        if res_lvl_2_qos_2 > res_lvl_2_qos_stop
                                            res_lvl_2_qos_stop = max(res_lvl_2_qos_stop << 1, 1)
                                            Finch.resize_if_smaller!(res_lvl_idx_2, res_lvl_2_qos_stop)
                                            Finch.resize_if_smaller!(res_lvl_2_val, res_lvl_2_qos_stop)
                                            Finch.fill_range!(res_lvl_2_val, false, res_lvl_2_qos_2, res_lvl_2_qos_stop)
                                        end
                                        tmp_lvl_2_q = tmp_lvl_2_q_ofs + i_17
                                        tmp_lvl_3_val_3 = tmp_lvl_2_val[tmp_lvl_2_q]
                                        res_lvl_2_val[res_lvl_2_qos_2] = tmp_lvl_3_val_3
                                        res_lvldirty = true
                                        res_lvl_idx_2[res_lvl_2_qos_2] = i_17
                                        res_lvl_2_qos_2 += 1
                                        res_lvl_2_prev_pos = res_lvl_qos
                                    end
                                end
                                tmp_lvl_2_r += tmp_lvl_2_i == tmp_lvl_2_i
                                i = tmp_lvl_2_i + 1
                            else
                                phase_start_13 = i
                                phase_stop_16 = min(tmp_lvl_2_i, phase_stop_12)
                                phase_start_15 = max(1 + tmp_lvl_2_i_2, phase_start_13)
                                if phase_stop_16 >= phase_start_15
                                    for i_20 = phase_start_15:phase_stop_16
                                        if res_lvl_2_qos_2 > res_lvl_2_qos_stop
                                            res_lvl_2_qos_stop = max(res_lvl_2_qos_stop << 1, 1)
                                            Finch.resize_if_smaller!(res_lvl_idx_2, res_lvl_2_qos_stop)
                                            Finch.resize_if_smaller!(res_lvl_2_val, res_lvl_2_qos_stop)
                                            Finch.fill_range!(res_lvl_2_val, false, res_lvl_2_qos_2, res_lvl_2_qos_stop)
                                        end
                                        tmp_lvl_2_q = tmp_lvl_2_q_ofs + i_20
                                        tmp_lvl_3_val_4 = tmp_lvl_2_val[tmp_lvl_2_q]
                                        res_lvl_2_val[res_lvl_2_qos_2] = tmp_lvl_3_val_4
                                        res_lvldirty = true
                                        res_lvl_idx_2[res_lvl_2_qos_2] = i_20
                                        res_lvl_2_qos_2 += 1
                                        res_lvl_2_prev_pos = res_lvl_qos
                                    end
                                end
                                tmp_lvl_2_r += phase_stop_16 == tmp_lvl_2_i
                                i = phase_stop_16 + 1
                                break
                            end
                        end
                    end
                    res_lvl_ptr_2[res_lvl_qos + 1] += (res_lvl_2_qos_2 - res_lvl_2_qos_fill) - 1
                    res_lvl_2_qos_fill = res_lvl_2_qos_2 - 1
                    if res_lvldirty
                        res_lvl_idx[res_lvl_qos] = phase_stop_11
                        res_lvl_qos += 1
                    end
                    tmp_lvl_q += 1
                end
                break
            end
        end
    end
    res_lvl_ptr[1 + 1] += (res_lvl_qos - 0) - 1
    result = something(nothing, (res = Tensor((SparseListLevel){Int64}((SparseListLevel){Int64}(res_lvl_3, tmp_lvl_2.shape, res_lvl_ptr_2, res_lvl_idx_2), tmp_lvl.shape, res_lvl_ptr, res_lvl_idx)),))
    resize!(res_lvl_ptr, 1 + 1)
    for p = 1:1
        res_lvl_ptr[p + 1] += res_lvl_ptr[p]
    end
    qos_stop = res_lvl_ptr[1 + 1] - 1
    resize!(res_lvl_idx, qos_stop)
    resize!(res_lvl_ptr_2, qos_stop + 1)
    for p_2 = 1:qos_stop
        res_lvl_ptr_2[p_2 + 1] += res_lvl_ptr_2[p_2]
    end
    qos_stop_2 = res_lvl_ptr_2[qos_stop + 1] - 1
    resize!(res_lvl_idx_2, qos_stop_2)
    resize!(res_lvl_2_val, qos_stop_2)
    result
end
