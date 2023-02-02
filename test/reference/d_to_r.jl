begin
    A_lvl = ex.body.lhs.tns.tns.lvl
    C = ex.body.rhs.tns.tns
    (C_mode1_stop,) = size(C)
    A_lvl.pos[1] = 1
    A_lvl_ros_fill = 0
    A_lvl_qos_stop = 0
    (Finch.resize_if_smaller!)(A_lvl.pos, 1 + 1)
    (Finch.fill_range!)(A_lvl.pos, 1, 1 + 1, 1 + 1)
    A_lvl_q = A_lvl_ros_fill + 1
    A_lvl_i_prev = 0
    A_lvl_v_prev = 0.0
    for i = 1:C_mode1_stop
        if A_lvl_v_prev != 0.0 && A_lvl_i_prev + 1 < i
            A_lvl_dirty = true
            if A_lvl_q > A_lvl_qos_stop
                A_lvlqos_fill = A_lvl_qos_stop
                A_lvl_qos_stop = max(A_lvl_qos_stop << 1, A_lvl_q)
                (Finch.resize_if_smaller!)(A_lvl.idx, A_lvl_qos_stop)
                (Finch.fill_range!)(A_lvl.idx, C_mode1_stop, A_lvlqos_fill + 1, A_lvl_qos_stop)
                (Finch.resize_if_smaller!)(A_lvl.val, A_lvl_qos_stop)
                (Finch.fill_range!)(A_lvl.val, 0.0, A_lvlqos_fill + 1, A_lvl_qos_stop)
            end
            A_lvl_dirty = true
            A_lvl.idx[A_lvl_q] = A_lvl_i_prev
            A_lvl.val[A_lvl_q] = A_lvl_v_prev
            A_lvl_q += 1
            A_lvl_v_prev = 0.0
        end
        A_lvl_i_prev = i - 1
        A_lvl_v = 0.0
        A_lvl_v = C[i]
        if A_lvl_v_prev != A_lvl_v && A_lvl_i_prev > 0
            if A_lvl_q > A_lvl_qos_stop
                A_lvlqos_fill = A_lvl_qos_stop
                A_lvl_qos_stop = max(A_lvl_qos_stop << 1, A_lvl_q)
                (Finch.resize_if_smaller!)(A_lvl.idx, A_lvl_qos_stop)
                (Finch.fill_range!)(A_lvl.idx, C_mode1_stop, A_lvlqos_fill + 1, A_lvl_qos_stop)
                (Finch.resize_if_smaller!)(A_lvl.val, A_lvl_qos_stop)
                (Finch.fill_range!)(A_lvl.val, 0.0, A_lvlqos_fill + 1, A_lvl_qos_stop)
            end
            A_lvl_dirty = true
            A_lvl.idx[A_lvl_q] = A_lvl_i_prev
            A_lvl.val[A_lvl_q] = A_lvl_v_prev
            A_lvl_q += 1
        end
        A_lvl_v_prev = A_lvl_v
        A_lvl_i_prev = i
    end
    if A_lvl_v_prev != 0.0
        if A_lvl_i_prev < C_mode1_stop
            if A_lvl_q > A_lvl_qos_stop
                A_lvlqos_fill = A_lvl_qos_stop
                A_lvl_qos_stop = max(A_lvl_qos_stop << 1, A_lvl_q)
                (Finch.resize_if_smaller!)(A_lvl.idx, A_lvl_qos_stop)
                (Finch.fill_range!)(A_lvl.idx, C_mode1_stop, A_lvlqos_fill + 1, A_lvl_qos_stop)
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
                (Finch.fill_range!)(A_lvl.idx, C_mode1_stop, A_lvlqos_fill + 1, A_lvl_qos_stop)
                (Finch.resize_if_smaller!)(A_lvl.val, A_lvl_qos_stop)
                (Finch.fill_range!)(A_lvl.val, 0.0, A_lvlqos_fill + 1, A_lvl_qos_stop)
            end
            A_lvl_dirty = true
            A_lvl.idx[A_lvl_q] = C_mode1_stop
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
    (Finch.fill_range!)(A_lvl.idx, C_mode1_stop, A_lvl_qos_stop + 1, qos_stop)
    (Finch.resize_if_smaller!)(A_lvl.val, qos_stop)
    (Finch.fill_range!)(A_lvl.val, 0.0, A_lvl_qos_stop + 1, qos_stop)
    resize!(A_lvl.pos, 1 + 1)
    qos = A_lvl.pos[end] - 1
    resize!(A_lvl.idx, qos)
    resize!(A_lvl.val, qos)
    (A = Fiber((Finch.RepeatRLELevel){0.0, Int64, Int64, Float64}(C_mode1_stop, A_lvl.pos, A_lvl.idx, A_lvl.val), (Environment)(; )),)
end
