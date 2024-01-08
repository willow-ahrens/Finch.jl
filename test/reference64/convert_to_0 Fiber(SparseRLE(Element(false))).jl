begin
    tmp_lvl = (ex.bodies[1]).tns.bind.lvl
    tmp_lvl_ptr = tmp_lvl.ptr
    tmp_lvl_left = tmp_lvl.left
    tmp_lvl_right = tmp_lvl.right
    tmp_lvl_2 = tmp_lvl.lvl
    tmp_lvl_val = tmp_lvl.lvl.val
    ref_lvl = (ex.bodies[2]).body.rhs.tns.bind.lvl
    ref_lvl_ptr = ref_lvl.ptr
    ref_lvl_idx = ref_lvl.idx
    ref_lvl_val = ref_lvl.lvl.val
    tmp_lvl_qos_stop = 0
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
                ref_lvl_2_val = ref_lvl_val[ref_lvl_q]
                if tmp_lvl_qos > tmp_lvl_qos_stop
                    tmp_lvl_qos_stop = max(tmp_lvl_qos_stop << 1, 1)
                    Finch.resize_if_smaller!(tmp_lvl_left, tmp_lvl_qos_stop)
                    Finch.resize_if_smaller!(tmp_lvl_right, tmp_lvl_qos_stop)
                    Finch.resize_if_smaller!(tmp_lvl_val, tmp_lvl_qos_stop)
                    Finch.fill_range!(tmp_lvl_val, false, tmp_lvl_qos, tmp_lvl_qos_stop)
                end
                tmp_lvl_val[tmp_lvl_qos] = ref_lvl_2_val
                tmp_lvl_left[tmp_lvl_qos] = ref_lvl_i
                tmp_lvl_right[tmp_lvl_qos] = ref_lvl_i
                tmp_lvl_qos += 1
                ref_lvl_q += 1
            else
                phase_stop_3 = min(ref_lvl_i, phase_stop)
                if ref_lvl_i == phase_stop_3
                    ref_lvl_2_val = ref_lvl_val[ref_lvl_q]
                    if tmp_lvl_qos > tmp_lvl_qos_stop
                        tmp_lvl_qos_stop = max(tmp_lvl_qos_stop << 1, 1)
                        Finch.resize_if_smaller!(tmp_lvl_left, tmp_lvl_qos_stop)
                        Finch.resize_if_smaller!(tmp_lvl_right, tmp_lvl_qos_stop)
                        Finch.resize_if_smaller!(tmp_lvl_val, tmp_lvl_qos_stop)
                        Finch.fill_range!(tmp_lvl_val, false, tmp_lvl_qos, tmp_lvl_qos_stop)
                    end
                    tmp_lvl_val[tmp_lvl_qos] = ref_lvl_2_val
                    tmp_lvl_left[tmp_lvl_qos] = phase_stop_3
                    tmp_lvl_right[tmp_lvl_qos] = phase_stop_3
                    tmp_lvl_qos += 1
                    ref_lvl_q += 1
                end
                break
            end
        end
    end
    tmp_lvl_ptr[1 + 1] = (tmp_lvl_qos - 0) - 1
    for p = 2:1 + 1
        tmp_lvl_ptr[p] += tmp_lvl_ptr[p - 1]
    end
    resize!(tmp_lvl_ptr, 1 + 1)
    qos = tmp_lvl_ptr[end] - 1
    resize!(tmp_lvl_left, qos)
    resize!(tmp_lvl_right, qos)
    resize!(tmp_lvl_val, qos)
    (tmp = Fiber((SparseRLELevel){Int64}(tmp_lvl_2, ref_lvl.shape, tmp_lvl_ptr, tmp_lvl_left, tmp_lvl_right)),)
end
