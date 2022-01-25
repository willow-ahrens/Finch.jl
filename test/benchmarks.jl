using MatrixDepot
using Finch
using BenchmarkTools
using SparseArrays
using Cthulhu
using Profile

using Finch: dimension

function spmv(mtx)
    println("spmv: $mtx")
    A_ref = SparseMatrixCSC(mdopen(mtx).A)
    (m, n) = size(A_ref)
    A = Finch.Fiber{Float64}((
        SolidLevel(m),
        HollowListLevel{0.0, Float64}(n, A_ref.colptr, A_ref.rowval),
        ElementLevel{0.0, Float64}(A_ref.nzval),
    ))
    y = Finch.Fiber{Float64}((
        SolidLevel(m),
        ElementLevel{0.0, Float64}(zeros(m)),
    ))
    x = Finch.Fiber{Float64}((
        SolidLevel(n),
        ElementLevel{0.0, Float64}(rand(n)),
    ))
    ex = @I @loop i j y[i] += A[i, j] * x[j]
    display(Finch.execute_code_lowered(:ex, typeof(ex)))
    execute(ex)
    println()
    #println(@descend execute(ex))

    println("Finch:")
    display((@benchmark execute($ex)))
    println()


    println("Julia:")
    x_ref = rand(n)
    display((@benchmark $A_ref * $x_ref))
    println()
end


function ata(mtx)
    println("ata: $mtx")
    A_ref = SparseMatrixCSC(mdopen(mtx).A)
    (m, n) = size(A_ref)
    A = Finch.Fiber{Float64}((
        SolidLevel(m),
        HollowListLevel{0.0, Float64}(n, A_ref.colptr, A_ref.rowval),
        ElementLevel{0.0, Float64}(A_ref.nzval),
    ))
    C = Finch.Fiber{Float64}((
        SolidLevel(m),
        SolidLevel(n),
        ElementLevel{0.0, Float64}(zeros(m * n)),
    ))
    ex = @I @loop i j k C[i, j] += A[i, k] * A[j, k]
    display(Finch.execute_code_lowered(:ex, typeof(ex)))
    execute(ex)
    println()
    #println(@descend execute(ex))

    println("Finch:")
    @btime execute($ex)

    println("Julia:")
    @btime $A_ref * $(transpose(A_ref))
end

ata("Gset/G30")

