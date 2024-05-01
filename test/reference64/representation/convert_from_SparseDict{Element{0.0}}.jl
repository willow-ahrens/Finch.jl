quote
    res_lvl = ((ex.bodies[1]).bodies[1]).tns.bind.lvl
    res_lvl_ptr = res_lvl.ptr
    res_lvl_idx = res_lvl.idx
    res_lvl_2 = res_lvl.lvl
    res_lvl_val = res_lvl.lvl.val
    tmp_lvl = ((ex.bodies[1]).bodies[2]).body.rhs.tns.bind.lvl
    tmp_lvl_tbl = tmp_lvl.tbl
    tmp_lvl_val = tmp_lvl.lvl.val
    result = nothing
    res_lvl_qos_stop = 0
    Finch.resize_if_smaller!(res_lvl_ptr, 1 + 1)
    Finch.fill_range!(res_lvl_ptr, 0, 1 + 1, 1 + 1)
    res_lvl_qos = 0 + 1
    0 < 1 || throw(FinchProtocolError("SparseListLevels cannot be updated multiple times"))
    tmp_lvl_subtbl = table_query(tmp_lvl_tbl, 1)
    sugar_1 = subtable_init(tmp_lvl_tbl, tmp_lvl_subtbl)
    tmp_lvl_i = sugar_1[1]
    tmp_lvl_i1 = sugar_1[2]
    tmp_lvl_state = sugar_1[3]
    phase_stop = min(tmp_lvl_i1, tmp_lvl.shape)
    if phase_stop >= 1
        if tmp_lvl_i < 1
            sugar_2 = subtable_seek(tmp_lvl_tbl, tmp_lvl_subtbl, tmp_lvl_state, tmp_lvl_i, 1)
            tmp_lvl_state = sugar_2[2]
        end
        while true
            sugar_3 = subtable_get(tmp_lvl_tbl, tmp_lvl_subtbl, tmp_lvl_state)
            tmp_lvl_i = sugar_3[1]
            tmp_lvl_q = sugar_3[2]
            if tmp_lvl_i < phase_stop
                tmp_lvl_2_val = tmp_lvl_val[tmp_lvl_q]
                if res_lvl_qos > res_lvl_qos_stop
                    res_lvl_qos_stop = max(res_lvl_qos_stop << 1, 1)
                    Finch.resize_if_smaller!(res_lvl_idx, res_lvl_qos_stop)
                    Finch.resize_if_smaller!(res_lvl_val, res_lvl_qos_stop)
                    Finch.fill_range!(res_lvl_val, 0.0, res_lvl_qos, res_lvl_qos_stop)
                end
                res = (res_lvl_val[res_lvl_qos] = tmp_lvl_2_val)
                res_lvl_idx[res_lvl_qos] = tmp_lvl_i
                res_lvl_qos += 1
                tmp_lvl_state = subtable_next(tmp_lvl_tbl, tmp_lvl_subtbl, tmp_lvl_state)
            else
                phase_stop_3 = min(tmp_lvl_i, phase_stop)
                if tmp_lvl_i == phase_stop_3
                    tmp_lvl_2_val = tmp_lvl_val[tmp_lvl_q]
                    if res_lvl_qos > res_lvl_qos_stop
                        res_lvl_qos_stop = max(res_lvl_qos_stop << 1, 1)
                        Finch.resize_if_smaller!(res_lvl_idx, res_lvl_qos_stop)
                        Finch.resize_if_smaller!(res_lvl_val, res_lvl_qos_stop)
                        Finch.fill_range!(res_lvl_val, 0.0, res_lvl_qos, res_lvl_qos_stop)
                    end
                    res_lvl_val[res_lvl_qos] = tmp_lvl_2_val
                    res_lvl_idx[res_lvl_qos] = phase_stop_3
                    res_lvl_qos += 1
                    tmp_lvl_state = subtable_next(tmp_lvl_tbl, tmp_lvl_subtbl, tmp_lvl_state)
                end
                break
            end
        end
    end
    res_lvl_ptr[1 + 1] += (res_lvl_qos - 0) - 1
    resize!(res_lvl_ptr, 1 + 1)
    for p = 1:1
        res_lvl_ptr[p + 1] += res_lvl_ptr[p]
    end
    qos_stop = res_lvl_ptr[1 + 1] - 1
    resize!(res_lvl_idx, qos_stop)
    resize!(res_lvl_val, qos_stop)
    result = (res = Tensor((SparseListLevel){Int64}(res_lvl_2, tmp_lvl.shape, res_lvl_ptr, res_lvl_idx)),)
    result
end
