# FIXME: Add a test for failures of concurrent.
@testset "parallel" begin
    @info "Testing Julia Threads Parallelism and Analysis"

    let
        io = IOBuffer()
        A = Tensor(Dense(SparseList(Element(0.0))), [1 2; 3 4])
        x = Tensor(Dense(Element(0.0)), [1, 1])
        y = Tensor(Dense(Element(0.0)))
        @repl io @finch_code begin
            y .= 0
            for j = parallel(_)
                for i = _
                    y[j] += x[i] * A[walk(i), j]
                end
            end
        end

        @repl io @finch begin
            y .= 0
            for j = parallel(_)
                for i = _
                    y[j] += x[i] * A[walk(i), j]
                end
            end
        end

        @test check_output("debug_parallel_spmv.txt", String(take!(io)))
    end

    let
        io = IOBuffer()
        A = Tensor(Dense(SparseList(Element(0.0))), [1 2; 3 4])
        x = Tensor(Dense(Element(0.0)), [1, 1])
        y = Tensor(Dense(Atomic(Element(0.0))))
        @repl io @finch_code begin
            y .= 0
            for j = parallel(_)
                for i = _
                    y[j] += x[i] * A[walk(i), j]
                end
            end
        end

        @repl io @finch begin
            y .= 0
            for i = parallel(_)
                for j = _
                    y[j] += x[i] * A[walk(i), j]
                end
            end
        end

        @test check_output("debug_parallel_spmv_atomics.txt", String(take!(io)))
    end

    let
        A = Tensor(Dense(SparseList(Element(0.0))))
        x = Tensor(Dense(Element(0.0)))
        y = Tensor(Dense(Element(0.0)))
        @test_throws Finch.FinchConcurrencyError begin
            @finch_code begin
                y .= 0
                for j = parallel(_)
                    for i = _
                        y[i+j] += x[i] * A[walk(i), j]
                    end
                end
            end
        end
    end

    let
        A = Tensor(Dense(SparseList(Element(0.0))))
        x = Tensor(Dense(Element(0.0)))
        y = Tensor(Dense(Element(0.0)))

        @test_throws Finch.FinchConcurrencyError begin
            @finch_code begin
                y .= 0
                for j = parallel(_)
                    for i = _
                        y[i] += x[i] * A[walk(i), j]
                        y[i+1] += x[i] * A[walk(i), j]
                    end
                end
            end
        end
    end
    let
        A = Tensor(Dense(SparseList(Element(0.0))))
        x = Tensor(Dense(Element(0.0)))
        y = Tensor(Dense(Element(0.0)))

        @test_throws Finch.FinchConcurrencyError begin
            @finch_code begin
                y .= 0
                for j = parallel(_)
                    for i = _
                        y[i] += x[i] * A[walk(i), j]
                        y[i+1] *= x[i] * A[walk(i), j]
                    end
                end
            end
        end
    end

    #https://github.com/willow-ahrens/Finch.jl/issues/317
    let
        A = rand(5, 5)
        B = rand(5, 5)

        @test_throws Finch.FinchConcurrencyError begin
            @finch_code begin
                for j = _
                    for i = parallel(_)
                        B[i, j] = A[i, j]
                        B[i+1, j] = A[i, j]
                    end
                end
            end
        end
    end

    let
        # Computes a horizontal blur a row at a time
        input = Tensor(Dense(Dense(Element(0.0))))
        output = Tensor(Dense(Dense(Element(0.0))))
        cpu = CPU(Threads.nthreads())
        tmp = moveto(Tensor(Dense(Element(0))), CPULocalMemory(cpu))

        check_output("parallel_blur.jl", @finch_code begin
            output .= 0
            for y = parallel(_, cpu)
                tmp .= 0
                for x = _
                    tmp[x] += input[x-1, y] + input[x, y] + input[x+1, y]
                end

                for x = _
                    output[x, y] = tmp[x]
                end
            end
        end)
    end

    let
        # Computes a horizontal blur a row at a time
        input = Tensor(Dense(SparseList(Element(0.0))))
        output = Tensor(Dense(Dense(Element(0.0))))
        cpu = CPU(Threads.nthreads())
        tmp = moveto(Tensor(Dense(Element(0))), CPULocalMemory(cpu))

        check_output("parallel_blur_sparse.jl", @finch_code begin
            output .= 0
            for y = parallel(_, cpu)
                tmp .= 0
                for x = _
                    tmp[x] += input[x-1, y] + input[x, y] + input[x+1, y]
                end

                for x = _
                    output[x, y] = tmp[x]
                end
            end
        end)
    end
end
