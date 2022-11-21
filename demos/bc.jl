using Finch
using Finch.IndexNotation
using RewriteTools
using BenchmarkTools
using SparseArrays
using LinearAlgebra
using MatrixMarket


function back_edge2(new_deps, B, deps)
    #= none:12 =#
    #= none:13 =#
    begin
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/denselevels.jl:67 =#
            tns_lvl = new_deps.lvl
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
            tns_2_lvl = deps.lvl
        end
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:57 =#
            tns_2_lvl_2 = tns_2_lvl.lvl
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:58 =#
            tns_2_lvl_2_val_alloc = length(tns_2_lvl.lvl.val)
            #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:59 =#
            tns_2_lvl_2_val = 0
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
            tns_3_lvl_2_val = 0
        end
        @inbounds begin
                j_stop = tns_2_lvl.I
                tns_lvl_2_val_alloc = (Finch).refill!(tns_lvl_2.val, 0, 0, 4)
                tns_lvl_2_val_alloc < 1 * tns_2_lvl.I && (tns_lvl_2_val_alloc = (Finch).refill!(tns_lvl_2.val, 0, tns_lvl_2_val_alloc, 1 * tns_2_lvl.I))
                for j = 1:j_stop
                    tns_lvl_q = (1 - 1) * tns_2_lvl.I + j
                    tns_3_lvl_q = (1 - 1) * tns_3_lvl.I + j
                    tns_2_lvl_q = (1 - 1) * tns_2_lvl.I + j
                    tns_lvl_2_val = 0
                    tns_3_lvl_2_val = tns_3_lvl_2.val[tns_3_lvl_q]
                    tns_2_lvl_2_val = tns_2_lvl_2.val[tns_2_lvl_q]
                    tns_lvl_2_val = tns_3_lvl_2_val + tns_2_lvl_2_val
                    tns_lvl_2.val[tns_lvl_q] = tns_lvl_2_val
                end
                (tns = Fiber((Finch.DenseLevel){Int64}(tns_2_lvl.I, tns_lvl_2), (Finch.Environment)(; name = :tns)),)
            end
    end
end


function main()
    N = 5
    matrix = copy(transpose(MatrixMarket.mmread("./graphs/dag5.mtx")))
    nzval = ones(size(matrix.nzval, 1))
    edges = Finch.Fiber(
                Dense(N,
                SparseList(N, matrix.colptr, matrix.rowval,
                Element{0}(nzval))))
   
    B = Finch.Fiber(
        Dense(N,
            Element{typemax(Int64), Int64}([0,0,1,0,0])
        )
    )

    in_deps = Finch.Fiber(
        Dense(N,
            Element{typemax(Int64), Int64}([0,1,0,0,0])
        )
    )

    out_deps = Finch.Fiber(
        Dense(N,
            Element{typemax(Int64), Int64}()
        )
    )

    back_edge2(out_deps, B, in_deps)

    println(out_deps.lvl.lvl.val)

end

main()