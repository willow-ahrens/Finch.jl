begin
    tmp_lvl = (ex.bodies[1]).tns.bind.lvl
    tmp_lvl_2 = tmp_lvl.lvl
    tmp_lvl_val = tmp_lvl.lvl.val
    ref_lvl = (ex.bodies[2]).body.rhs.tns.bind.lvl
    ref_lvl_ptr = ref_lvl.ptr
    ref_lvl_idx = ref_lvl.idx
    ref_lvl_val = ref_lvl.lvl.val
    pos_stop = fld(ref_lvl.shape, 1)
    Finch.resize_if_smaller!(tmp_lvl_val, pos_stop)
    Finch.fill_range!(tmp_lvl_val, false, 1, pos_stop)
    tmp_lvl_q = (1 - 1) * fld(ref_lvl.shape, 1) + 1
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
                ref_lvl_2_val = ref_lvl_val[ref_lvl_q]
                tmp_lvl_val[tmp_lvl_q + -1 + ref_lvl_i] = ref_lvl_2_val
                ref_lvl_q += 1
            else
                phase_stop_3 = min(ref_lvl_i, phase_stop)
                if ref_lvl_i == phase_stop_3
                    ref_lvl_2_val = ref_lvl_val[ref_lvl_q]
                    tmp_lvl_val[tmp_lvl_q + -1 + phase_stop_3] = ref_lvl_2_val
                    ref_lvl_q += 1
                end
                break
            end
        end
    end
    resize!(tmp_lvl_val, 1 * fld(ref_lvl.shape, 1))
    (tmp = Fiber((SparseTriangleLevel){1, Int32}(tmp_lvl_2, ref_lvl.shape)),)
end
