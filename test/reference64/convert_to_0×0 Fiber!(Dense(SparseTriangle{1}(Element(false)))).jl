begin
    tmp_lvl = (ex.bodies[1]).tns.bind.lvl
    tmp_lvl_2 = tmp_lvl.lvl
    tmp_lvl_3 = tmp_lvl_2.lvl
    tmp_lvl_2_val = tmp_lvl_2.lvl.val
    ref_lvl = (ex.bodies[2]).body.body.rhs.tns.bind.lvl
    ref_lvl_ptr = ref_lvl.ptr
    ref_lvl_idx = ref_lvl.idx
    ref_lvl_2 = ref_lvl.lvl
    ref_lvl_ptr_2 = ref_lvl_2.ptr
    ref_lvl_idx_2 = ref_lvl_2.idx
    ref_lvl_2_val = ref_lvl_2.lvl.val
    pos_stop = fld(ref_lvl_2.shape, 1) * ref_lvl.shape
    Finch.resize_if_smaller!(tmp_lvl_2_val, pos_stop)
    Finch.fill_range!(tmp_lvl_2_val, false, 1, pos_stop)
    ref_lvl_q = ref_lvl_ptr[1]
    ref_lvl_q_stop = ref_lvl_ptr[1 + 1]
    if ref_lvl_q < ref_lvl_q_stop
        ref_lvl_i1 = ref_lvl_idx[ref_lvl_q_stop - 1]
    else
        ref_lvl_i1 = 0
    end
    phase_stop = min(ref_lvl.shape, ref_lvl_i1)
    if phase_stop >= 1
        j = 1
        if ref_lvl_idx[ref_lvl_q] < 1
            ref_lvl_q = Finch.scansearch(ref_lvl_idx, 1, ref_lvl_q, ref_lvl_q_stop - 1)
        end
        while j <= phase_stop
            ref_lvl_i = ref_lvl_idx[ref_lvl_q]
            phase_stop_2 = min(phase_stop, ref_lvl_i)
            if ref_lvl_i == phase_stop_2
                tmp_lvl_q = (1 - 1) * ref_lvl.shape + phase_stop_2
                tmp_lvl_2_q = (tmp_lvl_q - 1) * fld(ref_lvl_2.shape, 1) + 1
                ref_lvl_2_q = ref_lvl_ptr_2[ref_lvl_q]
                ref_lvl_2_q_stop = ref_lvl_ptr_2[ref_lvl_q + 1]
                if ref_lvl_2_q < ref_lvl_2_q_stop
                    ref_lvl_2_i1 = ref_lvl_idx_2[ref_lvl_2_q_stop - 1]
                else
                    ref_lvl_2_i1 = 0
                end
                phase_stop_3 = min(ref_lvl_2.shape, ref_lvl_2_i1)
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
                            tmp_lvl_2_val[tmp_lvl_2_q + -1 + phase_stop_4] = ref_lvl_3_val
                            ref_lvl_2_q += 1
                        end
                        i = phase_stop_4 + 1
                    end
                end
                ref_lvl_q += 1
            end
            j = phase_stop_2 + 1
        end
    end
    qos = 1 * ref_lvl.shape
    resize!(tmp_lvl_2_val, qos * fld(ref_lvl_2.shape, 1))
    (tmp = Fiber((DenseLevel){Int64}((SparseTriangleLevel){1, Int64}(tmp_lvl_3, ref_lvl_2.shape), ref_lvl.shape)),)
end
