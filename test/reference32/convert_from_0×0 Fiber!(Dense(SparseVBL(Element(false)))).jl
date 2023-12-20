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
    tmp_lvl_2 = tmp_lvl.lvl
    tmp_lvl_ptr = tmp_lvl_2.ptr
    tmp_lvl_idx = tmp_lvl_2.idx
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
    for j_4 = 1:tmp_lvl.shape
        if res_lvl_qos > res_lvl_qos_stop
            res_lvl_qos_stop = max(res_lvl_qos_stop << 1, 1)
            Finch.resize_if_smaller!(res_lvl_idx, res_lvl_qos_stop)
            Finch.resize_if_smaller!(res_lvl_ptr_2, res_lvl_qos_stop + 1)
            Finch.fill_range!(res_lvl_ptr_2, 0, res_lvl_qos + 1, res_lvl_qos_stop + 1)
        end
        res_lvldirty = false
        tmp_lvl_q = (1 - 1) * tmp_lvl.shape + j_4
        res_lvl_2_qos = res_lvl_2_qos_fill + 1
        res_lvl_2_prev_pos < res_lvl_qos || throw(FinchProtocolError("SparseListLevels cannot be updated multiple times"))
        tmp_lvl_2_r = tmp_lvl_ptr[tmp_lvl_q]
        tmp_lvl_2_r_stop = tmp_lvl_ptr[tmp_lvl_q + 1]
        if tmp_lvl_2_r < tmp_lvl_2_r_stop
            tmp_lvl_2_i1 = tmp_lvl_idx[tmp_lvl_2_r_stop - 1]
        else
            tmp_lvl_2_i1 = 0
        end
        phase_stop = min(tmp_lvl_2_i1, tmp_lvl_2.shape)
        if phase_stop >= 1
            i = 1
            if tmp_lvl_idx[tmp_lvl_2_r] < 1
                tmp_lvl_2_r = Finch.scansearch(tmp_lvl_idx, 1, tmp_lvl_2_r, tmp_lvl_2_r_stop - 1)
            end
            while true
                i_start_2 = i
                tmp_lvl_2_i = tmp_lvl_idx[tmp_lvl_2_r]
                tmp_lvl_2_q_stop = tmp_lvl_ofs[tmp_lvl_2_r + 1]
                tmp_lvl_2_i_2 = tmp_lvl_2_i - (tmp_lvl_2_q_stop - tmp_lvl_ofs[tmp_lvl_2_r])
                tmp_lvl_2_q_ofs = (tmp_lvl_2_q_stop - tmp_lvl_2_i) - 1
                if tmp_lvl_2_i < phase_stop
                    phase_start_3 = max(i_start_2, 1 + tmp_lvl_2_i_2)
                    if tmp_lvl_2_i >= phase_start_3
                        for i_8 = phase_start_3:tmp_lvl_2_i
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
                    phase_start_4 = i
                    phase_stop_5 = min(tmp_lvl_2_i, phase_stop)
                    phase_start_6 = max(1 + tmp_lvl_2_i_2, phase_start_4)
                    if phase_stop_5 >= phase_start_6
                        for i_11 = phase_start_6:phase_stop_5
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
                    tmp_lvl_2_r += phase_stop_5 == tmp_lvl_2_i
                    i = phase_stop_5 + 1
                    break
                end
            end
        end
        res_lvl_ptr_2[res_lvl_qos + 1] = (res_lvl_2_qos - res_lvl_2_qos_fill) - 1
        res_lvl_2_qos_fill = res_lvl_2_qos - 1
        if res_lvldirty
            res_lvl_idx[res_lvl_qos] = j_4
            res_lvl_qos += 1
        end
    end
    res_lvl_ptr[1 + 1] = (res_lvl_qos - 0) - 1
    for p = 2:1 + 1
        res_lvl_ptr[p] += res_lvl_ptr[p - 1]
    end
    qos_stop = res_lvl_ptr[1 + 1] - 1
    for p_2 = 2:qos_stop + 1
        res_lvl_ptr_2[p_2] += res_lvl_ptr_2[p_2 - 1]
    end
    resize!(res_lvl_ptr, 1 + 1)
    qos = res_lvl_ptr[end] - 1
    resize!(res_lvl_idx, qos)
    resize!(res_lvl_ptr_2, qos + 1)
    qos_2 = res_lvl_ptr_2[end] - 1
    resize!(res_lvl_idx_2, qos_2)
    resize!(res_lvl_2_val, qos_2)
    (res = Fiber((SparseListLevel){Int32}((SparseListLevel){Int32}(res_lvl_3, tmp_lvl_2.shape, res_lvl_ptr_2, res_lvl_idx_2), tmp_lvl.shape, res_lvl_ptr, res_lvl_idx)),)
end
