begin
    x = ex.body.lhs.tns.bind
    x_val = x.val
    yf_lvl = ex.body.rhs.tns.bind.lvl
    yf_lvl_ptr = yf_lvl.ptr
    yf_lvl_idx = yf_lvl.idx
    yf_lvl_val = yf_lvl.lvl.val
    yf_lvl_q = yf_lvl_ptr[1]
    yf_lvl_q_stop = yf_lvl_ptr[1 + 1]
    if yf_lvl_q < yf_lvl_q_stop
        yf_lvl_i1 = yf_lvl_idx[yf_lvl_q_stop - 1]
    else
        yf_lvl_i1 = 0
    end
    phase_stop = min(yf_lvl_i1, yf_lvl.shape)
    if phase_stop >= 1
        i = 1
        if yf_lvl_idx[yf_lvl_q] < 1
            yf_lvl_q = Finch.scansearch(yf_lvl_idx, 1, yf_lvl_q, yf_lvl_q_stop - 1)
        end
        while i <= phase_stop
            yf_lvl_i = yf_lvl_idx[yf_lvl_q]
            phase_stop_2 = min(phase_stop, yf_lvl_i)
            if yf_lvl_i == phase_stop_2
                cond = 0 < -i + phase_stop_2
                if cond
                    x_val = min(NaN, x_val)
                end
                yf_lvl_2_val = yf_lvl_val[yf_lvl_q]
                x_val = min(x_val, yf_lvl_2_val)
                yf_lvl_q += 1
            else
                cond_3 = 0 < 1 + -i + phase_stop_2
                if cond_3
                    x_val = min(NaN, x_val)
                end
            end
            i = phase_stop_2 + 1
        end
    end
    phase_start_3 = max(1, 1 + yf_lvl_i1)
    phase_stop_3 = yf_lvl.shape
    if phase_stop_3 >= phase_start_3
        cond_4 = 0 < 1 + -phase_start_3 + phase_stop_3
        if cond_4
            x_val = min(NaN, x_val)
        end
    end
    (x = (Scalar){Inf, Float64}(x_val),)
end