spmv("Boeing/ct20stif")
spmv("Gset/G30")
function bar(ex)
    (@inbounds begin
        tns_C = ex.body.lhs.tns.tns
        tns_A = (ex.body.rhs.args[1]).tns.tns
        tns_B = (ex.body.rhs.args[2]).tns.tns
        var"##C_1_stop#301" = dimension(tns_C.lvls[1])
        var"##C_2_stop#302" = dimension(tns_C.lvls[2])
        var"##A_1_stop#303" = dimension(tns_A.lvls[1])
        var"##A_2_stop#304" = dimension(tns_A.lvls[2])
        1 == 1 || throw(DimensionMismatch("mismatched dimension starts"))
        var"##C_1_stop#301" == var"##A_1_stop#303" || throw(DimensionMismatch("mismatched dimension stops"))
        1 == 1 || throw(DimensionMismatch("mismatched dimension starts"))
        var"##C_2_stop#302" == var"##A_2_stop#304" || throw(DimensionMismatch("mismatched dimension stops"))
        var"##B_1_stop#305" = dimension(tns_B.lvls[1])
        var"##B_2_stop#306" = dimension(tns_B.lvls[2])
        1 == 1 || throw(DimensionMismatch("mismatched dimension starts"))
        var"##C_1_stop#301" == var"##B_1_stop#305" || throw(DimensionMismatch("mismatched dimension stops"))
        1 == 1 || throw(DimensionMismatch("mismatched dimension starts"))
        var"##C_2_stop#302" == var"##B_2_stop#306" || throw(DimensionMismatch("mismatched dimension stops"))
        c_size = 1024
        resize!((tns_C.lvls[3]).val, c_size)
        resize!((tns_C.lvls[2]).idx, c_size)
        for var"##i#307" = 1:var"##C_1_stop#301"
            tns_C_2_p = (tns_C.lvls[2]).pos[var"##i#307"]
            tns_A_2_p = (tns_A.lvls[2]).pos[var"##i#307"]
            tns_A_2_p1 = (tns_A.lvls[2]).pos[var"##i#307" + 1]
            if tns_A_2_p < tns_A_2_p1
                tns_A_2_i = (tns_A.lvls[2]).idx[tns_A_2_p]
                tns_A_2_i1 = (tns_A.lvls[2]).idx[tns_A_2_p1 - 1]
            else
                tns_A_2_i = 1
                tns_A_2_i1 = 0
            end
            tns_B_2_p = (tns_B.lvls[2]).pos[var"##i#307"]
            tns_B_2_p1 = (tns_B.lvls[2]).pos[var"##i#307" + 1]
            if tns_B_2_p < tns_B_2_p1
                tns_B_2_i = (tns_B.lvls[2]).idx[tns_B_2_p]
                tns_B_2_i1 = (tns_B.lvls[2]).idx[tns_B_2_p1 - 1]
            else
                tns_B_2_i = 1
                tns_B_2_i1 = 0
            end
            var"##_j#308" = 1
            var"##_j#309" = min(tns_A_2_i1, tns_B_2_i1, var"##C_2_stop#302")
            var"##_j#310" = var"##_j#308"
            while var"##_j#310" <= var"##_j#309"
                tns_A_2_i = (tns_A.lvls[2]).idx[tns_A_2_p]
                tns_B_2_i = (tns_B.lvls[2]).idx[tns_B_2_p]
                var"##_j#311" = min(tns_A_2_i, tns_B_2_i)
                if var"##_j#311" < tns_A_2_i && var"##_j#311" < tns_B_2_i
                elseif var"##_j#311" < tns_B_2_i
                    if c_size < tns_C_2_p
                        c_size *= 2
                        resize!((tns_C.lvls[3]).val, c_size)
                        resize!((tns_C.lvls[2]).idx, c_size)
                    end
                    tns_A_val = (tns_A.lvls[3]).val[tns_A_2_p]
                    tns_C_val = tns_A_val
                    (tns_C.lvls[3]).val[tns_C_2_p] = tns_C_val
                    (tns_C.lvls[2]).idx[tns_C_2_p] = var"##_j#311"
                    tns_C_2_p += 1
                    tns_A_2_p += 1
                elseif var"##_j#311" < tns_A_2_i
                    if c_size < tns_C_2_p
                        c_size *= 2
                        resize!((tns_C.lvls[3]).val, c_size)
                        resize!((tns_C.lvls[2]).idx, c_size)
                    end
                    tns_B_val = (tns_B.lvls[3]).val[tns_B_2_p]
                    tns_C_val = tns_B_val
                    (tns_C.lvls[3]).val[tns_C_2_p] = tns_C_val
                    (tns_C.lvls[2]).idx[tns_C_2_p] = var"##_j#311"
                    tns_C_2_p += 1
                    tns_B_2_p += 1
                else
                    if c_size < tns_C_2_p
                        c_size *= 2
                        resize!((tns_C.lvls[3]).val, c_size)
                        resize!((tns_C.lvls[2]).idx, c_size)
                    end
                    tns_A_val = (tns_A.lvls[3]).val[tns_A_2_p]
                    tns_B_val = (tns_B.lvls[3]).val[tns_B_2_p]
                    tns_C_val = (tns_A_val + tns_B_val)
                    (tns_C.lvls[3]).val[tns_C_2_p] = tns_C_val
                    (tns_C.lvls[2]).idx[tns_C_2_p] = var"##_j#311"
                    tns_C_2_p += 1
                    tns_A_2_p += 1
                    tns_B_2_p += 1
                end
                var"##_j#310" = var"##_j#311" + 1
            end
            var"##_j#308" = var"##_j#309" + 1
            var"##_j#309" = min(tns_B_2_i1, var"##C_2_stop#302")
            if var"##_j#308" <= var"##_j#309"
                var"##_j#318" = var"##_j#308"
                while tns_B_2_p < tns_B_2_p1
                    tns_B_2_i = (tns_B.lvls[2]).idx[tns_B_2_p]
                    if tns_B_2_i < tns_B_2_i
                    else
                        if c_size < tns_C_2_p
                            c_size *= 2
                            resize!((tns_C.lvls[3]).val, c_size)
                            resize!((tns_C.lvls[2]).idx, c_size)
                        end
                        tns_B_val = (tns_B.lvls[3]).val[tns_B_2_p]
                        tns_C_val = tns_B_val
                        (tns_C.lvls[3]).val[tns_C_2_p] = tns_C_val
                        (tns_C.lvls[2]).idx[tns_C_2_p] = tns_B_2_i
                        tns_C_2_p += 1
                        tns_B_2_p += 1
                    end
                    var"##_j#318" = tns_B_2_i + 1
                end
                var"##_j#308" = var"##_j#309" + 1
            end
            var"##_j#309" = min(tns_A_2_i1, var"##C_2_stop#302")
            if var"##_j#308" <= var"##_j#309"
                var"##_j#321" = var"##_j#308"
                while tns_A_2_p < tns_A_2_p1
                    tns_A_2_i = (tns_A.lvls[2]).idx[tns_A_2_p]
                    if tns_A_2_i < tns_A_2_i
                    else
                        if c_size < tns_C_2_p
                            c_size *= 2
                            resize!((tns_C.lvls[3]).val, c_size)
                            resize!((tns_C.lvls[2]).idx, c_size)
                        end
                        tns_A_val = (tns_A.lvls[3]).val[tns_A_2_p]
                        tns_C_val = tns_A_val
                        (tns_C.lvls[3]).val[tns_C_2_p] = tns_C_val
                        (tns_C.lvls[2]).idx[tns_C_2_p] = tns_A_2_i
                        tns_C_2_p += 1
                        tns_A_2_p += 1
                    end
                    var"##_j#321" = tns_A_2_i + 1
                end
                var"##_j#308" = var"##_j#309" + 1
            end
            var"##_j#309" = min(var"##C_2_stop#302")
            if var"##_j#308" <= var"##_j#309"
                var"##_j#308" = var"##_j#309" + 1
            end
            (tns_C.lvls[2]).pos[var"##i#307" + 1] = tns_C_2_p
        end
    end)
