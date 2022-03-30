using MatrixDepot
using Finch
using BenchmarkTools
using SparseArrays
using LinearAlgebra
using Cthulhu
using Profile

function tri(mtx)
    println("tri: $mtx")
    A_ref = SparseMatrixCSC(mdopen(mtx).A)
    (m, n) = size(A_ref)
    A = Finch.Fiber(
        Solid(m,
        HollowList(n, A_ref.colptr, A_ref.rowval,
        Element{0.0, Float64}(A_ref.nzval))))
    A2 = A
    A3 = A
    A4 = A
    C = Finch.Fiber(
        Element{0.0, Float64}(zeros(1)))

    #ex = Finch.@index_program_instance @loop i j k C[] += A[i, k] * A2[i, j] * A3[j, k]
    #display(Finch.execute_code_lowered(:ex, typeof(ex)))
    #println()
    foo(ex) = (@inbounds begin
        C_lvl = ex.body.lhs.tns.tns.lvl
        C_lvl_val_q = length(ex.body.lhs.tns.tns.lvl.val)
        C_lvl_val = 0.0
        A_lvl = (ex.body.rhs.args[1]).tns.tns.lvl
        A_lvl_I = A_lvl.I
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_I = A_lvl_2.I
        A_lvl_2_pos_q = length(A_lvl_2.pos)
        A_lvl_2_idx_q = length(A_lvl_2.idx)
        A_lvl_3 = A_lvl_2.lvl
        A_lvl_3_val_q = length(A_lvl_2.lvl.val)
        A_lvl_3_val = 0.0
        A2_lvl = (ex.body.rhs.args[2]).tns.tns.lvl
        A2_lvl_I = A2_lvl.I
        A2_lvl_2 = A2_lvl.lvl
        A2_lvl_2_I = A2_lvl_2.I
        A2_lvl_2_pos_q = length(A2_lvl_2.pos)
        A2_lvl_2_idx_q = length(A2_lvl_2.idx)
        A2_lvl_3 = A2_lvl_2.lvl
        A2_lvl_3_val_q = length(A2_lvl_2.lvl.val)
        A2_lvl_3_val = 0.0
        A3_lvl = (ex.body.rhs.args[3]).tns.tns.lvl
        A3_lvl_I = A3_lvl.I
        A3_lvl_2 = A3_lvl.lvl
        A3_lvl_2_I = A3_lvl_2.I
        A3_lvl_2_pos_q = length(A3_lvl_2.pos)
        A3_lvl_2_idx_q = length(A3_lvl_2.idx)
        A3_lvl_3 = A3_lvl_2.lvl
        A3_lvl_3_val_q = length(A3_lvl_2.lvl.val)
        A3_lvl_3_val = 0.0
        A_lvl_I == A2_lvl_I || throw(DimensionMismatch("mismatched dimension starts"))
        A2_lvl_I == A_lvl_I || throw(DimensionMismatch("mismatched dimension starts"))
        A2_lvl_2_I == A3_lvl_I || throw(DimensionMismatch("mismatched dimension starts"))
        A3_lvl_I == A2_lvl_2_I || throw(DimensionMismatch("mismatched dimension starts"))
        A_lvl_2_I == A3_lvl_2_I || throw(DimensionMismatch("mismatched dimension starts"))
        A3_lvl_2_I == A_lvl_2_I || throw(DimensionMismatch("mismatched dimension starts"))
        if C_lvl_val_q < 4
            resize!(C_lvl.val, 4)
        end
        C_lvl_val_q = 4
        for C_lvl_q = 1:4
            C_lvl.val[C_lvl_q] = 0.0
        end
        C_lvl_val_q < 1 && (C_lvl_val_q = refill!(C_lvl.val, 0.0, C_lvl_val_q, 1))
        C_lvl_val = C_lvl.val[1]
        for i = 1:A_lvl_I
            A2_lvl_2_p = A2_lvl_2.pos[i]
            A2_lvl_2_p1 = A2_lvl_2.pos[i + 1]
            if A2_lvl_2_p < A2_lvl_2_p1
                A2_lvl_2_i = A2_lvl_2.idx[A2_lvl_2_p]
                A2_lvl_2_i1 = A2_lvl_2.idx[A2_lvl_2_p1 - 1]
            else
                A2_lvl_2_i = 1
                A2_lvl_2_i1 = 0
            end
            j_start = 1
            j_step = min(A2_lvl_2_i1, A2_lvl_2_I)
            j_start_2 = j_start
            while A2_lvl_2_p < A2_lvl_2_p1
                A2_lvl_2_i = A2_lvl_2.idx[A2_lvl_2_p]
                j_step_2 = min(A2_lvl_2_i, j_step)
                if j_step_2 == A2_lvl_2_i
                    A2_lvl_3_val = A2_lvl_3.val[A2_lvl_2_p]
                    j = j_step_2
                    A_lvl_2_p = A_lvl_2.pos[i]
                    A_lvl_2_p1 = A_lvl_2.pos[i + 1]
                    if A_lvl_2_p < A_lvl_2_p1
                        A_lvl_2_i = A_lvl_2.idx[A_lvl_2_p]
                        A_lvl_2_i1 = A_lvl_2.idx[A_lvl_2_p1 - 1]
                    else
                        A_lvl_2_i = 1
                        A_lvl_2_i1 = 0
                    end
                    A3_lvl_2_p = A3_lvl_2.pos[j]
                    A3_lvl_2_p1 = A3_lvl_2.pos[j + 1]
                    if A3_lvl_2_p < A3_lvl_2_p1
                        A3_lvl_2_i = A3_lvl_2.idx[A3_lvl_2_p]
                        A3_lvl_2_i1 = A3_lvl_2.idx[A3_lvl_2_p1 - 1]
                    else
                        A3_lvl_2_i = 1
                        A3_lvl_2_i1 = 0
                    end
                    k_start = 1
                    k_step = min(A_lvl_2_i1, A3_lvl_2_i1, A_lvl_2_I)
                    if k_start <= k_step
                        k_start_2 = k_start
                        while k_start_2 <= k_step
                            A_lvl_2_i = A_lvl_2.idx[A_lvl_2_p]
                            A3_lvl_2_i = A3_lvl_2.idx[A3_lvl_2_p]
                            k_step_2 = min(A_lvl_2_i, A3_lvl_2_i)
                            if k_step_2 > k_step
                                k_step_2 = k_step
                                break
                            elseif k_step_2 == A_lvl_2_i && k_step_2 == A3_lvl_2_i
                                A_lvl_3_val = A_lvl_3.val[A_lvl_2_p]
                                A3_lvl_3_val = A3_lvl_3.val[A3_lvl_2_p]
                                k = k_step_2
                                C_lvl_val = C_lvl_val + A_lvl_3_val * A2_lvl_3_val * A3_lvl_3_val
                                A_lvl_2_p += 1
                                A3_lvl_2_p += 1
                            elseif k_step_2 == A3_lvl_2_i
                                #A3_lvl_3_val = A3_lvl_3.val[A3_lvl_2_p]
                                A3_lvl_2_p += 1
                            elseif k_step_2 == A_lvl_2_i
                                #A_lvl_3_val = A_lvl_3.val[A_lvl_2_p]
                                A_lvl_2_p += 1
                            end
                            k_start_2 = k_step_2 + 1
                        end
                        k_start = k_step + 1
                    end
                    k_step = min(A_lvl_2_i1, A_lvl_2_I)
                    if k_start <= k_step
                        k_start = k_step + 1
                    end
                    k_step = min(A3_lvl_2_i1, A_lvl_2_I)
                    if k_start <= k_step
                        k_start = k_step + 1
                    end
                    k_step = min(A_lvl_2_I)
                    if k_start <= k_step
                        k_start = k_step + 1
                    end
                    A2_lvl_2_p += 1
                else
                end
                j_start_2 = j_step_2 + 1
            end
            j_start = j_step + 1
            j_step = min(A2_lvl_2_I)
            j_start = j_step + 1
        end
        C_lvl.val[1] = C_lvl_val
        (C = Fiber(C_lvl, Finch.RootEnvironment()),)
    end)
    #@descend foo(ex)
    #exit()
    #=
    #./taco "a += B(i, k) * C(i, j) * D(j, k)" -f=B:ds -i=B:./web-BerkStan.mtx -f=C:ds -i=C:./web-BerkStan.mtx -f=D:ds -i=D:./web-BerkStan.mtx -time=10 -o=a:foo.ttx
    A = Finch.Fiber(
        Solid(m,
        Solid(n,
        Element{0.0, Float64}(A_ref.nzval))))
    ex = Finch.@index_program_instance @loop i j k C[] += A[i, k] * A[i, j] * A[j, k]
    display(Finch.execute_code_lowered(:ex, typeof(ex)))
    println()
    exit()
    ex = Finch.@index_program_instance @loop i j k C[] += A[i, k] * A[i, j] * A[j, k]
    display(Finch.execute_code_lowered(:ex, typeof(ex)))
    println()
    exit()
    ex = Finch.@index_program_instance @loop i j k C[] += A[i, k::gallop] * A2[i, j] * A3[j, k::gallop]
    display(Finch.execute_code_lowered(:ex, typeof(ex)))
    println()
    exit()
    exit()
    =#
    @index @loop i j k C[] += A[i, k::gallop] * A2[i, j] * A3[j, k::gallop]
    println(FiberArray(C)[])
    @index @loop i j k C[] += A[i, k] * A2[i, j] * A3[j, k]
    println(FiberArray(C)[])
    println(sum(A_ref .* (A_ref * A_ref)))
    #println(@descend execute(ex))

    foo(Finch.@index_program_instance @loop i j k C[] += A[i, k] * A2[i, j] * A3[j, k])
    
    #@profile @index @loop i j k C[] += A[i, k] * A2[i, j] * A3[j, k]
    #Profile.print()


    println("Finch:")
    @btime (A = $A; A2=$A; A3=$A; C = $C; @index @loop i j k C[] += A[i, k] * A2[i, j] * A3[j, k])

    println("foo:")
    @btime (A = $A; A2=$A; A3=$A; C = $C; $foo(Finch.@index_program_instance @loop i j k C[] += A[i, k] * A2[i, j] * A3[j, k]))

    println("Finch(gallop):")
    @btime (A = $A; A2=$A; A3=$A; C = $C; @index @loop i j k C[] += A[i, k::gallop] * A2[i, j] * A3[j, k::gallop])

    println("Julia:")
    @btime sum($A_ref .* ($A_ref * $(transpose(A_ref))))
