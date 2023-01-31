begin
    A_lvl = ex.body.lhs.tns.tns.lvl
    D_lvl = ex.body.rhs.tns.tns.lvl
    D_lvl_2 = D_lvl.lvl
    D_lvl_2_val = 0
    A_lvl.pos[1] = 1
    A_lvl_ros_fill = 0
    A_lvl_qos_stop = 0
    (Finch.resize_if_smaller!)(A_lvl.pos, 1 + 1)
    (Finch.fill_range!)(A_lvl.pos, 1, 1 + 1, 1 + 1)
    A_lvl_q = A_lvl_ros_fill + 1
    A_lvl_i_prev = 0
    A_lvl_v_prev = 0.0
    D_lvl_q = D_lvl.pos[1]
    D_lvl_q_stop = D_lvl.pos[1 + 1]
    D_lvl_i = if D_lvl_q < D_lvl_q_stop
            D_lvl.idx[D_lvl_q]
        else
            1
        end
    D_lvl_i1 = if D_lvl_q < D_lvl_q_stop
            D_lvl.idx[D_lvl_q_stop - 1]
        else
            0
        end
    i = 1
    i_start = i
    phase_stop = (min)(D_lvl_i1, D_lvl.I)
    if phase_stop >= i_start
        i = i
        i = i_start
        while D_lvl_q + 1 < D_lvl_q_stop && D_lvl.idx[D_lvl_q] < i_start
            D_lvl_q += 1
        end
        while i <= phase_stop
            i_start_2 = i
            D_lvl_i = D_lvl.idx[D_lvl_q]
            phase_stop_2 = (min)(D_lvl_i, phase_stop)
            i_2 = i
            if D_lvl_i == phase_stop_2
                D_lvl_2_val = D_lvl_2.val[D_lvl_q]
                if A_lvl_v_prev != 0.0 && A_lvl_i_prev + 1 < phase_stop_2
                    A_lvl_dirty = true
                    if A_lvl_q > A_lvl_qos_stop
                        A_lvlqos_fill = A_lvl_qos_stop
                        A_lvl_qos_stop = max(A_lvl_qos_stop << 1, A_lvl_q)
                        (Finch.resize_if_smaller!)(A_lvl.idx, A_lvl_qos_stop)
                        (Finch.fill_range!)(A_lvl.idx, D_lvl.I, A_lvlqos_fill + 1, A_lvl_qos_stop)
                        (Finch.resize_if_smaller!)(A_lvl.val, A_lvl_qos_stop)
                        (Finch.fill_range!)(A_lvl.val, 0.0, A_lvlqos_fill + 1, A_lvl_qos_stop)
                    end
                    A_lvl_dirty = true
                    A_lvl.idx[A_lvl_q] = A_lvl_i_prev
                    A_lvl.val[A_lvl_q] = A_lvl_v_prev
                    A_lvl_q += 1
                    A_lvl_v_prev = 0.0
                end
                A_lvl_i_prev = phase_stop_2 - 1
                A_lvl_v = 0.0
                A_lvl_v = D_lvl_2_val
                if A_lvl_v_prev != A_lvl_v && A_lvl_i_prev > 0
                    if A_lvl_q > A_lvl_qos_stop
                        A_lvlqos_fill = A_lvl_qos_stop
                        A_lvl_qos_stop = max(A_lvl_qos_stop << 1, A_lvl_q)
                        (Finch.resize_if_smaller!)(A_lvl.idx, A_lvl_qos_stop)
                        (Finch.fill_range!)(A_lvl.idx, D_lvl.I, A_lvlqos_fill + 1, A_lvl_qos_stop)
                        (Finch.resize_if_smaller!)(A_lvl.val, A_lvl_qos_stop)
                        (Finch.fill_range!)(A_lvl.val, 0.0, A_lvlqos_fill + 1, A_lvl_qos_stop)
                    end
                    A_lvl_dirty = true
                    A_lvl.idx[A_lvl_q] = A_lvl_i_prev
                    A_lvl.val[A_lvl_q] = A_lvl_v_prev
                    A_lvl_q += 1
                end
                A_lvl_v_prev = A_lvl_v
                A_lvl_i_prev = phase_stop_2
                D_lvl_q += 1
            else
            end
            i = phase_stop_2 + 1
        end
        i = phase_stop + 1
    end
    i_start = i
    if D_lvl.I >= i_start
        i_3 = i
        i = D_lvl.I + 1
    end
    if A_lvl_v_prev != 0.0
        if A_lvl_i_prev < D_lvl.I
            if A_lvl_q > A_lvl_qos_stop
                A_lvlqos_fill = A_lvl_qos_stop
                A_lvl_qos_stop = max(A_lvl_qos_stop << 1, A_lvl_q)
                (Finch.resize_if_smaller!)(A_lvl.idx, A_lvl_qos_stop)
                (Finch.fill_range!)(A_lvl.idx, D_lvl.I, A_lvlqos_fill + 1, A_lvl_qos_stop)
                (Finch.resize_if_smaller!)(A_lvl.val, A_lvl_qos_stop)
                (Finch.fill_range!)(A_lvl.val, 0.0, A_lvlqos_fill + 1, A_lvl_qos_stop)
            end
            A_lvl_dirty = true
            A_lvl.idx[A_lvl_q] = A_lvl_i_prev
            A_lvl.val[A_lvl_q] = A_lvl_v_prev
            A_lvl_q += 1
        else
            if A_lvl_q > A_lvl_qos_stop
                A_lvlqos_fill = A_lvl_qos_stop
                A_lvl_qos_stop = max(A_lvl_qos_stop << 1, A_lvl_q)
                (Finch.resize_if_smaller!)(A_lvl.idx, A_lvl_qos_stop)
                (Finch.fill_range!)(A_lvl.idx, D_lvl.I, A_lvlqos_fill + 1, A_lvl_qos_stop)
                (Finch.resize_if_smaller!)(A_lvl.val, A_lvl_qos_stop)
                (Finch.fill_range!)(A_lvl.val, 0.0, A_lvlqos_fill + 1, A_lvl_qos_stop)
            end
            A_lvl_dirty = true
            A_lvl.idx[A_lvl_q] = D_lvl.I
            A_lvl.val[A_lvl_q] = A_lvl_v_prev
            A_lvl_q += 1
        end
    end
    A_lvl.pos[1 + 1] += A_lvl_q - (A_lvl_ros_fill + 1)
    A_lvl_ros_fill += A_lvl_q - (A_lvl_ros_fill + 1)
    for p = 2:1 + 1
        A_lvl.pos[p] += A_lvl.pos[p - 1]
    end
    qos_stop = A_lvl.pos[1 + 1] - 1
    (Finch.resize_if_smaller!)(A_lvl.idx, qos_stop)
    (Finch.fill_range!)(A_lvl.idx, D_lvl.I, A_lvl_qos_stop + 1, qos_stop)
    (Finch.resize_if_smaller!)(A_lvl.val, qos_stop)
    (Finch.fill_range!)(A_lvl.val, 0.0, A_lvl_qos_stop + 1, qos_stop)
    resize!(A_lvl.pos, 1 + 1)
    qos = A_lvl.pos[end] - 1
    resize!(A_lvl.idx, qos)
    resize!(A_lvl.val, qos)
    (A = Fiber((Finch.RepeatRLELevel){0.0, Int64, Int64, Float64}(D_lvl.I, A_lvl.pos, A_lvl.idx, A_lvl.val), (Environment)(; )),)
end