end

function foo(A, B) 
    (m, n) = size(A)
    C = Finch.Fiber{Float64}((
        SolidLevel(m),
        HollowListLevel{0.0, Float64}(n, ones(Int, m + 1), Int[]),
        ElementLevel{0.0, Float64}([]),
    ))
    ex = @I @loop i j C[i, j] = A[i, j] + B[i, j]
    execute(ex)
    #bar(ex)
end

function apb(mtxa, mtxb)
    println("apb: $mtxa, $mtxb")
    A_ref = SparseMatrixCSC{Float64}(mdopen(mtxa).A)
    B_ref = SparseMatrixCSC{Float64}(mdopen(mtxb).A)
    (m, n) = size(A_ref)
    A = Finch.Fiber{Float64}((
        SolidLevel(m),
        HollowListLevel{0.0, Float64}(n, A_ref.colptr, A_ref.rowval),
        ElementLevel{0.0, Float64}(A_ref.nzval),
    ))
    B = Finch.Fiber{Float64}((
        SolidLevel(m),
        HollowListLevel{0.0, Float64}(n, B_ref.colptr, B_ref.rowval),
        ElementLevel{0.0, Float64}(B_ref.nzval),
    ))
    C = Finch.Fiber{Float64}((
        SolidLevel(m),
        HollowListLevel{0.0, Float64}(n, ones(Int, m + 1), Int[]),
        ElementLevel{0.0, Float64}([]),
    ))
    ex = @I @loop i j C[i, j] += A[i, j] + B[i, j]
    #display(Finch.execute_code_lowered(:ex, typeof(ex)))
    bar(ex)
    execute(ex)
    println()
    #println(@descend execute(ex))

    println("Finch:")
    display((@benchmark foo($A, $B)))
    println()

    println("Julia:")
    x_ref = rand(n)
    display((@benchmark $A_ref + $B_ref))
    println()
end

apb("Gset/G30", "Gset/G31")
apb("DRIVCAV/cavity25", "DRIVCAV/cavity26")