end

function quad(mtx)
    println("quad: $mtx")
    A_ref = SparseMatrixCSC(mdopen(mtx).A)
    (m, n) = size(A_ref)
    A = Finch.Fiber(
        Solid(m,
        HollowList(n, A_ref.colptr, A_ref.rowval,
        Element{0.0, Float64}(A_ref.nzval))))
    A2 = A
    A3 = A
    A4 = A
    C = Finch.Fiber(
        Element{0.0, Float64}(zeros(1)))

    println("Finch:")
    @btime (A=A2=A3=A4=A5=A6=$A; C = $C; @index @loop i j k l C[] += A[i, j] * A2[i, k] * A3[i, l] * A4[j,k] * A5[j, l] * A6[k,l])

    println("Finch (gallop):")
    @btime (A=A2=A3=A4=A5=A6=$A; C = $C; @index @loop i j k l C[] += A[i, j] * A2[i, k] * A3[i, l::gallop] * A4[j,k] * A5[j, l::gallop] * A6[k,l::gallop])
end

quad("Bai/bfwb398")

tri("Boeing/ct20stif")
tri("SNAP/web-NotreDame")
tri("SNAP/roadNet-PA")
tri("VDOL/spaceStation_5")
tri("DIMACS10/sd2010")
tri("Bai/bfwb398")
tri("SNAP/soc-Epinions1")
tri("SNAP/email-EuAll")
tri("SNAP/wiki-Talk")
#tri("SNAP/web-BerkStan")
exit()
