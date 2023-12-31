begin
    tmp_lvl = (ex.bodies[1]).tns.bind.lvl
    tmp_lvl_2 = tmp_lvl.lvl
    tmp_lvl_ptr = tmp_lvl_2.ptr
    tmp_lvl_idx = tmp_lvl_2.idx
    tmp_lvl_ofs = tmp_lvl_2.ofs
    tmp_lvl_3 = tmp_lvl_2.lvl
    tmp_lvl_2_val = tmp_lvl_2.lvl.val
    ref_lvl = (ex.bodies[2]).body.body.rhs.tns.bind.lvl
    ref_lvl_ptr = ref_lvl.ptr
    ref_lvl_idx = ref_lvl.idx
    ref_lvl_2 = ref_lvl.lvl
    ref_lvl_ptr_2 = ref_lvl_2.ptr
    ref_lvl_idx_2 = ref_lvl_2.idx
    ref_lvl_2_val = ref_lvl_2.lvl.val
    tmp_lvl_2_qos_fill = 0
    tmp_lvl_2_qos_stop = 0
    tmp_lvl_2_ros_fill = 0
    tmp_lvl_2_ros_stop = 0
    Finch.resize_if_smaller!(tmp_lvl_ofs, 1)
    tmp_lvl_ofs[1] = 1
    tmp_lvl_2_prev_pos = 0
    p_start_2 = ref_lvl.shape
    Finch.resize_if_smaller!(tmp_lvl_ptr, p_start_2 + 1)
    Finch.fill_range!(tmp_lvl_ptr, 0, 1 + 1, p_start_2 + 1)
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
                tmp_lvl_q = (1 - 1) * ref_lvl.shape + ref_lvl_i
                tmp_lvl_2_ros = tmp_lvl_2_ros_fill
                tmp_lvl_2_qos = tmp_lvl_2_qos_fill + 1
                tmp_lvl_2_i_prev = -1
                tmp_lvl_2_prev_pos < tmp_lvl_q || throw(FinchProtocolError("SparseVBLLevels cannot be updated multiple times"))
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
                            if tmp_lvl_2_qos > tmp_lvl_2_qos_stop
                                tmp_lvl_2_qos_stop = max(tmp_lvl_2_qos_stop << 1, 1)
                                Finch.resize_if_smaller!(tmp_lvl_2_val, tmp_lvl_2_qos_stop)
                                Finch.fill_range!(tmp_lvl_2_val, false, tmp_lvl_2_qos, tmp_lvl_2_qos_stop)
                            end
                            tmp_lvl_2_val[tmp_lvl_2_qos] = ref_lvl_3_val
                            if ref_lvl_2_i > tmp_lvl_2_i_prev + 1
                                tmp_lvl_2_ros += 1
                                if tmp_lvl_2_ros > tmp_lvl_2_ros_stop
                                    tmp_lvl_2_ros_stop = max(tmp_lvl_2_ros_stop << 1, 1)
                                    Finch.resize_if_smaller!(tmp_lvl_idx, tmp_lvl_2_ros_stop)
                                    Finch.resize_if_smaller!(tmp_lvl_ofs, tmp_lvl_2_ros_stop + 1)
                                end
                            end
                            tmp_lvl_idx[tmp_lvl_2_ros] = (tmp_lvl_2_i_prev = ref_lvl_2_i)
                            tmp_lvl_2_qos += 1
                            tmp_lvl_ofs[tmp_lvl_2_ros + 1] = tmp_lvl_2_qos
                            tmp_lvl_2_prev_pos = tmp_lvl_q
                            ref_lvl_2_q += 1
                        else
                            phase_stop_5 = min(phase_stop_3, ref_lvl_2_i)
                            if ref_lvl_2_i == phase_stop_5
                                ref_lvl_3_val = ref_lvl_2_val[ref_lvl_2_q]
                                if tmp_lvl_2_qos > tmp_lvl_2_qos_stop
                                    tmp_lvl_2_qos_stop = max(tmp_lvl_2_qos_stop << 1, 1)
                                    Finch.resize_if_smaller!(tmp_lvl_2_val, tmp_lvl_2_qos_stop)
                                    Finch.fill_range!(tmp_lvl_2_val, false, tmp_lvl_2_qos, tmp_lvl_2_qos_stop)
                                end
                                tmp_lvl_2_val[tmp_lvl_2_qos] = ref_lvl_3_val
                                if phase_stop_5 > tmp_lvl_2_i_prev + 1
                                    tmp_lvl_2_ros += 1
                                    if tmp_lvl_2_ros > tmp_lvl_2_ros_stop
                                        tmp_lvl_2_ros_stop = max(tmp_lvl_2_ros_stop << 1, 1)
                                        Finch.resize_if_smaller!(tmp_lvl_idx, tmp_lvl_2_ros_stop)
                                        Finch.resize_if_smaller!(tmp_lvl_ofs, tmp_lvl_2_ros_stop + 1)
                                    end
                                end
                                tmp_lvl_idx[tmp_lvl_2_ros] = (tmp_lvl_2_i_prev = phase_stop_5)
                                tmp_lvl_2_qos += 1
                                tmp_lvl_ofs[tmp_lvl_2_ros + 1] = tmp_lvl_2_qos
                                tmp_lvl_2_prev_pos = tmp_lvl_q
                                ref_lvl_2_q += 1
                            end
                            break
                        end
                    end
                end
                tmp_lvl_ptr[tmp_lvl_q + 1] = tmp_lvl_2_ros - tmp_lvl_2_ros_fill
                tmp_lvl_2_ros_fill = tmp_lvl_2_ros
                tmp_lvl_2_qos_fill = tmp_lvl_2_qos - 1
                ref_lvl_q += 1
            else
                phase_stop_6 = min(phase_stop, ref_lvl_i)
                if ref_lvl_i == phase_stop_6
                    tmp_lvl_q = (1 - 1) * ref_lvl.shape + phase_stop_6
                    tmp_lvl_2_ros_2 = tmp_lvl_2_ros_fill
                    tmp_lvl_2_qos_2 = tmp_lvl_2_qos_fill + 1
                    tmp_lvl_2_i_prev_2 = -1
                    tmp_lvl_2_prev_pos < tmp_lvl_q || throw(FinchProtocolError("SparseVBLLevels cannot be updated multiple times"))
                    ref_lvl_2_q = ref_lvl_ptr_2[ref_lvl_q]
                    ref_lvl_2_q_stop = ref_lvl_ptr_2[ref_lvl_q + 1]
                    if ref_lvl_2_q < ref_lvl_2_q_stop
                        ref_lvl_2_i1 = ref_lvl_idx_2[ref_lvl_2_q_stop - 1]
                    else
                        ref_lvl_2_i1 = 0
                    end
                    phase_stop_7 = min(ref_lvl_2_i1, ref_lvl_2.shape)
                    if phase_stop_7 >= 1
                        if ref_lvl_idx_2[ref_lvl_2_q] < 1
                            ref_lvl_2_q = Finch.scansearch(ref_lvl_idx_2, 1, ref_lvl_2_q, ref_lvl_2_q_stop - 1)
                        end
                        while true
                            ref_lvl_2_i = ref_lvl_idx_2[ref_lvl_2_q]
                            if ref_lvl_2_i < phase_stop_7
                                ref_lvl_3_val_2 = ref_lvl_2_val[ref_lvl_2_q]
                                if tmp_lvl_2_qos_2 > tmp_lvl_2_qos_stop
                                    tmp_lvl_2_qos_stop = max(tmp_lvl_2_qos_stop << 1, 1)
                                    Finch.resize_if_smaller!(tmp_lvl_2_val, tmp_lvl_2_qos_stop)
                                    Finch.fill_range!(tmp_lvl_2_val, false, tmp_lvl_2_qos_2, tmp_lvl_2_qos_stop)
                                end
                                tmp_lvl_2_val[tmp_lvl_2_qos_2] = ref_lvl_3_val_2
                                if ref_lvl_2_i > tmp_lvl_2_i_prev_2 + 1
                                    tmp_lvl_2_ros_2 += 1
                                    if tmp_lvl_2_ros_2 > tmp_lvl_2_ros_stop
                                        tmp_lvl_2_ros_stop = max(tmp_lvl_2_ros_stop << 1, 1)
                                        Finch.resize_if_smaller!(tmp_lvl_idx, tmp_lvl_2_ros_stop)
                                        Finch.resize_if_smaller!(tmp_lvl_ofs, tmp_lvl_2_ros_stop + 1)
                                    end
                                end
                                tmp_lvl_idx[tmp_lvl_2_ros_2] = (tmp_lvl_2_i_prev_2 = ref_lvl_2_i)
                                tmp_lvl_2_qos_2 += 1
                                tmp_lvl_ofs[tmp_lvl_2_ros_2 + 1] = tmp_lvl_2_qos_2
                                tmp_lvl_2_prev_pos = tmp_lvl_q
                                ref_lvl_2_q += 1
                            else
                                phase_stop_9 = min(ref_lvl_2_i, phase_stop_7)
                                if ref_lvl_2_i == phase_stop_9
                                    ref_lvl_3_val_2 = ref_lvl_2_val[ref_lvl_2_q]
                                    if tmp_lvl_2_qos_2 > tmp_lvl_2_qos_stop
                                        tmp_lvl_2_qos_stop = max(tmp_lvl_2_qos_stop << 1, 1)
                                        Finch.resize_if_smaller!(tmp_lvl_2_val, tmp_lvl_2_qos_stop)
                                        Finch.fill_range!(tmp_lvl_2_val, false, tmp_lvl_2_qos_2, tmp_lvl_2_qos_stop)
                                    end
                                    tmp_lvl_2_val[tmp_lvl_2_qos_2] = ref_lvl_3_val_2
                                    if phase_stop_9 > tmp_lvl_2_i_prev_2 + 1
                                        tmp_lvl_2_ros_2 += 1
                                        if tmp_lvl_2_ros_2 > tmp_lvl_2_ros_stop
                                            tmp_lvl_2_ros_stop = max(tmp_lvl_2_ros_stop << 1, 1)
                                            Finch.resize_if_smaller!(tmp_lvl_idx, tmp_lvl_2_ros_stop)
                                            Finch.resize_if_smaller!(tmp_lvl_ofs, tmp_lvl_2_ros_stop + 1)
                                        end
                                    end
                                    tmp_lvl_idx[tmp_lvl_2_ros_2] = (tmp_lvl_2_i_prev_2 = phase_stop_9)
                                    tmp_lvl_2_qos_2 += 1
                                    tmp_lvl_ofs[tmp_lvl_2_ros_2 + 1] = tmp_lvl_2_qos_2
                                    tmp_lvl_2_prev_pos = tmp_lvl_q
                                    ref_lvl_2_q += 1
                                end
                                break
                            end
                        end
                    end
                    tmp_lvl_ptr[tmp_lvl_q + 1] = tmp_lvl_2_ros_2 - tmp_lvl_2_ros_fill
                    tmp_lvl_2_ros_fill = tmp_lvl_2_ros_2
                    tmp_lvl_2_qos_fill = tmp_lvl_2_qos_2 - 1
                    ref_lvl_q += 1
                end
                break
            end
        end
    end
    for p = 2:ref_lvl.shape + 1
        tmp_lvl_ptr[p] += tmp_lvl_ptr[p - 1]
    end
    qos = 1 * ref_lvl.shape
    resize!(tmp_lvl_ptr, qos + 1)
    ros = tmp_lvl_ptr[end] - 1
    resize!(tmp_lvl_idx, ros)
    resize!(tmp_lvl_ofs, ros + 1)
    qos_2 = tmp_lvl_ofs[end] - 1
    resize!(tmp_lvl_2_val, qos_2)
    (tmp = Fiber((DenseLevel){Int32}((SparseVBLLevel){Int32}(tmp_lvl_3, ref_lvl_2.shape, tmp_lvl_ptr, tmp_lvl_idx, tmp_lvl_ofs), ref_lvl.shape)),)
end
