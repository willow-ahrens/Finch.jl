using Finch
using Finch.IndexNotation
using RewriteTools
using BenchmarkTools
using SparseArrays
using LinearAlgebra
using MatrixMarket


function def_1_pagerank(edges, out_d)
                 #= none:12 =#
                 #= none:13 =#
               w_0 = Scalar{0}()
                 begin
                     begin
                         #= /Users/adadima/mit/commit/Finch.jl/src/denselevels.jl:67 =#
                         tns_lvl = out_d.lvl
                     end
                     begin
                         #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:57 =#
                         tns_lvl_2 = tns_lvl.lvl
                         #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:58 =#
                         tns_lvl_2_val_alloc = length(tns_lvl.lvl.val)
                         #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:59 =#
                         tns_lvl_2_val = 0
                     end
                     begin
                         #= /Users/adadima/mit/commit/Finch.jl/src/denselevels.jl:67 =#
                         tns_2_lvl = edges.lvl
                     end
                     begin
                         #= /Users/adadima/mit/commit/Finch.jl/src/denselevels.jl:67 =#
                         tns_2_lvl_2 = tns_2_lvl.lvl
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
                         #= /Users/adadima/mit/commit/Finch.jl/src/scalars.jl:31 =#
                         w_0 = w_0
                         #= /Users/adadima/mit/commit/Finch.jl/src/scalars.jl:32 =#
                         w_0_val = w_0.val
                     end
                     @inbounds begin
                             j_stop = tns_2_lvl_2.I
                             i_stop = tns_2_lvl.I
                             tns_lvl_2_val_alloc = (Finch).refill!(tns_lvl_2.val, 0, 0, 4)
                             tns_lvl_2_val_alloc < 1 * tns_2_lvl_2.I && (tns_lvl_2_val_alloc = (Finch).refill!(tns_lvl_2.val, 0, tns_lvl_2_val_alloc, 1 * tns_2_lvl_2.I))
                             for j = 1:j_stop
                                 tns_lvl_q = (1 - 1) * tns_2_lvl_2.I + j
                                 tns_lvl_2_val = 0
                                 tns_lvl_2_val = begin
                                         w_0_val = 0
                                         for i = 1:i_stop
                                             tns_2_lvl_q = (1 - 1) * tns_2_lvl.I + i
                                             s_stop = tns_2_lvl_2.I
                                             select_s = j
                                             s = 1
                                             s_start = s
                                             phase_start = max(s_start)
                                             phase_stop = min(s_stop, select_s - 1)
                                             if phase_stop >= phase_start
                                                 s_2 = s
                                                 s = phase_stop + 1
                                             end
                                             s_start = s
                                             phase_start_2 = max(s_start)
                                             phase_stop_2 = min(s_stop, select_s)
                                             if phase_stop_2 >= phase_start_2
                                                 s_3 = s
                                                 for s_4 = phase_start_2:phase_stop_2
                                                     tns_2_lvl_2_q = (tns_2_lvl_q - 1) * tns_2_lvl_2.I + s_4
                                                     tns_2_lvl_3_val = tns_2_lvl_3.val[tns_2_lvl_2_q]
                                                     w_0_val = w_0_val + tns_2_lvl_3_val
                                                 end
                                                 s = phase_stop_2 + 1
                                             end
                                             s_start = s
                                             phase_start_3 = max(s_start)
                                             phase_stop_3 = min(s_stop)
                                             if phase_stop_3 >= phase_start_3
                                                 s_5 = s
                                                 s = phase_stop_3 + 1
                                             end
                                         end
                                         w_0_val
                                     end
                                 tns_lvl_2.val[tns_lvl_q] = tns_lvl_2_val
                             end
                             (tns = Fiber((Finch.DenseLevel){Int64}(tns_2_lvl_2.I, tns_lvl_2), (Finch.Environment)(; name = :tns)),)
                         end
    end
 end

function main()
    matrix = copy(transpose(MatrixMarket.mmread("graphs/dag3.mtx")))
    (n, m) = size(matrix)
    @assert n == m
    nzval = ones(size(matrix.nzval, 1))
    edges = Finch.Fiber(
                Dense(n,
                SparseList(n, matrix.colptr, matrix.rowval,
                Element{0}(nzval))))
    out_d = Finch.Fiber(Dense(n, Element{0, Int64}()))
    def_1_pagerank(edges, out_d)
    println(out_d.lvl.lvl.val)
end


main()