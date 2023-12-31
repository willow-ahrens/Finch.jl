begin
    fmt_lvl = ex.body.body.lhs.tns.bind.lvl
    fmt_lvl_2 = fmt_lvl.lvl
    fmt_lvl_2_qos_fill = length(fmt_lvl_2.tbl)
    fmt_lvl_2_qos_stop = fmt_lvl_2_qos_fill
    fmt_lvl_ptr = fmt_lvl.lvl.ptr
    fmt_lvl_tbl = fmt_lvl.lvl.tbl
    fmt_lvl_srt = fmt_lvl.lvl.srt
    fmt_lvl_3 = fmt_lvl_2.lvl
    fmt_lvl_2_val = fmt_lvl_2.lvl.val
    arr_2_lvl = ex.body.body.rhs.tns.bind.lvl
    arr_2_lvl_ptr = ex.body.body.rhs.tns.bind.lvl.ptr
    arr_2_lvl_tbl1 = ex.body.body.rhs.tns.bind.lvl.tbl[1]
    arr_2_lvl_tbl2 = ex.body.body.rhs.tns.bind.lvl.tbl[2]
    arr_2_lvl_val = arr_2_lvl.lvl.val
    arr_2_lvl.shape[1] == fmt_lvl_2.shape[1] || throw(DimensionMismatch("mismatched dimension limits ($(arr_2_lvl.shape[1]) != $(fmt_lvl_2.shape[1]))"))
    arr_2_lvl.shape[2] == fmt_lvl.shape || throw(DimensionMismatch("mismatched dimension limits ($(arr_2_lvl.shape[2]) != $(fmt_lvl.shape))"))
    for fmt_lvl_2_p = 1 * fmt_lvl.shape + 1:-1:2
        fmt_lvl_ptr[fmt_lvl_2_p] = fmt_lvl_ptr[fmt_lvl_2_p] - fmt_lvl_ptr[fmt_lvl_2_p - 1]
    end
    fmt_lvl_ptr[1] = 1
    fmt_lvl_2_qos_fill = length(fmt_lvl_tbl)
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
                            fmt_lvl_2_key = (fmt_lvl_q, (arr_2_lvl_i_2,))
                            fmt_lvl_2_q = get(fmt_lvl_tbl, fmt_lvl_2_key, fmt_lvl_2_qos_fill + 1)
                            if fmt_lvl_2_q > fmt_lvl_2_qos_stop
                                fmt_lvl_2_qos_stop = max(fmt_lvl_2_qos_stop << 1, 1)
                                Finch.resize_if_smaller!(fmt_lvl_2_val, fmt_lvl_2_qos_stop)
                                Finch.fill_range!(fmt_lvl_2_val, 0.0, fmt_lvl_2_q, fmt_lvl_2_qos_stop)
                            end
                            fmt_lvl_2_val[fmt_lvl_2_q] = arr_2_lvl_2_val + fmt_lvl_2_val[fmt_lvl_2_q]
                            if fmt_lvl_2_q > fmt_lvl_2_qos_fill
                                fmt_lvl_2_qos_fill = fmt_lvl_2_q
                                fmt_lvl_tbl[fmt_lvl_2_key] = fmt_lvl_2_q
                                fmt_lvl_ptr[fmt_lvl_q + 1] += 1
                            end
                            arr_2_lvl_q_2 += 1
                        else
                            phase_stop_5 = min(phase_stop_3, arr_2_lvl_i_2)
                            if arr_2_lvl_i_2 == phase_stop_5
                                arr_2_lvl_2_val = arr_2_lvl_val[arr_2_lvl_q_2]
                                fmt_lvl_2_key = (fmt_lvl_q, (phase_stop_5,))
                                fmt_lvl_2_q = get(fmt_lvl_tbl, fmt_lvl_2_key, fmt_lvl_2_qos_fill + 1)
                                if fmt_lvl_2_q > fmt_lvl_2_qos_stop
                                    fmt_lvl_2_qos_stop = max(fmt_lvl_2_qos_stop << 1, 1)
                                    Finch.resize_if_smaller!(fmt_lvl_2_val, fmt_lvl_2_qos_stop)
                                    Finch.fill_range!(fmt_lvl_2_val, 0.0, fmt_lvl_2_q, fmt_lvl_2_qos_stop)
                                end
                                fmt_lvl_2_val[fmt_lvl_2_q] = arr_2_lvl_2_val + fmt_lvl_2_val[fmt_lvl_2_q]
                                if fmt_lvl_2_q > fmt_lvl_2_qos_fill
                                    fmt_lvl_2_qos_fill = fmt_lvl_2_q
                                    fmt_lvl_tbl[fmt_lvl_2_key] = fmt_lvl_2_q
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
                phase_stop_6 = min(phase_stop, arr_2_lvl_i)
                if arr_2_lvl_i == phase_stop_6
                    fmt_lvl_q = (1 - 1) * fmt_lvl.shape + phase_stop_6
                    arr_2_lvl_q_2 = arr_2_lvl_q
                    if arr_2_lvl_q < arr_2_lvl_q_step
                        arr_2_lvl_i_stop_2 = arr_2_lvl_tbl1[arr_2_lvl_q_step - 1]
                    else
                        arr_2_lvl_i_stop_2 = 0
                    end
                    phase_stop_7 = min(arr_2_lvl.shape[1], arr_2_lvl_i_stop_2)
                    if phase_stop_7 >= 1
                        if arr_2_lvl_tbl1[arr_2_lvl_q] < 1
                            arr_2_lvl_q_2 = Finch.scansearch(arr_2_lvl_tbl1, 1, arr_2_lvl_q, arr_2_lvl_q_step - 1)
                        end
                        while true
                            arr_2_lvl_i_2 = arr_2_lvl_tbl1[arr_2_lvl_q_2]
                            if arr_2_lvl_i_2 < phase_stop_7
                                arr_2_lvl_2_val_2 = arr_2_lvl_val[arr_2_lvl_q_2]
                                fmt_lvl_2_key_2 = (fmt_lvl_q, (arr_2_lvl_i_2,))
                                fmt_lvl_2_q_2 = get(fmt_lvl_tbl, fmt_lvl_2_key_2, fmt_lvl_2_qos_fill + 1)
                                if fmt_lvl_2_q_2 > fmt_lvl_2_qos_stop
                                    fmt_lvl_2_qos_stop = max(fmt_lvl_2_qos_stop << 1, 1)
                                    Finch.resize_if_smaller!(fmt_lvl_2_val, fmt_lvl_2_qos_stop)
                                    Finch.fill_range!(fmt_lvl_2_val, 0.0, fmt_lvl_2_q_2, fmt_lvl_2_qos_stop)
                                end
                                fmt_lvl_2_val[fmt_lvl_2_q_2] = arr_2_lvl_2_val_2 + fmt_lvl_2_val[fmt_lvl_2_q_2]
                                if fmt_lvl_2_q_2 > fmt_lvl_2_qos_fill
                                    fmt_lvl_2_qos_fill = fmt_lvl_2_q_2
                                    fmt_lvl_tbl[fmt_lvl_2_key_2] = fmt_lvl_2_q_2
                                    fmt_lvl_ptr[fmt_lvl_q + 1] += 1
                                end
                                arr_2_lvl_q_2 += 1
                            else
                                phase_stop_9 = min(arr_2_lvl_i_2, phase_stop_7)
                                if arr_2_lvl_i_2 == phase_stop_9
                                    arr_2_lvl_2_val_2 = arr_2_lvl_val[arr_2_lvl_q_2]
                                    fmt_lvl_2_key_2 = (fmt_lvl_q, (phase_stop_9,))
                                    fmt_lvl_2_q_2 = get(fmt_lvl_tbl, fmt_lvl_2_key_2, fmt_lvl_2_qos_fill + 1)
                                    if fmt_lvl_2_q_2 > fmt_lvl_2_qos_stop
                                        fmt_lvl_2_qos_stop = max(fmt_lvl_2_qos_stop << 1, 1)
                                        Finch.resize_if_smaller!(fmt_lvl_2_val, fmt_lvl_2_qos_stop)
                                        Finch.fill_range!(fmt_lvl_2_val, 0.0, fmt_lvl_2_q_2, fmt_lvl_2_qos_stop)
                                    end
                                    fmt_lvl_2_val[fmt_lvl_2_q_2] = arr_2_lvl_2_val_2 + fmt_lvl_2_val[fmt_lvl_2_q_2]
                                    if fmt_lvl_2_q_2 > fmt_lvl_2_qos_fill
                                        fmt_lvl_2_qos_fill = fmt_lvl_2_q_2
                                        fmt_lvl_tbl[fmt_lvl_2_key_2] = fmt_lvl_2_q_2
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
    resize!(fmt_lvl_srt, length(fmt_lvl_tbl))
    copyto!(fmt_lvl_srt, pairs(fmt_lvl_tbl))
    sort!(fmt_lvl_srt, by = hashkeycmp)
    for p = 2:fmt_lvl.shape + 1
        fmt_lvl_ptr[p] += fmt_lvl_ptr[p - 1]
    end
    qos = 1 * fmt_lvl.shape
    resize!(fmt_lvl_ptr, qos + 1)
    qos_2 = fmt_lvl_ptr[end] - 1
    resize!(fmt_lvl_srt, qos_2)
    resize!(fmt_lvl_2_val, qos_2)
    (fmt = Fiber((DenseLevel){Int32}((SparseHashLevel){1, Tuple{Int32}}(fmt_lvl_3, (fmt_lvl_2.shape[1],), fmt_lvl_ptr, fmt_lvl_tbl, fmt_lvl_srt), fmt_lvl.shape)),)
end
