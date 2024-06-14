begin
    x = (ex.bodies[1]).body.lhs.tns.bind
    x_val = x.val
    yf_lvl = ((ex.bodies[1]).body.rhs.args[1]).tns.bind.lvl
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
        if yf_lvl_idx[yf_lvl_q] < 1
            yf_lvl_q = Finch.scansearch(yf_lvl_idx, 1, yf_lvl_q, yf_lvl_q_stop - 1)
        end
        while true
            yf_lvl_i = yf_lvl_idx[yf_lvl_q]
            if yf_lvl_i < phase_stop
                yf_lvl_2_val = yf_lvl_val[yf_lvl_q]
                x_val = min(something(yf_lvl_2_val, Inf), x_val)
                yf_lvl_q += 1
            else
                phase_stop_3 = min(phase_stop, yf_lvl_i)
                if yf_lvl_i == phase_stop_3
                    yf_lvl_2_val = yf_lvl_val[yf_lvl_q]
                    x_val = min(x_val, something(yf_lvl_2_val, Inf))
                    yf_lvl_q += 1
                end
                break
            end
        end
    end
    result = ()
    x.val = x_val
    result
end
