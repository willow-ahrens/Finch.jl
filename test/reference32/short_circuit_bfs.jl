begin
    x_lvl = (ex.bodies[1]).tns.bind.lvl
    x_lvl_ptr = x_lvl.ptr
    x_lvl_idx = x_lvl.idx
    x_lvl_2 = x_lvl.lvl
    x_lvl_val = x_lvl.lvl.val
    A_lvl = (((ex.bodies[2]).body.bodies[2]).body.rhs.args[1]).tns.bind.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_ptr = A_lvl_2.ptr
    A_lvl_idx = A_lvl_2.idx
    A_lvl_2_val = A_lvl_2.lvl.val
    y_lvl = (((ex.bodies[2]).body.bodies[2]).body.rhs.args[2]).tns.bind.lvl
    y_lvl_ptr = y_lvl.ptr
    y_lvl_idx = y_lvl.idx
    y_lvl_val = y_lvl.lvl.val
    y_lvl.shape == A_lvl_2.shape || throw(DimensionMismatch("mismatched dimension limits ($(y_lvl.shape) != $(A_lvl_2.shape))"))
    x_lvl_qos_stop = 0
    Finch.resize_if_smaller!(x_lvl_ptr, 1 + 1)
    Finch.fill_range!(x_lvl_ptr, 0, 1 + 1, 1 + 1)
    x_lvl_qos = 0 + 1
    0 < 1 || throw(FinchProtocolError("SparseListLevels cannot be updated multiple times"))
    for j_4 = 1:A_lvl.shape
        A_lvl_q = (1 - 1) * A_lvl.shape + j_4
        if x_lvl_qos > x_lvl_qos_stop
            x_lvl_qos_stop = max(x_lvl_qos_stop << 1, 1)
            Finch.resize_if_smaller!(x_lvl_idx, x_lvl_qos_stop)
            Finch.resize_if_smaller!(x_lvl_val, x_lvl_qos_stop)
            Finch.fill_range!(x_lvl_val, false, x_lvl_qos, x_lvl_qos_stop)
        end
        x_lvldirty = false
        t_val = false
        t_dirty = false
        y_lvl_q = y_lvl_ptr[1]
        y_lvl_q_stop = y_lvl_ptr[1 + 1]
        if y_lvl_q < y_lvl_q_stop
            y_lvl_i1 = y_lvl_idx[y_lvl_q_stop - 1]
        else
            y_lvl_i1 = 0
        end
        A_lvl_2_q = A_lvl_ptr[A_lvl_q]
        A_lvl_2_q_stop = A_lvl_ptr[A_lvl_q + 1]
        if A_lvl_2_q < A_lvl_2_q_stop
            A_lvl_2_i1 = A_lvl_idx[A_lvl_2_q_stop - 1]
        else
            A_lvl_2_i1 = 0
        end
        phase_stop = min(y_lvl.shape, A_lvl_2_i1, y_lvl_i1)
        if phase_stop >= 1
            i = 1
            if y_lvl_idx[y_lvl_q] < 1
                y_lvl_q = Finch.scansearch(y_lvl_idx, 1, y_lvl_q, y_lvl_q_stop - 1)
            end
            if A_lvl_idx[A_lvl_2_q] < 1
                A_lvl_2_q = Finch.scansearch(A_lvl_idx, 1, A_lvl_2_q, A_lvl_2_q_stop - 1)
            end
            while i <= phase_stop
                if t_val == true
                    break
                end
                y_lvl_i = y_lvl_idx[y_lvl_q]
                A_lvl_2_i = A_lvl_idx[A_lvl_2_q]
                phase_stop_2 = min(y_lvl_i, A_lvl_2_i, phase_stop)
                if y_lvl_i == phase_stop_2 && A_lvl_2_i == phase_stop_2
                    A_lvl_3_val = A_lvl_2_val[A_lvl_2_q]
                    y_lvl_2_val = y_lvl_val[y_lvl_q]
                    t_dirty = true
                    t_val = t_val | (y_lvl_2_val && A_lvl_3_val)
                    y_lvl_q += 1
                    A_lvl_2_q += 1
                elseif A_lvl_2_i == phase_stop_2
                    A_lvl_2_q += 1
                elseif y_lvl_i == phase_stop_2
                    y_lvl_q += 1
                end
                i = phase_stop_2 + 1
            end
        end
        if t_dirty
            x_lvldirty = true
            x_lvl_val[x_lvl_qos] = t_val
        end
        if x_lvldirty
            x_lvl_idx[x_lvl_qos] = j_4
            x_lvl_qos += 1
        end
    end
    x_lvl_ptr[1 + 1] += (x_lvl_qos - 0) - 1
    for p = 1:1
        x_lvl_ptr[p + 1] += x_lvl_ptr[p]
    end
    resize!(x_lvl_ptr, 1 + 1)
    qos = x_lvl_ptr[end] - 1
    resize!(x_lvl_idx, qos)
    resize!(x_lvl_val, qos)
    (x = Fiber((SparseListLevel){Int32}(x_lvl_2, A_lvl.shape, x_lvl_ptr, x_lvl_idx)),)
end
