begin
    fmt_lvl = (ex.bodies[1]).body.body.lhs.tns.bind.lvl
    fmt_lvl_2 = fmt_lvl.lvl
    fmt_lvl_tbl = fmt_lvl_2.tbl
    fmt_lvl_2_val = fmt_lvl_2.lvl.val
    arr_2_lvl = (ex.bodies[1]).body.body.rhs.tns.bind.lvl
    arr_2_lvl_ptr = (ex.bodies[1]).body.body.rhs.tns.bind.lvl.ptr
    arr_2_lvl_tbl1 = (ex.bodies[1]).body.body.rhs.tns.bind.lvl.tbl[1]
    arr_2_lvl_tbl2 = (ex.bodies[1]).body.body.rhs.tns.bind.lvl.tbl[2]
    arr_2_lvl_val = arr_2_lvl.lvl.val
    arr_2_lvl.shape[1] == fmt_lvl_2.shape || throw(DimensionMismatch("mismatched dimension limits ($(arr_2_lvl.shape[1]) != $(fmt_lvl_2.shape))"))
    arr_2_lvl.shape[2] == fmt_lvl.shape || throw(DimensionMismatch("mismatched dimension limits ($(arr_2_lvl.shape[2]) != $(fmt_lvl.shape))"))
    fmt_lvl_qos_stop = Finch.thaw_table!(fmt_lvl_tbl, fmt_lvl.shape)
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
                fmt_lvl_2_subtbl = Finch.table_register(fmt_lvl_tbl, fmt_lvl_q)
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
                            fmt_lvl_2_qos = Finch.subtable_register(fmt_lvl_tbl, fmt_lvl_2_subtbl, arr_2_lvl_i_2)
                            if fmt_lvl_2_qos > fmt_lvl_qos_stop
                                fmt_lvl_qos_stop = max(fmt_lvl_qos_stop << 1, 1)
                                Finch.resize_if_smaller!(fmt_lvl_2_val, fmt_lvl_qos_stop)
                                Finch.fill_range!(fmt_lvl_2_val, 0.0, fmt_lvl_2_qos, fmt_lvl_qos_stop)
                            end
                            fmt_lvl_2_val[fmt_lvl_2_qos] = arr_2_lvl_2_val + fmt_lvl_2_val[fmt_lvl_2_qos]
                            Finch.subtable_commit!(fmt_lvl_tbl, fmt_lvl_2_subtbl, fmt_lvl_2_qos, arr_2_lvl_i_2)
                            arr_2_lvl_q_2 += 1
                        else
                            phase_stop_5 = min(arr_2_lvl_i_2, phase_stop_3)
                            if arr_2_lvl_i_2 == phase_stop_5
                                arr_2_lvl_2_val = arr_2_lvl_val[arr_2_lvl_q_2]
                                fmt_lvl_2_qos = Finch.subtable_register(fmt_lvl_tbl, fmt_lvl_2_subtbl, phase_stop_5)
                                if fmt_lvl_2_qos > fmt_lvl_qos_stop
                                    fmt_lvl_qos_stop = max(fmt_lvl_qos_stop << 1, 1)
                                    Finch.resize_if_smaller!(fmt_lvl_2_val, fmt_lvl_qos_stop)
                                    Finch.fill_range!(fmt_lvl_2_val, 0.0, fmt_lvl_2_qos, fmt_lvl_qos_stop)
                                end
                                fmt_lvl_2_val[fmt_lvl_2_qos] = arr_2_lvl_2_val + fmt_lvl_2_val[fmt_lvl_2_qos]
                                Finch.subtable_commit!(fmt_lvl_tbl, fmt_lvl_2_subtbl, fmt_lvl_2_qos, phase_stop_5)
                                arr_2_lvl_q_2 += 1
                            end
                            break
                        end
                    end
                end
                Finch.table_commit!(fmt_lvl_tbl, fmt_lvl_q)
                arr_2_lvl_q = arr_2_lvl_q_step
            else
                phase_stop_7 = min(arr_2_lvl_i, phase_stop)
                if arr_2_lvl_i == phase_stop_7
                    fmt_lvl_q = (1 - 1) * fmt_lvl.shape + phase_stop_7
                    fmt_lvl_2_subtbl_2 = Finch.table_register(fmt_lvl_tbl, fmt_lvl_q)
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
                                fmt_lvl_2_qos_2 = Finch.subtable_register(fmt_lvl_tbl, fmt_lvl_2_subtbl_2, arr_2_lvl_i_2)
                                if fmt_lvl_2_qos_2 > fmt_lvl_qos_stop
                                    fmt_lvl_qos_stop = max(fmt_lvl_qos_stop << 1, 1)
                                    Finch.resize_if_smaller!(fmt_lvl_2_val, fmt_lvl_qos_stop)
                                    Finch.fill_range!(fmt_lvl_2_val, 0.0, fmt_lvl_2_qos_2, fmt_lvl_qos_stop)
                                end
                                fmt_lvl_2_val[fmt_lvl_2_qos_2] = arr_2_lvl_2_val_2 + fmt_lvl_2_val[fmt_lvl_2_qos_2]
                                Finch.subtable_commit!(fmt_lvl_tbl, fmt_lvl_2_subtbl_2, fmt_lvl_2_qos_2, arr_2_lvl_i_2)
                                arr_2_lvl_q_2 += 1
                            else
                                phase_stop_10 = min(arr_2_lvl_i_2, phase_stop_8)
                                if arr_2_lvl_i_2 == phase_stop_10
                                    arr_2_lvl_2_val_2 = arr_2_lvl_val[arr_2_lvl_q_2]
                                    fmt_lvl_2_qos_2 = Finch.subtable_register(fmt_lvl_tbl, fmt_lvl_2_subtbl_2, phase_stop_10)
                                    if fmt_lvl_2_qos_2 > fmt_lvl_qos_stop
                                        fmt_lvl_qos_stop = max(fmt_lvl_qos_stop << 1, 1)
                                        Finch.resize_if_smaller!(fmt_lvl_2_val, fmt_lvl_qos_stop)
                                        Finch.fill_range!(fmt_lvl_2_val, 0.0, fmt_lvl_2_qos_2, fmt_lvl_qos_stop)
                                    end
                                    fmt_lvl_2_val[fmt_lvl_2_qos_2] = arr_2_lvl_2_val_2 + fmt_lvl_2_val[fmt_lvl_2_qos_2]
                                    Finch.subtable_commit!(fmt_lvl_tbl, fmt_lvl_2_subtbl_2, fmt_lvl_2_qos_2, phase_stop_10)
                                    arr_2_lvl_q_2 += 1
                                end
                                break
                            end
                        end
                    end
                    Finch.table_commit!(fmt_lvl_tbl, fmt_lvl_q)
                    arr_2_lvl_q = arr_2_lvl_q_step
                end
                break
            end
        end
    end
    result = ()
    qos_stop = Finch.freeze_table!(fmt_lvl_tbl, fmt_lvl.shape)
    resize!(fmt_lvl_2_val, qos_stop)
    result
end
