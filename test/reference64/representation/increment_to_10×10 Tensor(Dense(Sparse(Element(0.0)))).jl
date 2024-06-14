begin
    fmt_lvl = (ex.bodies[1]).body.body.lhs.tns.bind.lvl
    fmt_lvl_2 = fmt_lvl.lvl
    fmt_lvl_ptr = fmt_lvl_2.ptr
    fmt_lvl_idx = fmt_lvl_2.idx
    fmt_lvl_val = fmt_lvl_2.val
    fmt_lvl_tbl = fmt_lvl_2.tbl
    fmt_lvl_2_val = fmt_lvl_2.lvl.val
    arr_2_lvl = (ex.bodies[1]).body.body.rhs.tns.bind.lvl
    arr_2_lvl_ptr = (ex.bodies[1]).body.body.rhs.tns.bind.lvl.ptr
    arr_2_lvl_tbl1 = (ex.bodies[1]).body.body.rhs.tns.bind.lvl.tbl[1]
    arr_2_lvl_tbl2 = (ex.bodies[1]).body.body.rhs.tns.bind.lvl.tbl[2]
    arr_2_lvl_val = arr_2_lvl.lvl.val
    arr_2_lvl.shape[1] == fmt_lvl_2.shape || throw(DimensionMismatch("mismatched dimension limits ($(arr_2_lvl.shape[1]) != $(fmt_lvl_2.shape))"))
    arr_2_lvl.shape[2] == fmt_lvl.shape || throw(DimensionMismatch("mismatched dimension limits ($(arr_2_lvl.shape[2]) != $(fmt_lvl.shape))"))
    fmt_lvl_qos_stop = fmt_lvl_ptr[fmt_lvl.shape + 1] - 1
    for p = fmt_lvl.shape:-1:1
        fmt_lvl_ptr[p + 1] = fmt_lvl_ptr[p + 1] - fmt_lvl_ptr[p]
    end
    arr_2_lvl_q = arr_2_lvl_ptr[1]
    arr_2_lvl_q_stop = arr_2_lvl_ptr[1 + 1]
    if arr_2_lvl_q < arr_2_lvl_q_stop
        arr_2_lvl_i_stop = arr_2_lvl_tbl2[arr_2_lvl_q_stop - 1]
    else
        arr_2_lvl_i_stop = 0
    end
    phase_stop = min(arr_2_lvl.shape[2], arr_2_lvl_i_stop)
    if phase_stop >= 1
        if arr_2_lvl_tbl2[arr_2_lvl_q] < 1
            arr_2_lvl_q = Finch.scansearch(arr_2_lvl_tbl2, 1, arr_2_lvl_q, arr_2_lvl_q_stop - 1)
        end
        while true
            arr_2_lvl_i = arr_2_lvl_tbl2[arr_2_lvl_q]
            arr_2_lvl_q_step = arr_2_lvl_q
            if arr_2_lvl_tbl2[arr_2_lvl_q] == arr_2_lvl_i
                arr_2_lvl_q_step = Finch.scansearch(arr_2_lvl_tbl2, arr_2_lvl_i + 1, arr_2_lvl_q, arr_2_lvl_q_stop - 1)
            end
            if arr_2_lvl_i < phase_stop
                fmt_lvl_q = (1 - 1) * fmt_lvl.shape + arr_2_lvl_i
                arr_2_lvl_q_2 = arr_2_lvl_q
                if arr_2_lvl_q < arr_2_lvl_q_step
                    arr_2_lvl_i_stop_2 = arr_2_lvl_tbl1[arr_2_lvl_q_step - 1]
                else
                    arr_2_lvl_i_stop_2 = 0
                end
                phase_stop_3 = min(arr_2_lvl.shape[1], arr_2_lvl_i_stop_2)
                if phase_stop_3 >= 1
                    if arr_2_lvl_tbl1[arr_2_lvl_q] < 1
                        arr_2_lvl_q_2 = Finch.scansearch(arr_2_lvl_tbl1, 1, arr_2_lvl_q, arr_2_lvl_q_step - 1)
                    end
                    while true
                        arr_2_lvl_i_2 = arr_2_lvl_tbl1[arr_2_lvl_q_2]
                        if arr_2_lvl_i_2 < phase_stop_3
                            arr_2_lvl_2_val = arr_2_lvl_val[arr_2_lvl_q_2]
                            fmt_lvl_2_qos = get(fmt_lvl_tbl, (fmt_lvl_q, arr_2_lvl_i_2), length(fmt_lvl_tbl) + 1)
                            if fmt_lvl_2_qos > fmt_lvl_qos_stop
                                fmt_lvl_qos_stop = max(fmt_lvl_qos_stop << 1, 1)
                                Finch.resize_if_smaller!(fmt_lvl_2_val, fmt_lvl_qos_stop)
                                Finch.fill_range!(fmt_lvl_2_val, 0.0, fmt_lvl_2_qos, fmt_lvl_qos_stop)
                            end
                            fmt_lvl_2_val[fmt_lvl_2_qos] = arr_2_lvl_2_val + fmt_lvl_2_val[fmt_lvl_2_qos]
                            if fmt_lvl_2_qos > length(fmt_lvl_tbl)
                                fmt_lvl_tbl[(fmt_lvl_q, arr_2_lvl_i_2)] = fmt_lvl_2_qos
                                fmt_lvl_ptr[fmt_lvl_q + 1] += 1
                            end
                            arr_2_lvl_q_2 += 1
                        else
                            phase_stop_5 = min(phase_stop_3, arr_2_lvl_i_2)
                            if arr_2_lvl_i_2 == phase_stop_5
                                arr_2_lvl_2_val = arr_2_lvl_val[arr_2_lvl_q_2]
                                fmt_lvl_2_qos = get(fmt_lvl_tbl, (fmt_lvl_q, phase_stop_5), length(fmt_lvl_tbl) + 1)
                                if fmt_lvl_2_qos > fmt_lvl_qos_stop
                                    fmt_lvl_qos_stop = max(fmt_lvl_qos_stop << 1, 1)
                                    Finch.resize_if_smaller!(fmt_lvl_2_val, fmt_lvl_qos_stop)
                                    Finch.fill_range!(fmt_lvl_2_val, 0.0, fmt_lvl_2_qos, fmt_lvl_qos_stop)
                                end
                                fmt_lvl_2_val[fmt_lvl_2_qos] = arr_2_lvl_2_val + fmt_lvl_2_val[fmt_lvl_2_qos]
                                if fmt_lvl_2_qos > length(fmt_lvl_tbl)
                                    fmt_lvl_tbl[(fmt_lvl_q, phase_stop_5)] = fmt_lvl_2_qos
                                    fmt_lvl_ptr[fmt_lvl_q + 1] += 1
                                end
                                arr_2_lvl_q_2 += 1
                            end
                            break
                        end
                    end
                end
                arr_2_lvl_q = arr_2_lvl_q_step
            else
                phase_stop_7 = min(phase_stop, arr_2_lvl_i)
                if arr_2_lvl_i == phase_stop_7
                    fmt_lvl_q = (1 - 1) * fmt_lvl.shape + phase_stop_7
                    arr_2_lvl_q_2 = arr_2_lvl_q
                    if arr_2_lvl_q < arr_2_lvl_q_step
                        arr_2_lvl_i_stop_2 = arr_2_lvl_tbl1[arr_2_lvl_q_step - 1]
                    else
                        arr_2_lvl_i_stop_2 = 0
                    end
                    phase_stop_8 = min(arr_2_lvl.shape[1], arr_2_lvl_i_stop_2)
                    if phase_stop_8 >= 1
                        if arr_2_lvl_tbl1[arr_2_lvl_q] < 1
                            arr_2_lvl_q_2 = Finch.scansearch(arr_2_lvl_tbl1, 1, arr_2_lvl_q, arr_2_lvl_q_step - 1)
                        end
                        while true
                            arr_2_lvl_i_2 = arr_2_lvl_tbl1[arr_2_lvl_q_2]
                            if arr_2_lvl_i_2 < phase_stop_8
                                arr_2_lvl_2_val_2 = arr_2_lvl_val[arr_2_lvl_q_2]
                                fmt_lvl_2_qos_2 = get(fmt_lvl_tbl, (fmt_lvl_q, arr_2_lvl_i_2), length(fmt_lvl_tbl) + 1)
                                if fmt_lvl_2_qos_2 > fmt_lvl_qos_stop
                                    fmt_lvl_qos_stop = max(fmt_lvl_qos_stop << 1, 1)
                                    Finch.resize_if_smaller!(fmt_lvl_2_val, fmt_lvl_qos_stop)
                                    Finch.fill_range!(fmt_lvl_2_val, 0.0, fmt_lvl_2_qos_2, fmt_lvl_qos_stop)
                                end
                                fmt_lvl_2_val[fmt_lvl_2_qos_2] = arr_2_lvl_2_val_2 + fmt_lvl_2_val[fmt_lvl_2_qos_2]
                                if fmt_lvl_2_qos_2 > length(fmt_lvl_tbl)
                                    fmt_lvl_tbl[(fmt_lvl_q, arr_2_lvl_i_2)] = fmt_lvl_2_qos_2
                                    fmt_lvl_ptr[fmt_lvl_q + 1] += 1
                                end
                                arr_2_lvl_q_2 += 1
                            else
                                phase_stop_10 = min(arr_2_lvl_i_2, phase_stop_8)
                                if arr_2_lvl_i_2 == phase_stop_10
                                    arr_2_lvl_2_val_2 = arr_2_lvl_val[arr_2_lvl_q_2]
                                    fmt_lvl_2_qos_2 = get(fmt_lvl_tbl, (fmt_lvl_q, phase_stop_10), length(fmt_lvl_tbl) + 1)
                                    if fmt_lvl_2_qos_2 > fmt_lvl_qos_stop
                                        fmt_lvl_qos_stop = max(fmt_lvl_qos_stop << 1, 1)
                                        Finch.resize_if_smaller!(fmt_lvl_2_val, fmt_lvl_qos_stop)
                                        Finch.fill_range!(fmt_lvl_2_val, 0.0, fmt_lvl_2_qos_2, fmt_lvl_qos_stop)
                                    end
                                    fmt_lvl_2_val[fmt_lvl_2_qos_2] = arr_2_lvl_2_val_2 + fmt_lvl_2_val[fmt_lvl_2_qos_2]
                                    if fmt_lvl_2_qos_2 > length(fmt_lvl_tbl)
                                        fmt_lvl_tbl[(fmt_lvl_q, phase_stop_10)] = fmt_lvl_2_qos_2
                                        fmt_lvl_ptr[fmt_lvl_q + 1] += 1
                                    end
                                    arr_2_lvl_q_2 += 1
                                end
                                break
                            end
                        end
                    end
                    arr_2_lvl_q = arr_2_lvl_q_step
                end
                break
            end
        end
    end
    result = ()
    max_pos = maximum(fmt_lvl_ptr)
    resize!(fmt_lvl_ptr, fmt_lvl.shape + 1)
    fmt_lvl_ptr[1] = 1
    for p_3 = 2:fmt_lvl.shape + 1
        fmt_lvl_ptr[p_3] += fmt_lvl_ptr[p_3 - 1]
    end
    resize!(fmt_lvl_idx, length(fmt_lvl_tbl))
    resize!(fmt_lvl_val, length(fmt_lvl_tbl))
    ps = copy(fmt_lvl_ptr)
    for entry = pairs(fmt_lvl_tbl)
        sugar_2 = entry[1]
        p_3 = sugar_2[1]
        i_14 = sugar_2[2]
        v = entry[2]
        q = ps[p_3]
        fmt_lvl_idx[q] = i_14
        fmt_lvl_val[q] = v
        ps[p_3] += 1
    end
    perm = Vector{Int64}(undef, max_pos)
    idx_temp = (typeof(fmt_lvl_idx))(undef, max_pos)
    val_temp = (typeof(fmt_lvl_val))(undef, max_pos)
    for p_3 = 1:fmt_lvl.shape
        start = fmt_lvl_ptr[p_3]
        stop = fmt_lvl_ptr[p_3 + 1] - 1
        sortperm!(@view(perm[1:(stop - start) + 1]), fmt_lvl_idx[start:stop])
        for i_14 = 1:(stop - start) + 1
            idx_temp[i_14] = fmt_lvl_idx[(start + perm[i_14]) - 1]
            val_temp[i_14] = fmt_lvl_val[(start + perm[i_14]) - 1]
        end
        for i_14 = 1:(stop - start) + 1
            fmt_lvl_idx[(start + i_14) - 1] = idx_temp[i_14]
            fmt_lvl_val[(start + i_14) - 1] = val_temp[i_14]
        end
    end
    qos_stop = fmt_lvl_ptr[fmt_lvl.shape + 1] - 1
    resize!(fmt_lvl_2_val, qos_stop)
    result
end
