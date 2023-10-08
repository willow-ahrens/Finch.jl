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
    tmp_lvl_val = tmp_lvl.lvl.val
    tmp_lvl_q = (1 - 1) * fld(tmp_lvl.shape * (1 + tmp_lvl.shape), 2) + 1
    res_lvl_qos_stop = 0
    res_lvl_2_qos_fill = 0
    res_lvl_2_qos_stop = 0
    res_lvl_2_prev_pos = 0
    Finch.resize_if_smaller!(res_lvl_ptr, 1 + 1)
    Finch.fill_range!(res_lvl_ptr, 0, 1 + 1, 1 + 1)
    res_lvl_qos = 0 + 1
    0 < 1 || throw(FinchProtocolError("SparseListLevels cannot be updated multiple times"))
    phase_stop = tmp_lvl.shape
    if phase_stop >= 1
        for j_5 = 1:phase_stop
            if res_lvl_qos > res_lvl_qos_stop
                res_lvl_qos_stop = max(res_lvl_qos_stop << 1, 1)
                Finch.resize_if_smaller!(res_lvl_idx, res_lvl_qos_stop)
                Finch.resize_if_smaller!(res_lvl_ptr_2, res_lvl_qos_stop + 1)
                Finch.fill_range!(res_lvl_ptr_2, 0, res_lvl_qos + 1, res_lvl_qos_stop + 1)
            end
            res_lvldirty = false
            tmp_lvl_s = tmp_lvl_q + fld(j_5 * (j_5 + -1), 2)
            res_lvl_2_qos = res_lvl_2_qos_fill + 1
            res_lvl_2_prev_pos < res_lvl_qos || throw(FinchProtocolError("SparseListLevels cannot be updated multiple times"))
            phase_stop_2 = min(tmp_lvl.shape, j_5)
            if phase_stop_2 >= 1
                for i_5 = 1:phase_stop_2
                    if res_lvl_2_qos > res_lvl_2_qos_stop
                        res_lvl_2_qos_stop = max(res_lvl_2_qos_stop << 1, 1)
                        Finch.resize_if_smaller!(res_lvl_idx_2, res_lvl_2_qos_stop)
                        Finch.resize_if_smaller!(res_lvl_2_val, res_lvl_2_qos_stop)
                        Finch.fill_range!(res_lvl_2_val, false, res_lvl_2_qos, res_lvl_2_qos_stop)
                    end
                    tmp_lvl_2_val = tmp_lvl_val[tmp_lvl_s + -1 + i_5]
                    res_lvl_2_val[res_lvl_2_qos] = tmp_lvl_2_val
                    res_lvldirty = true
                    res_lvl_idx_2[res_lvl_2_qos] = i_5
                    res_lvl_2_qos += 1
                    res_lvl_2_prev_pos = res_lvl_qos
                end
            end
            res_lvl_ptr_2[res_lvl_qos + 1] = (res_lvl_2_qos - res_lvl_2_qos_fill) - 1
            res_lvl_2_qos_fill = res_lvl_2_qos - 1
            if res_lvldirty
                res_lvl_idx[res_lvl_qos] = j_5
                res_lvl_qos += 1
            end
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
    (res = Fiber((SparseListLevel){Int64}((SparseListLevel){Int64}(res_lvl_3, tmp_lvl.shape, res_lvl_ptr_2, res_lvl_idx_2), tmp_lvl.shape, res_lvl_ptr, res_lvl_idx)),)
end
