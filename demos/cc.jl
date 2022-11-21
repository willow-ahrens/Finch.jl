using Finch
using Finch.IndexNotation
using RewriteTools
using BenchmarkTools
using SparseArrays
using LinearAlgebra
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
    (@rule @f(@chunk $i $a ($b[j...] <<min>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<min>>= $d)
    end),
    (@rule @f(@chunk $i $a @multi b... ($c[j...] <<min>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @f @multi (c[j...] <<min>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),

    (@rule @f(@chunk $i $a ($b[j...] <<$or>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<$or>>= $d)
    end),

    (@rule @f(@chunk $i $a @multi b... ($c[j...] <<$or>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @f @multi (c[j...] <<$or>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),
])

Finch.register()

function edge_update3(new_update1, new_ids, old_ids, N)
    #= none:12 =#
    #= none:13 =#
    new_update1.val = 0
    #= none:14 =#
    #= none:15 =#
    println(new_ids.lvl.lvl.val)
    #= none:16 =#
    println(old_ids.lvl.lvl.val)
    #= none:17 =#
    begin
        begin
            #= /Users/adadima/mit/commit/Finch.jl/src/denselevels.jl:67 =#
            tns_lvl = old_ids.lvl
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
            tns_2_lvl = new_ids.lvl
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
            #= /Users/adadima/mit/commit/Finch.jl/src/scalars.jl:31 =#
            new_update1 = new_update1
            #= /Users/adadima/mit/commit/Finch.jl/src/scalars.jl:32 =#
            new_update1_val = new_update1.val
        end
        @inbounds begin
                i_stop = tns_lvl.I
                new_update1_val = 0
                for i = 1:i_stop
                    tns_lvl_q = (1 - 1) * tns_lvl.I + i
                    tns_lvl_q_2 = (1 - 1) * tns_lvl.I + i
                    tns_lvl_2_val = tns_lvl_2.val[tns_lvl_q]
                    tns_lvl_2_val = tns_lvl_2.val[tns_lvl_q_2]
                    s_stop = tns_lvl.I
                    s_2_stop = tns_2_lvl.I
                    select_s_2 = tns_lvl_2_val
                    s_2 = 1
                    s_2_start = s_2
                    phase_start = max(s_2_start, s_2_start)
                    phase_stop = min(s_2_stop, select_s_2 - 1)
                    if phase_stop >= phase_start
                        s_3 = s_2
                        s_2 = phase_stop + 1
                    end
                    s_2_start = s_2
                    phase_start_2 = max(s_2_start, s_2_start)
                    phase_stop_2 = min(s_2_stop, select_s_2)
                    if phase_stop_2 >= phase_start_2
                        s_4 = s_2
                        for s_5 = phase_start_2:phase_stop_2
                            tns_2_lvl_q = (1 - 1) * tns_2_lvl.I + s_5
                            tns_2_lvl_2_val = tns_2_lvl_2.val[tns_2_lvl_q]
                            select_s = tns_lvl_2_val
                            s = 1
                            s_start = s
                            phase_start_3 = max(s_start, s_start)
                            phase_stop_3 = min(s_stop, select_s - 1)
                            if phase_stop_3 >= phase_start_3
                                s_6 = s
                                s = phase_stop_3 + 1
                            end
                            s_start = s
                            phase_start_4 = max(s_start, s_start)
                            phase_stop_4 = min(s_stop, select_s)
                            if phase_stop_4 >= phase_start_4
                                s_7 = s
                                for s_8 = phase_start_4:phase_stop_4
                                    tns_lvl_q_3 = (1 - 1) * tns_lvl.I + s_8
                                    tns_lvl_2_val = tns_lvl_2.val[tns_lvl_q_3]
                                    println("BEFORE")
                                    println(new_update1_val)
                                    new_update1_val = or(new_update1_val, tns_lvl_2_val != tns_2_lvl_2_val)
                                    println("CONDITION")
                                    println(tns_lvl_2_val != tns_2_lvl_2_val)
                                    println("AFTER")
                                    println(new_update1_val)
                                end
                                s = phase_stop_4 + 1
                            end
                            s_start = s
                            phase_start_5 = max(s_start, s_start)
                            phase_stop_5 = min(s_stop, s_stop)
                            if phase_stop_5 >= phase_start_5
                                s_9 = s
                                s = phase_stop_5 + 1
                            end
                        end
                        s_2 = phase_stop_2 + 1
                    end
                    s_2_start = s_2
                    phase_start_6 = max(s_2_start, s_2_start)
                    phase_stop_6 = min(s_2_stop, s_2_stop)
                    if phase_stop_6 >= phase_start_6
                        s_10 = s_2
                        s_2 = phase_stop_6 + 1
                    end
                end
                (new_update1 = (Scalar){0, Int64}(new_update1_val),)
                new_update1.val = new_update1_val
                println("FINAL:")
                println(new_update1_val)
            end
    end
    #= none:18 =#
end

function main()
    N = 5
    matrix = copy(transpose(MatrixMarket.mmread("./graphs/dag5.mtx")))
    nzval = ones(size(matrix.nzval, 1))
    Finch.Fiber(
                Dense(N,
                SparseList(N, matrix.colptr, matrix.rowval,
                Element{0}(nzval))))

    old_ids = Finch.Fiber(
        Dense(N,
            Element{0, Cint}([1, 2, 3, 4, 5])
        )
    )
    new_ids = Finch.Fiber(
        Dense(N,
            Element{0, Cint}([1, 1, 2, 3, 1])
        )
    )
    update = Scalar{0}()

    edge_update3(update, new_ids, old_ids, N)

    println(update.val)

end

main()