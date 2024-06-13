quote
    tmp_lvl = ((ex.bodies[1]).bodies[1]).tns.bind.lvl
    tmp_lvl_ptr = tmp_lvl.ptr
    tmp_lvl_idx = tmp_lvl.idx
    tmp_lvl_val = tmp_lvl.val
    tmp_lvl_tbl = tmp_lvl.tbl
    tmp_lvl_2 = tmp_lvl.lvl
    tmp_lvl_val_2 = tmp_lvl.lvl.val
    ref_lvl = ((ex.bodies[1]).bodies[2]).body.rhs.tns.bind.lvl
    ref_lvl_ptr = ref_lvl.ptr
    ref_lvl_idx = ref_lvl.idx
    ref_lvl_val = ref_lvl.lvl.val
    resize!(tmp_lvl_ptr, 1 + 1)
    Finch.fill_range!(tmp_lvl_ptr, 0, 1 + 1, 1 + 1)
    empty!(tmp_lvl_tbl)
    tmp_lvl_qos_stop = 0
    Finch.resize_if_smaller!(tmp_lvl_ptr, 1 + 1)
    Finch.fill_range!(tmp_lvl_ptr, 0, 1 + 1, 1 + 1)
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
                ref_lvl_2_val = ref_lvl_val[ref_lvl_q]
                tmp_lvl_qos = get(tmp_lvl_tbl, (1, ref_lvl_i), length(tmp_lvl_tbl) + 1)
                if tmp_lvl_qos > tmp_lvl_qos_stop
                    tmp_lvl_qos_stop = max(tmp_lvl_qos_stop << 1, 1)
                    Finch.resize_if_smaller!(tmp_lvl_val_2, tmp_lvl_qos_stop)
                    Finch.fill_range!(tmp_lvl_val_2, 0.0, tmp_lvl_qos, tmp_lvl_qos_stop)
                end
                tmp_lvl_val_2[tmp_lvl_qos] = ref_lvl_2_val
                if tmp_lvl_qos > length(tmp_lvl_tbl)
                    tmp_lvl_tbl[(1, ref_lvl_i)] = tmp_lvl_qos
                    tmp_lvl_ptr[1 + 1] += 1
                end
                ref_lvl_q += 1
            else
                phase_stop_3 = min(phase_stop, ref_lvl_i)
                if ref_lvl_i == phase_stop_3
                    ref_lvl_2_val = ref_lvl_val[ref_lvl_q]
                    tmp_lvl_qos = get(tmp_lvl_tbl, (1, phase_stop_3), length(tmp_lvl_tbl) + 1)
                    if tmp_lvl_qos > tmp_lvl_qos_stop
                        tmp_lvl_qos_stop = max(tmp_lvl_qos_stop << 1, 1)
                        Finch.resize_if_smaller!(tmp_lvl_val_2, tmp_lvl_qos_stop)
                        Finch.fill_range!(tmp_lvl_val_2, 0.0, tmp_lvl_qos, tmp_lvl_qos_stop)
                    end
                    tmp_lvl_val_2[tmp_lvl_qos] = ref_lvl_2_val
                    if tmp_lvl_qos > length(tmp_lvl_tbl)
                        tmp_lvl_tbl[(1, phase_stop_3)] = tmp_lvl_qos
                        tmp_lvl_ptr[1 + 1] += 1
                    end
                    ref_lvl_q += 1
                end
                break
            end
        end
    end
    srt = sort(collect(pairs(tmp_lvl_tbl)))
    resize!(tmp_lvl_idx, length(srt))
    resize!(tmp_lvl_val, length(srt))
    for q = 1:length(srt)
        sugar_1 = srt[q]
        sugar_2 = sugar_1[1]
        p = sugar_2[1]
        i = sugar_2[2]
        v = sugar_1[2]
        tmp_lvl_val[q] = v
        tmp_lvl_idx[q] = i
    end
    resize!(tmp_lvl_ptr, 1 + 1)
    tmp_lvl_ptr[1] = 1
    for p = 2:1 + 1
        tmp_lvl_ptr[p] += tmp_lvl_ptr[p - 1]
    end
    qos_stop = tmp_lvl_ptr[1 + 1] - 1
    resize!(tmp_lvl_val_2, qos_stop)
    (tmp = Tensor((SparseLevel){Int64}(tmp_lvl_2, ref_lvl.shape, tmp_lvl_ptr, tmp_lvl_idx, tmp_lvl_val, tmp_lvl_tbl)),)
end
