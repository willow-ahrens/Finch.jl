begin
    tmp_lvl = (ex.bodies[1]).tns.bind.lvl
    tmp_lvl_2 = tmp_lvl.lvl
    tmp_lvl_val = tmp_lvl.lvl.val
    ref_lvl = (ex.bodies[2]).body.body.rhs.tns.bind.lvl
    ref_lvl_ptr = ref_lvl.ptr
    ref_lvl_idx = ref_lvl.idx
    ref_lvl_2 = ref_lvl.lvl
    ref_lvl_ptr_2 = ref_lvl_2.ptr
    ref_lvl_idx_2 = ref_lvl_2.idx
    ref_lvl_2_val = ref_lvl_2.lvl.val
    pos_stop = fld(ref_lvl.shape * (1 + ref_lvl.shape), 2)
    Finch.resize_if_smaller!(tmp_lvl_val, pos_stop)
    Finch.fill_range!(tmp_lvl_val, false, 1, pos_stop)
    tmp_lvl_q = (1 - 1) * fld(ref_lvl.shape * (1 + ref_lvl.shape), 2) + 1
    ref_lvl_q = ref_lvl_ptr[1]
    ref_lvl_q_stop = ref_lvl_ptr[1 + 1]
    if ref_lvl_q < ref_lvl_q_stop
        ref_lvl_i1 = ref_lvl_idx[ref_lvl_q_stop - 1]
    else
        ref_lvl_i1 = 0
    end
    phase_stop = min(ref_lvl.shape, ref_lvl_i1)
    if phase_stop >= 1
        if ref_lvl_idx[ref_lvl_q] < 1
            ref_lvl_q = Finch.scansearch(ref_lvl_idx, 1, ref_lvl_q, ref_lvl_q_stop - 1)
        end
        while true
            ref_lvl_i = ref_lvl_idx[ref_lvl_q]
            if ref_lvl_i < phase_stop
                tmp_lvl_s = tmp_lvl_q + fld(ref_lvl_i * (-1 + ref_lvl_i), 2)
                ref_lvl_2_q = ref_lvl_ptr_2[ref_lvl_q]
                ref_lvl_2_q_stop = ref_lvl_ptr_2[ref_lvl_q + 1]
                if ref_lvl_2_q < ref_lvl_2_q_stop
                    ref_lvl_2_i1 = ref_lvl_idx_2[ref_lvl_2_q_stop - 1]
                else
                    ref_lvl_2_i1 = 0
                end
                phase_stop_3 = min(ref_lvl_i, ref_lvl_2.shape, ref_lvl_2_i1)
                if phase_stop_3 >= 1
                    if ref_lvl_idx_2[ref_lvl_2_q] < 1
                        ref_lvl_2_q = Finch.scansearch(ref_lvl_idx_2, 1, ref_lvl_2_q, ref_lvl_2_q_stop - 1)
                    end
                    while true
                        ref_lvl_2_i = ref_lvl_idx_2[ref_lvl_2_q]
                        if ref_lvl_2_i < phase_stop_3
                            ref_lvl_3_val = ref_lvl_2_val[ref_lvl_2_q]
                            tmp_lvl_val[tmp_lvl_s + -1 + ref_lvl_2_i] = ref_lvl_3_val
                            ref_lvl_2_q += 1
                        else
                            phase_stop_5 = min(ref_lvl_2_i, phase_stop_3)
                            if ref_lvl_2_i == phase_stop_5
                                ref_lvl_3_val = ref_lvl_2_val[ref_lvl_2_q]
                                tmp_lvl_val[tmp_lvl_s + -1 + phase_stop_5] = ref_lvl_3_val
                                ref_lvl_2_q += 1
                            end
                            break
                        end
                    end
                end
                ref_lvl_q += 1
            else
                phase_stop_9 = min(ref_lvl_i, phase_stop)
                if ref_lvl_i == phase_stop_9
                    tmp_lvl_s = tmp_lvl_q + fld(phase_stop_9 * (-1 + phase_stop_9), 2)
                    ref_lvl_2_q = ref_lvl_ptr_2[ref_lvl_q]
                    ref_lvl_2_q_stop = ref_lvl_ptr_2[ref_lvl_q + 1]
                    if ref_lvl_2_q < ref_lvl_2_q_stop
                        ref_lvl_2_i1 = ref_lvl_idx_2[ref_lvl_2_q_stop - 1]
                    else
                        ref_lvl_2_i1 = 0
                    end
                    phase_stop_10 = min(ref_lvl_2.shape, ref_lvl_2_i1, phase_stop_9)
                    if phase_stop_10 >= 1
                        if ref_lvl_idx_2[ref_lvl_2_q] < 1
                            ref_lvl_2_q = Finch.scansearch(ref_lvl_idx_2, 1, ref_lvl_2_q, ref_lvl_2_q_stop - 1)
                        end
                        while true
                            ref_lvl_2_i = ref_lvl_idx_2[ref_lvl_2_q]
                            if ref_lvl_2_i < phase_stop_10
                                ref_lvl_3_val_3 = ref_lvl_2_val[ref_lvl_2_q]
                                tmp_lvl_val[tmp_lvl_s + -1 + ref_lvl_2_i] = ref_lvl_3_val_3
                                ref_lvl_2_q += 1
                            else
                                phase_stop_12 = min(ref_lvl_2_i, phase_stop_10)
                                if ref_lvl_2_i == phase_stop_12
                                    ref_lvl_3_val_3 = ref_lvl_2_val[ref_lvl_2_q]
                                    tmp_lvl_val[tmp_lvl_s + -1 + phase_stop_12] = ref_lvl_3_val_3
                                    ref_lvl_2_q += 1
                                end
                                break
                            end
                        end
                    end
                    ref_lvl_q += 1
                end
                break
            end
        end
    end
    resize!(tmp_lvl_val, 1 * fld(ref_lvl.shape * (1 + ref_lvl.shape), 2))
    (tmp = Tensor((SparseTriangleLevel){2, Int32}(tmp_lvl_2, ref_lvl.shape)),)
end
