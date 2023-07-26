using Finch
using SparseArrays
using MatrixDepot
using BenchmarkTools

#A = @fiber(d(sl(e(0.0))), SparseMatrixCSC(matrixdepot("Boeing/ct20stif")))
A = fiber(SparseMatrixCSC(matrixdepot("SNAP/soc-Epinions1")))
(m, n) = size(A)
x = @fiber(d(e(0.0)), randn(m))
y = @fiber(d(e(0.0)))

#prgm = Finch.@finch_program_instance begin
@btime begin
    (A, x, y) = $(A, x, y)
    Finch.@finch begin
        y .= 0
        for j = parallel(_)
            for i = _
                y[j] += A[walk(i), j] * x[i]
            end
        end
    end
end

println(Finch.@finch_kernel function spmv(y, A, x)
    y .= 0
    for j = parallel(_)
        for i = _
            y[j] += A[walk(i), j] * x[i]
        end
    end
end)

#=
#What's wrong with this function? Why is it not faster?
function spmv(y::Fiber{DenseLevel{Int64, ElementLevel{0.0, Float64}}}, A::Fiber{DenseLevel{Int64, SparseListLevel{Int64, Int64, ElementLevel{0.0, Float64}}}}, x::Fiber{DenseLevel{Int64, ElementLevel{0.0, Float64}}})
    @inbounds begin
            y_lvl = y.lvl
            y_lvl_2 = y_lvl.lvl
            A_lvl = A.lvl
            A_lvl_2 = A_lvl.lvl
            A_lvl_3 = A_lvl_2.lvl
            x_lvl = x.lvl
            x_lvl_2 = x_lvl.lvl
            x_lvl.shape == A_lvl_2.shape || throw(DimensionMismatch("mismatched dimension limits ($(x_lvl.shape) != $(A_lvl_2.shape))"))
            Finch.resize_if_smaller!(y_lvl_2.val, A_lvl.shape)
            Finch.fill_range!(y_lvl_2.val, 0.0, 1, A_lvl.shape)
            Threads.@threads for i_4 = 1:Threads.nthreads()
                    Threads.nthreads()
                    phase_start_2 = (max)(1, (+)(1, (fld)((*)(A_lvl.shape, (+)(i_4, -1)), Threads.nthreads())))
                    phase_stop_2 = (min)(A_lvl.shape, (fld)((*)(A_lvl.shape, i_4), Threads.nthreads()))
                    if phase_stop_2 >= phase_start_2
                        for j_6 = phase_start_2:phase_stop_2
                            y_lvl_q = (1 - 1) * A_lvl.shape + j_6
                            A_lvl_q = (1 - 1) * A_lvl.shape + j_6
                            A_lvl_2_q = A_lvl_2.ptr[A_lvl_q]
                            A_lvl_2_q_stop = A_lvl_2.ptr[A_lvl_q + 1]
                            if A_lvl_2_q < A_lvl_2_q_stop
                                A_lvl_2_i1 = A_lvl_2.idx[A_lvl_2_q_stop - 1]
                            else
                                A_lvl_2_i1 = 0
                            end
                            phase_stop_3 = (min)(x_lvl.shape, A_lvl_2_i1)
                            if phase_stop_3 >= 1
                                i = 1
                                if A_lvl_2.idx[A_lvl_2_q] < 1
                                    A_lvl_2_q = Finch.scansearch(A_lvl_2.idx, 1, A_lvl_2_q, A_lvl_2_q_stop - 1)
                                end
                                while i <= phase_stop_3
                                    A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                                    phase_stop_4 = (min)(phase_stop_3, A_lvl_2_i)
                                    if A_lvl_2_i == phase_stop_4
                                        A_lvl_3_val_2 = A_lvl_3.val[A_lvl_2_q]
                                        x_lvl_q = (1 - 1) * x_lvl.shape + phase_stop_4
                                        x_lvl_2_val_2 = x_lvl_2.val[x_lvl_q]
                                        y_lvl_2.val[y_lvl_q] = (+)(y_lvl_2.val[y_lvl_q], (*)(x_lvl_2_val_2, A_lvl_3_val_2))
                                        A_lvl_2_q += 1
                                    end
                                    i = phase_stop_4 + 1
                                end
                            end
                        end
                    end
                    Threads.nthreads()
                end
            qos = 1 * A_lvl.shape
            resize!(y_lvl_2.val, qos)
            (y = Fiber((DenseLevel){Int64}(y_lvl_2, A_lvl.shape)),)
        end
end

@btime spmv($y, $A, $x)
=#

@btime begin
    (A, x, y) = $((A, x, y))
    Finch.@finch begin
        y .= 0
        for j = _
            for i = _
                y[i] += A[walk(i), j] * x[j]
            end
        end
    end
end

#debug the program

#debug = Finch.begin_debug(prgm)
