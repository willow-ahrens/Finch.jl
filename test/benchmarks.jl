using MatrixDepot
using Finch
using BenchmarkTools
using SparseArrays
using Cthulhu

using Finch: dimension

function spmv(mtx)
    println("spmv: $mtx")
    A_ref = SparseMatrixCSC(mdopen(mtx).A)
    (m, n) = size(A_ref)
    A = Finch.Fiber{Float64}((
        SolidLevel(m),
        HollowLevel{0.0, Float64}(n, A_ref.colptr, A_ref.rowval),
        ScalarLevel{0.0, Float64}(A_ref.nzval),
    ))
    y = Finch.Fiber{Float64}((
        SolidLevel(m),
        ScalarLevel{0.0, Float64}(zeros(m)),
    ))
    x = Finch.Fiber{Float64}((
        SolidLevel(n),
        ScalarLevel{0.0, Float64}(rand(n)),
    ))
    ex = @I @loop i j y[i] += A[i, j] * x[j]
    display(Finch.execute_code_lowered(:ex, typeof(ex)))
    execute(ex)
    println()
    #println(@descend execute(ex))

    println("Finch:")
    @btime execute($ex)

    println("Julia:")
    x_ref = rand(n)
    @btime $A_ref * $x_ref
end

#spmv("Boeing/ct20stif")
function bar(ex)
    tns_C = ex.body.lhs.tns.tns
    tns_A = (ex.body.rhs.args[1]).tns.tns
    tns_B = (ex.body.rhs.args[2]).tns.tns
    var"##C_1_stop#300" = dimension(tns_C.lvls[1])
    var"##C_2_stop#301" = dimension(tns_C.lvls[2])
    var"##A_1_stop#302" = dimension(tns_A.lvls[1])
    var"##A_2_stop#303" = dimension(tns_A.lvls[2])
    1 == 1 || throw(DimensionMismatch("mismatched dimension starts"))
    var"##C_1_stop#300" == var"##A_1_stop#302" || throw(DimensionMismatch("mismatched dimension stops"))
    1 == 1 || throw(DimensionMismatch("mismatched dimension starts"))
    var"##C_2_stop#301" == var"##A_2_stop#303" || throw(DimensionMismatch("mismatched dimension stops"))
    var"##B_1_stop#304" = dimension(tns_B.lvls[1])
    var"##B_2_stop#305" = dimension(tns_B.lvls[2])
    1 == 1 || throw(DimensionMismatch("mismatched dimension starts"))
    var"##C_1_stop#300" == var"##B_1_stop#304" || throw(DimensionMismatch("mismatched dimension stops"))
    1 == 1 || throw(DimensionMismatch("mismatched dimension starts"))
    var"##C_2_stop#301" == var"##B_2_stop#305" || throw(DimensionMismatch("mismatched dimension stops"))
    for var"##i#306" = 1:var"##C_1_stop#300"
        tns_C_2_p = (tns_C.lvls[2]).pos[var"##i#306"]
        tns_A_2_p = (tns_A.lvls[2]).pos[var"##i#306"]
        tns_A_2_p1 = (tns_A.lvls[2]).pos[var"##i#306" + 1]
        if tns_A_2_p < tns_A_2_p1
            tns_A_2_i = (tns_A.lvls[2]).idx[tns_A_2_p]
            tns_A_2_i1 = (tns_A.lvls[2]).idx[tns_A_2_p1 - 1]
        else
            tns_A_2_i = 1
            tns_A_2_i1 = 0
        end
        tns_B_2_p = (tns_B.lvls[2]).pos[var"##i#306"]
        tns_B_2_p1 = (tns_B.lvls[2]).pos[var"##i#306" + 1]
        if tns_B_2_p < tns_B_2_p1
            tns_B_2_i = (tns_B.lvls[2]).idx[tns_B_2_p]
            tns_B_2_i1 = (tns_B.lvls[2]).idx[tns_B_2_p1 - 1]
        else
            tns_B_2_i = 1
            tns_B_2_i1 = 0
        end
        var"##_j#307" = 1
        var"##_j#308" = min(tns_A_2_i1, tns_B_2_i1, var"##C_2_stop#301")
        var"##_j#309" = var"##_j#307"
        while var"##_j#309" <= var"##_j#308"
            tns_A_2_i = (tns_A.lvls[2]).idx[tns_A_2_p]
            tns_B_2_i = (tns_B.lvls[2]).idx[tns_B_2_p]
            var"##_j#310" = min(tns_A_2_i, tns_B_2_i)
            if var"##_j#310" < tns_A_2_i && var"##_j#310" < tns_B_2_i
            elseif var"##_j#310" < tns_B_2_i
                var"##311" = length((tns_C.lvls[3]).val)
                resize!((tns_C.lvls[3]).val, tns_C_2_p)
                for var"##312" = var"##311" + 1:tns_C_2_p
                    (tns_C.lvls[3]).val[var"##312"] = 0.0
                end
                tns_C_val = (tns_C.lvls[3]).val[tns_C_2_p]
                tns_A_val = (tns_A.lvls[3]).val[tns_A_2_p]
                tns_C_val = tns_C_val + +tns_A_val
                (tns_C.lvls[3]).val[tns_C_2_p] = tns_C_val
                push!((tns_C.lvls[2]).idx, var"##_j#310")
                tns_C_2_p += 1
                tns_A_2_p += 1
            elseif var"##_j#310" < tns_A_2_i
                var"##313" = length((tns_C.lvls[3]).val)
                resize!((tns_C.lvls[3]).val, tns_C_2_p)
                for var"##314" = var"##313" + 1:tns_C_2_p
                    (tns_C.lvls[3]).val[var"##314"] = 0.0
                end
                tns_C_val = (tns_C.lvls[3]).val[tns_C_2_p]
                tns_B_val = (tns_B.lvls[3]).val[tns_B_2_p]
                tns_C_val = tns_C_val + +tns_B_val
                (tns_C.lvls[3]).val[tns_C_2_p] = tns_C_val
                push!((tns_C.lvls[2]).idx, var"##_j#310")
                tns_C_2_p += 1
                tns_B_2_p += 1
            else
                var"##315" = length((tns_C.lvls[3]).val)
                resize!((tns_C.lvls[3]).val, tns_C_2_p)
                for var"##316" = var"##315" + 1:tns_C_2_p
                    (tns_C.lvls[3]).val[var"##316"] = 0.0
                end
                tns_C_val = (tns_C.lvls[3]).val[tns_C_2_p]
                tns_A_val = (tns_A.lvls[3]).val[tns_A_2_p]
                tns_B_val = (tns_B.lvls[3]).val[tns_B_2_p]
                tns_C_val = tns_C_val + (tns_A_val + tns_B_val)
                (tns_C.lvls[3]).val[tns_C_2_p] = tns_C_val
                push!((tns_C.lvls[2]).idx, var"##_j#310")
                tns_C_2_p += 1
                tns_A_2_p += 1
                tns_B_2_p += 1
            end
            var"##_j#309" = var"##_j#310" + 1
        end
        var"##_j#307" = var"##_j#308" + 1
        var"##_j#308" = min(tns_B_2_i1, var"##C_2_stop#301")
        if var"##_j#307" <= var"##_j#308"
            var"##_j#317" = var"##_j#307"
            while tns_B_2_p < tns_B_2_p1
                tns_B_2_i = (tns_B.lvls[2]).idx[tns_B_2_p]
                if tns_B_2_i < tns_B_2_i
                else
                    var"##318" = length((tns_C.lvls[3]).val)
                    resize!((tns_C.lvls[3]).val, tns_C_2_p)
                    for var"##319" = var"##318" + 1:tns_C_2_p
                        (tns_C.lvls[3]).val[var"##319"] = 0.0
                    end
                    tns_C_val = (tns_C.lvls[3]).val[tns_C_2_p]
                    tns_B_val = (tns_B.lvls[3]).val[tns_B_2_p]
                    tns_C_val = tns_C_val + +tns_B_val
                    (tns_C.lvls[3]).val[tns_C_2_p] = tns_C_val
                    push!((tns_C.lvls[2]).idx, tns_B_2_i)
                    tns_C_2_p += 1
                    tns_B_2_p += 1
                end
                var"##_j#317" = tns_B_2_i + 1
            end
            var"##_j#307" = var"##_j#308" + 1
        end
        var"##_j#308" = min(tns_A_2_i1, var"##C_2_stop#301")
        if var"##_j#307" <= var"##_j#308"
            var"##_j#320" = var"##_j#307"
            while tns_A_2_p < tns_A_2_p1
                tns_A_2_i = (tns_A.lvls[2]).idx[tns_A_2_p]
                if tns_A_2_i < tns_A_2_i
                else
                    var"##321" = length((tns_C.lvls[3]).val)
                    resize!((tns_C.lvls[3]).val, tns_C_2_p)
                    for var"##322" = var"##321" + 1:tns_C_2_p
                        (tns_C.lvls[3]).val[var"##322"] = 0.0
                    end
                    tns_C_val = (tns_C.lvls[3]).val[tns_C_2_p]
                    tns_A_val = (tns_A.lvls[3]).val[tns_A_2_p]
                    tns_C_val = tns_C_val + +tns_A_val
                    (tns_C.lvls[3]).val[tns_C_2_p] = tns_C_val
                    push!((tns_C.lvls[2]).idx, tns_A_2_i)
                    tns_C_2_p += 1
                    tns_A_2_p += 1
                end
                var"##_j#320" = tns_A_2_i + 1
            end
            var"##_j#307" = var"##_j#308" + 1
        end
        var"##_j#308" = min(var"##C_2_stop#301")
        if var"##_j#307" <= var"##_j#308"
            var"##_j#307" = var"##_j#308" + 1
        end
        (tns_C.lvls[2]).pos[var"##i#306" + 1] = tns_C_2_p
    end
