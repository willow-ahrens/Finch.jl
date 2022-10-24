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

Finch.register()function dist_update1(new_dist, dist, weights, priorityQ, priority, N)
#= none:22 =#
#= none:23 =#
B = Finch.Fiber(Dense(N, Element{typemax(Int64), Int64}()))
#= none:28 =#
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
        tns_3_lvl_2_val = 9223372036854775807
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
        tns_4_lvl_2_val = 9223372036854775807
    end
    begin
        #= /Users/adadima/mit/commit/Finch.jl/src/denselevels.jl:67 =#
        tns_5_lvl = new_dist.lvl
    end
    begin
        #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:57 =#
        tns_5_lvl_2 = tns_5_lvl.lvl
        #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:58 =#
        tns_5_lvl_2_val_alloc = length(tns_5_lvl.lvl.val)
        #= /Users/adadima/mit/commit/Finch.jl/src/elementlevels.jl:59 =#
        tns_5_lvl_2_val = 9223372036854775807
    end
    @inbounds begin
            j_stop = j_stop
            tns_5_lvl_2_val_alloc = (Finch).refill!(tns_5_lvl_2.val, 9223372036854775807, 0, 4)
            tns_5_lvl_2_val_alloc < 1j_stop && (tns_5_lvl_2_val_alloc = (Finch).refill!(tns_5_lvl_2.val, 9223372036854775807, tns_5_lvl_2_val_alloc, 1j_stop))
            for j = 1:j_stop
                tns_5_lvl_q = (1 - 1) * j_stop + j
                tns_4_lvl_q = (1 - 1) * j_stop + j
                tns_3_lvl_q = (1 - 1) * tns_3_lvl.I + j
                tns_5_lvl_2_val = 9223372036854775807
                tns_4_lvl_2_val = tns_4_lvl_2.val[tns_4_lvl_q]
                tns_3_lvl_2_val = tns_3_lvl_2.val[tns_3_lvl_q]
                tns_5_lvl_2_val = min(tns_4_lvl_2_val, tns_3_lvl_2_val)
                tns_5_lvl_2.val[tns_5_lvl_q] = tns_5_lvl_2_val
            end
            (tns_5 = Fiber((Finch.DenseLevel){Int64}(j_stop, tns_5_lvl_2), (Finch.Environment)(; name = :tns_5)),)
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
                    tns_3_lvl_q = (1 - 1) * tns_3_lvl.I + j
                    tns_lvl_q = (1 - 1) * tns_lvl.I + j
                    tns_2_lvl_2_val = 9223372036854775807
                    tns_3_lvl_2_val = tns_3_lvl_2.val[tns_3_lvl_q]
                    tns_lvl_2_val = tns_lvl_2.val[tns_lvl_q]
                    tns_2_lvl_2_val = min(tns_3_lvl_2_val, tns_lvl_2_val)
                    tns_2_lvl_2.val[tns_2_lvl_q] = tns_2_lvl_2_val
                end
                (tns_2 = Fiber((Finch.DenseLevel){Int64}(tns_3_lvl.I, tns_2_lvl_2), (Finch.Environment)(; name = :tns_2)),)
            end
    end
    #= none:18 =#
    println(new_dist.lvl.lvl.val)
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

    new_dist = Finch.Fiber(
        Dense(N,
            Element{typemax(Int64), Int64}([])
        )
    )
    dist_update1(new_dist, dist, weights, priorityQ, 1)
    # @finch @loop j k B[j] <<min>>= ifelse(weights[j, k] * priorityQ[1, k] != 0, weights[j, k] + dist[k], $val)
    
    println(new_dist.lvl.lvl.val)

    # new_dist = Finch.Fiber(
    #             Dense(N,
    #                 Element{typemax(Int64), Int64}()
    #     )
    # )
    # dist_update2(new_dist, B, dist)

    # println(new_dist.lvl.lvl.val)
end

main()