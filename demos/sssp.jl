using Finch
using Finch.IndexNotation
using RewriteTools
using BenchmarkTools
using SparseArrays
using LinearAlgebra
using SparseArrays
using MatrixMarket

or(x,y) = x == 1|| y == 1

function choose(x, y)
    if x != 0
        return x
    else
        return y
    end
end

@slots a b c d e i j Finch.add_rules!([
    (@rule @f(@chunk $i a (b[j...] <<min>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<min>>= $d)
    end),

    (@rule @f(@chunk $i a @multi b... (c[j...] <<min>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @f @multi (c[j...] <<min>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),

    (@rule @f(@chunk $i a (b[j...] <<$or>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<$or>>= $d)
    end),

    (@rule @f(@chunk $i a @multi b... (c[j...] <<$or>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @f @multi (c[j...] <<$or>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),
])

Finch.register()

function dist_update1(B, dist, weights, priorityQ, priority)
    #= none:17 =#
    #= none:18 =#
    println("IN")
    #= none:19 =#
    println(B.lvl.lvl.val)
    #= none:20 =#
    println(dist.lvl.lvl.val)
    #= none:21 =#
    println(weights.lvl.lvl.lvl.val)
    #= none:22 =#
    println(priorityQ.lvl.lvl.lvl.val)
    #= none:23 =#
    begin
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/denselevels.jl:67 =#
            tns_lvl = weights.lvl
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/sparselistlevels.jl:87 =#
            tns_lvl_2 = tns_lvl.lvl
            #= /Users/adadima/mit/commit/Finch.jl/src/sparselistlevels.jl:88 =#
            tns_lvl_2_pos_alloc = length(tns_lvl_2.pos)
            #= /Users/adadima/mit/commit/Finch.jl/src/sparselistlevels.jl:89 =#
            tns_lvl_2_idx_alloc = length(tns_lvl_2.idx)
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:57 =#
            tns_lvl_3 = tns_lvl_2.lvl
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:58 =#
            tns_lvl_3_val_alloc = length(tns_lvl_2.lvl.val)
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:59 =#
            tns_lvl_3_val = 0
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/denselevels.jl:67 =#
            tns_2_lvl = priorityQ.lvl
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/sparselistlevels.jl:87 =#
            tns_2_lvl_2 = tns_2_lvl.lvl
            #= /Users/adadima/mit/commit/Finch.jl/src/sparselistlevels.jl:88 =#
            tns_2_lvl_2_pos_alloc = length(tns_2_lvl_2.pos)
            #= /Users/adadima/mit/commit/Finch.jl/src/sparselistlevels.jl:89 =#
            tns_2_lvl_2_idx_alloc = length(tns_2_lvl_2.idx)
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:57 =#
            tns_2_lvl_3 = tns_2_lvl_2.lvl
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:58 =#
            tns_2_lvl_3_val_alloc = length(tns_2_lvl_2.lvl.val)
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:59 =#
            tns_2_lvl_3_val = 0
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/denselevels.jl:67 =#
            tns_3_lvl = dist.lvl
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:57 =#
            tns_3_lvl_2 = tns_3_lvl.lvl
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:58 =#
            tns_3_lvl_2_val_alloc = length(tns_3_lvl.lvl.val)
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:59 =#
            tns_3_lvl_2_val = 0
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/denselevels.jl:67 =#
            tns_4_lvl = B.lvl
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:57 =#
            tns_4_lvl_2 = tns_4_lvl.lvl
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:58 =#
            tns_4_lvl_2_val_alloc = length(tns_4_lvl.lvl.val)
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:59 =#
            tns_4_lvl_2_val = 0
        end
        @inbounds begin
                j_stop = tns_lvl.I
                k_stop = tns_lvl_2.I
                tns_4_lvl_2_val_alloc = (Finch).refill!(tns_4_lvl_2.val, 0, 0, 4)
                tns_4_lvl_2_val_alloc < 1 * tns_lvl.I && (tns_4_lvl_2_val_alloc = (Finch).refill!(tns_4_lvl_2.val, 0, tns_4_lvl_2_val_alloc, 1 * tns_lvl.I))
                j_stop_2 = j_stop
                k_stop_2 = k_stop
                s_stop = tns_2_lvl.I
                select_s = priority
                s = 1
                s_start = s
                phase_start = max(s_start)
                phase_stop = min(select_s - 1, s_stop)
                if phase_stop >= phase_start
                    s_2 = s
                    s = phase_stop + 1
                end
                s_start = s
                phase_start_2 = max(s_start)
                phase_stop_2 = min(select_s, s_stop)
                if phase_stop_2 >= phase_start_2
                    s_3 = s
                    for s_4 = phase_start_2:phase_stop_2
                        tns_2_lvl_q = (1 - 1) * tns_2_lvl.I + s_4
                        for j = 1:j_stop_2
                            tns_4_lvl_q = (1 - 1) * j_stop + j
                            tns_lvl_q = (1 - 1) * tns_lvl.I + j
                            tns_lvl_q_2 = (1 - 1) * tns_lvl.I + j
                            tns_4_lvl_2_val = tns_4_lvl_2.val[tns_4_lvl_q]
                            println(tns_4_lvl_2.val)
                            tns_lvl_2_q = tns_lvl_2.pos[tns_lvl_q]
                            tns_lvl_2_q_stop = tns_lvl_2.pos[tns_lvl_q + 1]
                            if tns_lvl_2_q < tns_lvl_2_q_stop
                                tns_lvl_2_i = tns_lvl_2.idx[tns_lvl_2_q]
                                tns_lvl_2_i1 = tns_lvl_2.idx[tns_lvl_2_q_stop - 1]
                            else
                                tns_lvl_2_i = 1
                                tns_lvl_2_i1 = 0
                            end
                            tns_2_lvl_2_q = tns_2_lvl_2.pos[tns_2_lvl_q]
                            tns_2_lvl_2_q_stop = tns_2_lvl_2.pos[tns_2_lvl_q + 1]
                            if tns_2_lvl_2_q < tns_2_lvl_2_q_stop
                                tns_2_lvl_2_i = tns_2_lvl_2.idx[tns_2_lvl_2_q]
                                tns_2_lvl_2_i1 = tns_2_lvl_2.idx[tns_2_lvl_2_q_stop - 1]
                            else
                                tns_2_lvl_2_i = 1
                                tns_2_lvl_2_i1 = 0
                            end
                            tns_lvl_2_q_2 = tns_lvl_2.pos[tns_lvl_q_2]
                            tns_lvl_2_q_stop_2 = tns_lvl_2.pos[tns_lvl_q_2 + 1]
                            if tns_lvl_2_q_2 < tns_lvl_2_q_stop_2
                                tns_lvl_2_i_2 = tns_lvl_2.idx[tns_lvl_2_q_2]
                                tns_lvl_2_i1_2 = tns_lvl_2.idx[tns_lvl_2_q_stop_2 - 1]
                            else
                                tns_lvl_2_i_2 = 1
                                tns_lvl_2_i1_2 = 0
                            end
                            k = 1
                            k_start = k
                            phase_start_3 = max(k_start)
                            phase_stop_3 = min(tns_2_lvl_2_i1, tns_lvl_2_i1, tns_lvl_2_i1_2, k_stop_2)
                            if phase_stop_3 >= phase_start_3
                                k = k
                                k = phase_start_3
                                while tns_lvl_2_q < tns_lvl_2_q_stop && tns_lvl_2.idx[tns_lvl_2_q] < phase_start_3
                                    tns_lvl_2_q += 1
                                end
                                while tns_2_lvl_2_q < tns_2_lvl_2_q_stop && tns_2_lvl_2.idx[tns_2_lvl_2_q] < phase_start_3
                                    tns_2_lvl_2_q += 1
                                end
                                while tns_lvl_2_q_2 < tns_lvl_2_q_stop_2 && tns_lvl_2.idx[tns_lvl_2_q_2] < phase_start_3
                                    tns_lvl_2_q_2 += 1
                                end
                                while k <= phase_stop_3
                                    k_start_2 = k
                                    tns_lvl_2_i = tns_lvl_2.idx[tns_lvl_2_q]
                                    tns_2_lvl_2_i = tns_2_lvl_2.idx[tns_2_lvl_2_q]
                                    tns_lvl_2_i_2 = tns_lvl_2.idx[tns_lvl_2_q_2]
                                    phase_start_4 = max(k_start_2)
                                    phase_stop_4 = min(tns_2_lvl_2_i, tns_lvl_2_i, tns_lvl_2_i_2, phase_stop_3)
                                    if phase_stop_4 >= phase_start_4
                                        k_2 = k
                                        if (tns_lvl_2_i == phase_stop_4 && tns_2_lvl_2_i == phase_stop_4) && tns_lvl_2_i_2 == phase_stop_4
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_lvl_3_val = tns_lvl_3.val[tns_lvl_2_q]
                                            tns_2_lvl_3_val = tns_2_lvl_3.val[tns_2_lvl_2_q]
                                            tns_lvl_3_val = tns_lvl_3.val[tns_lvl_2_q_2]
                                            k_3 = phase_stop_4
                                            tns_3_lvl_q = (1 - 1) * tns_3_lvl.I + k_3
                                            tns_3_lvl_2_val = tns_3_lvl_2.val[tns_3_lvl_q]
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, ifelse(tns_lvl_3_val * tns_2_lvl_3_val != 0, tns_lvl_3_val + tns_3_lvl_2_val, 5))
                                            tns_lvl_2_q += 1
                                            tns_2_lvl_2_q += 1
                                            tns_lvl_2_q_2 += 1
                                        elseif tns_2_lvl_2_i == phase_stop_4 && tns_lvl_2_i_2 == phase_stop_4
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_2_lvl_3_val = tns_2_lvl_3.val[tns_2_lvl_2_q]
                                            tns_lvl_3_val = tns_lvl_3.val[tns_lvl_2_q_2]
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_2_lvl_2_q += 1
                                            tns_lvl_2_q_2 += 1
                                        elseif tns_lvl_2_i == phase_stop_4 && tns_lvl_2_i_2 == phase_stop_4
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_lvl_3_val = tns_lvl_3.val[tns_lvl_2_q]
                                            tns_lvl_3_val = tns_lvl_3.val[tns_lvl_2_q_2]
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_lvl_2_q += 1
                                            tns_lvl_2_q_2 += 1
                                        elseif tns_lvl_2_i_2 == phase_stop_4
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_lvl_3_val = tns_lvl_3.val[tns_lvl_2_q_2]
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_lvl_2_q_2 += 1
                                        elseif tns_lvl_2_i == phase_stop_4 && tns_2_lvl_2_i == phase_stop_4
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_lvl_3_val = tns_lvl_3.val[tns_lvl_2_q]
                                            tns_2_lvl_3_val = tns_2_lvl_3.val[tns_2_lvl_2_q]
                                            k_4 = phase_stop_4
                                            tns_3_lvl_q = (1 - 1) * tns_3_lvl.I + k_4
                                            tns_3_lvl_2_val = tns_3_lvl_2.val[tns_3_lvl_q]
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, ifelse(tns_lvl_3_val * tns_2_lvl_3_val != 0, tns_3_lvl_2_val, 5))
                                            tns_lvl_2_q += 1
                                            tns_2_lvl_2_q += 1
                                        elseif tns_2_lvl_2_i == phase_stop_4
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_2_lvl_3_val = tns_2_lvl_3.val[tns_2_lvl_2_q]
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_2_lvl_2_q += 1
                                        elseif tns_lvl_2_i == phase_stop_4
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_lvl_3_val = tns_lvl_3.val[tns_lvl_2_q]
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_lvl_2_q += 1
                                        else
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                        end
                                        k = phase_stop_4 + 1
                                    end
                                end
                                k = phase_stop_3 + 1
                            end
                            k_start = k
                            phase_start_5 = max(k_start)
                            phase_stop_5 = min(tns_2_lvl_2_i1, tns_lvl_2_i1, k_stop_2)
                            if phase_stop_5 >= phase_start_5
                                k_5 = k
                                k = phase_start_5
                                while tns_lvl_2_q < tns_lvl_2_q_stop && tns_lvl_2.idx[tns_lvl_2_q] < phase_start_5
                                    tns_lvl_2_q += 1
                                end
                                while tns_2_lvl_2_q < tns_2_lvl_2_q_stop && tns_2_lvl_2.idx[tns_2_lvl_2_q] < phase_start_5
                                    tns_2_lvl_2_q += 1
                                end
                                while k <= phase_stop_5
                                    k_start_3 = k
                                    tns_lvl_2_i = tns_lvl_2.idx[tns_lvl_2_q]
                                    tns_2_lvl_2_i = tns_2_lvl_2.idx[tns_2_lvl_2_q]
                                    phase_start_6 = max(k_start_3)
                                    phase_stop_6 = min(tns_2_lvl_2_i, tns_lvl_2_i, phase_stop_5)
                                    if phase_stop_6 >= phase_start_6
                                        k_6 = k
                                        if tns_lvl_2_i == phase_stop_6 && tns_2_lvl_2_i == phase_stop_6
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_lvl_3_val = tns_lvl_3.val[tns_lvl_2_q]
                                            tns_2_lvl_3_val = tns_2_lvl_3.val[tns_2_lvl_2_q]
                                            k_7 = phase_stop_6
                                            tns_3_lvl_q = (1 - 1) * tns_3_lvl.I + k_7
                                            tns_3_lvl_2_val = tns_3_lvl_2.val[tns_3_lvl_q]
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, ifelse(tns_lvl_3_val * tns_2_lvl_3_val != 0, tns_3_lvl_2_val, 5))
                                            tns_lvl_2_q += 1
                                            tns_2_lvl_2_q += 1
                                        elseif tns_2_lvl_2_i == phase_stop_6
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_2_lvl_3_val = tns_2_lvl_3.val[tns_2_lvl_2_q]
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_2_lvl_2_q += 1
                                        elseif tns_lvl_2_i == phase_stop_6
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_lvl_3_val = tns_lvl_3.val[tns_lvl_2_q]
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                            tns_lvl_2_q += 1
                                        else
                                            tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                        end
                                        k = phase_stop_6 + 1
                                    end
                                end
                                k = phase_stop_5 + 1
                            end
                            k_start = k
                            phase_start_7 = max(k_start)
                            phase_stop_7 = min(tns_lvl_2_i1, tns_lvl_2_i1_2, k_stop_2)
                            if phase_stop_7 >= phase_start_7
                                k_8 = k
                                tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                k = phase_stop_7 + 1
                            end
                            k_start = k
                            phase_start_8 = max(k_start)
                            phase_stop_8 = min(tns_lvl_2_i1, k_stop_2)
                            if phase_stop_8 >= phase_start_8
                                k_9 = k
                                tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                k = phase_stop_8 + 1
                            end
                            k_start = k
                            phase_start_9 = max(k_start)
                            phase_stop_9 = min(tns_2_lvl_2_i1, tns_lvl_2_i1_2, k_stop_2)
                            if phase_stop_9 >= phase_start_9
                                k_10 = k
                                tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                k = phase_stop_9 + 1
                            end
                            k_start = k
                            phase_start_10 = max(k_start)
                            phase_stop_10 = min(tns_2_lvl_2_i1, k_stop_2)
                            if phase_stop_10 >= phase_start_10
                                k_11 = k
                                tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                k = phase_stop_10 + 1
                            end
                            k_start = k
                            phase_start_11 = max(k_start)
                            phase_stop_11 = min(tns_lvl_2_i1_2, k_stop_2)
                            if phase_stop_11 >= phase_start_11
                                k_12 = k
                                tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                k = phase_stop_11 + 1
                            end
                            k_start = k
                            phase_start_12 = max(k_start)
                            phase_stop_12 = min(k_stop_2)
                            if phase_stop_12 >= phase_start_12
                                k_13 = k
                                tns_4_lvl_2_val = min(tns_4_lvl_2_val, 5)
                                k = phase_stop_12 + 1
                            end
                            println(tns_4_lvl_2_val)
                            tns_4_lvl_2.val[tns_4_lvl_q] = tns_4_lvl_2_val
                        end
                    end
                    s = phase_stop_2 + 1
                end
                s_start = s
                phase_start_13 = max(s_start)
                phase_stop_13 = min(s_stop)
                if phase_stop_13 >= phase_start_13
                    s_5 = s
                    s = phase_stop_13 + 1
                end
                (tns_4 = Fiber((Finch.DenseLevel){Int64}(j_stop, tns_4_lvl_2), (Finch.Environment)(; name = :tns_4)),)
            end
    end
end

function dist_update2(new_dist, B, dist)
    #= none:13 =#
    #= none:14 =#
    println(new_dist.lvl.lvl.val)
    #= none:15 =#
    println(B.lvl.lvl.val)
    #= none:16 =#
    println(dist.lvl.lvl.val)
    #= none:17 =#
    begin
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/denselevels.jl:67 =#
            tns_lvl = dist.lvl
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:57 =#
            tns_lvl_2 = tns_lvl.lvl
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:58 =#
            tns_lvl_2_val_alloc = length(tns_lvl.lvl.val)
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:59 =#
            tns_lvl_2_val = 9223372036854775807
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/denselevels.jl:67 =#
            tns_2_lvl = new_dist.lvl
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:57 =#
            tns_2_lvl_2 = tns_2_lvl.lvl
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:58 =#
            tns_2_lvl_2_val_alloc = length(tns_2_lvl.lvl.val)
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:59 =#
            tns_2_lvl_2_val = 9223372036854775807
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/denselevels.jl:67 =#
            tns_3_lvl = B.lvl
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:57 =#
            tns_3_lvl_2 = tns_3_lvl.lvl
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:58 =#
            tns_3_lvl_2_val_alloc = length(tns_3_lvl.lvl.val)
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:59 =#
            tns_3_lvl_2_val = 9223372036854775807
        end
        @inbounds begin
                j_stop = tns_3_lvl.I
                tns_2_lvl_2_val_alloc = (Finch).refill!(tns_2_lvl_2.val, 9223372036854775807, 0, 4)
                tns_2_lvl_2_val_alloc < 1 * tns_3_lvl.I && (tns_2_lvl_2_val_alloc = (Finch).refill!(tns_2_lvl_2.val, 9223372036854775807, tns_2_lvl_2_val_alloc, 1 * tns_3_lvl.I))
                for j = 1:j_stop
                    tns_2_lvl_q = (1 - 1) * tns_3_lvl.I + j
                    tns_lvl_q = (1 - 1) * tns_lvl.I + j
                    tns_3_lvl_q = (1 - 1) * tns_3_lvl.I + j
                    tns_2_lvl_2_val = 9223372036854775807
                    tns_lvl_2_val = tns_lvl_2.val[tns_lvl_q]
                    tns_3_lvl_2_val = tns_3_lvl_2.val[tns_3_lvl_q]
                    tns_2_lvl_2_val = min(tns_lvl_2_val, tns_3_lvl_2_val)
                    tns_2_lvl_2.val[tns_2_lvl_q] = tns_2_lvl_2_val
                end
                (tns_2 = Fiber((Finch.DenseLevel){Int64}(tns_3_lvl.I, tns_2_lvl_2), (Finch.Environment)(; name = :tns_2)),)
            end
    end
end

function main()
    N = 5
    source = 5
    P = 5
    matrix = copy(transpose(MatrixMarket.mmread("./graphs/dag5.mtx")))
    weights = Finch.Fiber(
                Dense(N,
                SparseList(N, matrix.colptr, matrix.rowval,
                Element{0}(matrix.nzval))))
    println(weights.lvl.lvl.lvl.val)

    rowptr = ones(Int64, N + 1)
    priorityQ = Finch.Fiber(
        Dense(P,
        SparseList(N, rowptr, Int64[],
        Element{0}(Int64[]))))
    @finch @loop p j priorityQ[p, j] = (p == 1 && j == $source) + (p == $P && j != $source)
    println(priorityQ.lvl.lvl.lvl.val)

    val = typemax(Int64)
    dist = Finch.Fiber(
                Dense(N,
                    Element{typemax(Int64), Int64}()
        )
    )
    @finch @loop j dist[j] = (j != $source) * $P
    println(dist.lvl.lvl.val)

    B = Finch.Fiber(
        Dense(N,
            Element{typemax(Int64), Int64}([])
        )
    )
    # dist_update1(B, dist, weights, priorityQ, 1)
    @finch @loop j k B[j] <<min>>= ifelse(weights[j, k] * priorityQ[1, k] != 0, weights[j, k] + dist[k], $val)
    
    println(B.lvl.lvl.val)

    new_dist = Finch.Fiber(
                Dense(N,
                    Element{typemax(Int64), Int64}()
        )
    )
    dist_update2(new_dist, B, dist)

    println(new_dist.lvl.lvl.val)
end

main()