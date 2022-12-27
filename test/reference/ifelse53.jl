@inbounds begin
        y = ex.body.lhs.tns.tns
        y_val = y.val
        x_lvl = (ex.body.rhs.args[1]).tns.tns.lvl
        x_lvl_pos_alloc = length(x_lvl.pos)
        x_lvl_idx_alloc = length(x_lvl.idx)
        i_stop = x_lvl.I
        y_val = 0.0
        x_lvl_q = x_lvl.pos[1]
        x_lvl_q_stop = x_lvl.pos[1 + 1]
        if x_lvl_q < x_lvl_q_stop
            x_lvl_i = x_lvl.idx[x_lvl_q]
            x_lvl_i1 = x_lvl.idx[x_lvl_q_stop - 1]
        else
            x_lvl_i = 1
            x_lvl_i1 = 0
        end
        i = 1
        i_start = i
        phase_start = max(i_start)
        phase_stop = min(x_lvl_i1, i_stop)
        if phase_stop >= phase_start
            i = i
            i = phase_start
            while x_lvl_q < x_lvl_q_stop && x_lvl.idx[x_lvl_q] < phase_start
                x_lvl_q += 1
            end
            while i <= phase_stop
                i_start_2 = i
                x_lvl_i = x_lvl.idx[x_lvl_q]
                phase_start_2 = max(i_start_2)
                phase_stop_2 = min(x_lvl_i, phase_stop)
                i_2 = i
                if x_lvl_i == phase_stop_2
                    y_val = y_val + ((phase_stop_2 - 1) + -phase_start_2 + 1) * ex.body.rhs.args[3]
                    y_val = y_val + (phase_stop_2 + -phase_stop_2 + 1) * ex.body.rhs.args[2]
                    x_lvl_q += 1
                else
                    y_val = y_val + (phase_stop_2 + -phase_start_2 + 1) * ex.body.rhs.args[3]
                end
                i = phase_stop_2 + 1
            end
            i = phase_stop + 1
        end
        i_start = i
        phase_start_3 = max(i_start)
        phase_stop_3 = min(i_stop)
        if phase_stop_3 >= phase_start_3
            i_3 = i
            y_val = y_val + (phase_stop_3 + -phase_start_3 + 1) * ex.body.rhs.args[3]
            i = phase_stop_3 + 1
        end
        (y = (Scalar){0.0, Float64}(y_val),)
    end
