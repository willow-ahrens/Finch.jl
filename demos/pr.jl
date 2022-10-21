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

function out_d_init(out_d, edges)
    @finch @loop i j out_d[j] += edges[i, j]
end

function r_init(r, N)
    @finch @loop j r[j] = 1.0 / $N
end

function c_init(contrib, r_in, out_d)
    @finch @loop i contrib[i] = r_in[i] / out_d[i]
end

function get_kernel(deg, edges)
    #= none:12 =#
    #= none:13 =#
    begin
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/denselevels.jl:67 =#
            tns_lvl = edges.lvl
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
            tns_2_lvl = deg.lvl
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:57 =#
            tns_2_lvl_2 = tns_2_lvl.lvl
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:58 =#
            tns_2_lvl_2_val_alloc = length(tns_2_lvl.lvl.val)
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:59 =#
            tns_2_lvl_2_val = 0
        end
        @inbounds begin
                j_stop = tns_lvl_2.I
                i_stop = tns_lvl.I
                tns_2_lvl_2_val_alloc = (Finch).refill!(tns_2_lvl_2.val, 0, 0, 4)
                tns_2_lvl_2_val_alloc < 1 * tns_lvl_2.I && (tns_2_lvl_2_val_alloc = (Finch).refill!(tns_2_lvl_2.val, 0, tns_2_lvl_2_val_alloc, 1 * tns_lvl_2.I))
                for i = 1:i_stop
                    tns_lvl_q = (1 - 1) * tns_lvl.I + i
                    tns_lvl_2_q = tns_lvl_2.pos[tns_lvl_q]
                    tns_lvl_2_q_stop = tns_lvl_2.pos[tns_lvl_q + 1]
                    if tns_lvl_2_q < tns_lvl_2_q_stop
                        tns_lvl_2_i = tns_lvl_2.idx[tns_lvl_2_q]
                        tns_lvl_2_i1 = tns_lvl_2.idx[tns_lvl_2_q_stop - 1]
                    else
                        tns_lvl_2_i = 1
                        tns_lvl_2_i1 = 0
                    end
                    j = 1
                    j_start = j
                    phase_start = max(j_start)
                    phase_stop = min(tns_lvl_2_i1, j_stop)
                    if phase_stop >= phase_start
                        j = j
                        j = phase_start
                        while tns_lvl_2_q < tns_lvl_2_q_stop && tns_lvl_2.idx[tns_lvl_2_q] < phase_start
                            tns_lvl_2_q += 1
                        end
                        while j <= phase_stop
                            j_start_2 = j
                            tns_lvl_2_i = tns_lvl_2.idx[tns_lvl_2_q]
                            phase_stop_2 = min(tns_lvl_2_i, phase_stop)
                            j_2 = j
                            if tns_lvl_2_i == phase_stop_2
                                tns_lvl_3_val = tns_lvl_3.val[tns_lvl_2_q]
                                j_3 = phase_stop_2
                                tns_2_lvl_q = (1 - 1) * tns_lvl_2.I + j_3
                                tns_2_lvl_2_val = tns_2_lvl_2.val[tns_2_lvl_q]
                                tns_2_lvl_2_val = tns_2_lvl_2_val + tns_lvl_3_val
                                tns_2_lvl_2.val[tns_2_lvl_q] = tns_2_lvl_2_val
                                tns_lvl_2_q += 1
                            else
                            end
                            j = phase_stop_2 + 1
                        end
                        j = phase_stop + 1
                    end
                    j_start = j
                    phase_start_3 = max(j_start)
                    phase_stop_3 = min(j_stop)
                    if phase_stop_3 >= phase_start_3
                        j_4 = j
                        j = phase_stop_3 + 1
                    end
                end
                (tns_2 = Fiber((Finch.DenseLevel){Int64}(tns_lvl_2.I, tns_2_lvl_2), (Finch.Environment)(; name = :tns_2)),)
            end
    end
end

function main()
    N = 1
    matrix = copy(transpose(MatrixMarket.mmread("./graphs/starter.mtx")))
    nzval = ones(size(matrix.nzval, 1))
    edges = Finch.Fiber(
                Dense(N,
                SparseList(N, matrix.colptr, matrix.rowval,
                Element{0}(nzval))))
    
    deg = Finch.Fiber(
        Dense(N,
            Element{0, Int64}([])
        )
    )

    get_kernel(deg, edges)

    println(deg.lvl.lvl.val)
end

main()