using MatrixDepot
using Finch
using BenchmarkTools
using SparseArrays
using Cthulhu

using Finch: dimension
function bar(ex)
    (@inbounds begin
        tns_y = ex.body.lhs.tns.tns
        tns_A = (ex.body.rhs.args[1]).tns.tns
        tns_x = (ex.body.rhs.args[2]).tns.tns
        var"##y_1_stop#293" = dimension(tns_y.lvls[1])
        var"##A_1_stop#294" = dimension(tns_A.lvls[1])
        var"##A_2_stop#295" = dimension(tns_A.lvls[2])
        1 == 1 || throw(DimensionMismatch("mismatched dimension starts"))
        var"##y_1_stop#293" == var"##A_1_stop#294" || throw(DimensionMismatch("mismatched dimension stops"))
        var"##x_1_stop#296" = dimension(tns_x.lvls[1])
        1 == 1 || throw(DimensionMismatch("mismatched dimension starts"))
        var"##A_2_stop#295" == var"##x_1_stop#296" || throw(DimensionMismatch("mismatched dimension stops"))
        for var"##i#297" = 1:var"##y_1_stop#293"
            tns_y_val = (tns_y.lvls[2]).val[var"##i#297"]
            tns_A_2_p = (tns_A.lvls[2]).pos[var"##i#297"]
            tns_A_2_p1 = (tns_A.lvls[2]).pos[var"##i#297" + 1]
            if tns_A_2_p < tns_A_2_p1
                tns_A_2_i = (tns_A.lvls[2]).idx[tns_A_2_p]
                tns_A_2_i1 = (tns_A.lvls[2]).idx[tns_A_2_p1 - 1]
            else
                tns_A_2_i = 1
                tns_A_2_i1 = 0
            end
            var"##_j#298" = 1
            var"##_j#299" = min(tns_A_2_i1, var"##A_2_stop#295")
            var"##_j#300" = var"##_j#298"
            while tns_A_2_p < tns_A_2_p1
                tns_A_2_i = (tns_A.lvls[2]).idx[tns_A_2_p]
                if tns_A_2_i < tns_A_2_i
                else
                    tns_A_val = (tns_A.lvls[3]).val[tns_A_2_p]
                    tns_x_val = (tns_x.lvls[2]).val[tns_A_2_i]
                    tns_y_val = tns_y_val + tns_A_val * tns_x_val
                    tns_A_2_p += 1
                end
                var"##_j#300" = tns_A_2_i + 1
            end
            var"##_j#298" = var"##_j#299" + 1
            var"##_j#299" = min(var"##A_2_stop#295")
            var"##_j#298" = var"##_j#299" + 1
            (tns_y.lvls[2]).val[var"##i#297"] = tns_y_val
        end
    end)
end

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

    println("Bar:")
    @btime bar($ex)

    println("Julia:")
    x_ref = rand(n)
    @btime $A_ref * $x_ref
end

spmv("Boeing/ct20stif")