end

function foo(A, B) 
    (m, n) = size(A)
    C = Finch.Fiber{Float64}((
        SolidLevel(m),
        HollowLevel{0.0, Float64}(n, ones(Int, m + 1), Int[]),
        ScalarLevel{0.0, Float64}([]),
    ))
    ex = @I @loop i j C[i, j] += A[i, j] + B[i, j]
    execute(ex)
end

function apb(m, n, p)
    println("apb: $m × $n, $p")
    A_ref = sprand(m, n, p)
    B_ref = sprand(m, n, p)
    A = Finch.Fiber{Float64}((
        SolidLevel(m),
        HollowLevel{0.0, Float64}(n, A_ref.colptr, A_ref.rowval),
        ScalarLevel{0.0, Float64}(A_ref.nzval),
    ))
    B = Finch.Fiber{Float64}((
        SolidLevel(m),
        HollowLevel{0.0, Float64}(n, B_ref.colptr, B_ref.rowval),
        ScalarLevel{0.0, Float64}(B_ref.nzval),
    ))
    C = Finch.Fiber{Float64}((
        SolidLevel(m),
        HollowLevel{0.0, Float64}(n, ones(Int, m + 1), Int[]),
        ScalarLevel{0.0, Float64}([]),
    ))
    ex = @I @loop i j C[i, j] += A[i, j] + B[i, j]
    display(Finch.execute_code_lowered(:ex, typeof(ex)))
    bar(ex)
    execute(ex)
    println()
    #println(@descend execute(ex))


    println("Finch:")
    @btime foo($A, $B)

    println("Julia:")
    x_ref = rand(n)
    @btime $A_ref + $B_ref
end

apb(10_000, 10_000, 0.01)