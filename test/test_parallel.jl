# FIXME: Add a test for failures of concurrent.
@testset "parallel" begin
    @info "Testing Julia Threads Parallelism and Analysis"

    let
        io = IOBuffer()
        A = Fiber!(Dense(SparseList(Element(0.0))), [1 2; 3 4])
        x = Fiber!(Dense(Element(0.0)), [1, 1])
        y = Fiber!(Dense(Element(0.0)))
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
        A = Fiber!(Dense(SparseList(Element(0.0))))
        x = Fiber!(Dense(Element(0.0)))
        y = Fiber!(Dense(Element(0.0)))
        @test_throws Finch.FinchConcurrencyError try
            @finch_code begin
                y .= 0
                for j = parallel(_)
                    for i = _
                        y[i+j] += x[i] * A[walk(i), j]
                    end
                end
            end
        catch e
            @test e isa Finch.FinchConcurrencyError
            #@test !e.naive
            #@test e.withAtomics
            #@test length(e.nonInjectiveAccss) == 1
            throw(e)
        end
    end

    let
        A = Fiber!(Dense(SparseList(Element(0.0))))
        x = Fiber!(Dense(Element(0.0)))
        y = Fiber!(Dense(Element(0.0)))

        @test_throws Finch.FinchConcurrencyError try
            @finch_code begin
                y .= 0
                for j = parallel(_)
                    for i = _
                        y[i] += x[i] * A[walk(i), j]
                        y[i+1] += x[i] * A[walk(i), j]
                    end
                end
            end
        catch e
            @test e isa Finch.FinchConcurrencyError
            #@test !e.naive
            #@test e.withAtomics
            #@test length(e.nonInjectiveAccss) == 1
            throw(e)
        end
    end
    let
        A = Fiber!(Dense(SparseList(Element(0.0))))
        x = Fiber!(Dense(Element(0.0)))
        y = Fiber!(Dense(Element(0.0)))

        @test_throws Finch.FinchConcurrencyError try
            @finch_code begin
                y .= 0
                for j = parallel(_)
                    for i = _
                        y[i] += x[i] * A[walk(i), j]
                        y[i+1] *= x[i] * A[walk(i), j]
                    end
                end
            end
        catch e
            @test e isa Finch.FinchConcurrencyError
            #@test !e.naive
            #@test !e.withAtomics
            #@test length(e.nonInjectiveAccss) == 1
            #@test e.withAtomicsAndAssoc
            #@test length(e.nonAssocAssigns) == 2
            throw(e)
        end
    end

    let
        # Computes a horizontal blur a row at a time
        input = Fiber!(Dense(SparseList(Element(0.0))))
        output = Fiber!(Dense(SparseList(Element(0.0))))
        cpu = CPU(Threads.nthreads())
        tmp = Fiber!(SparseList(Element(0, CPULocalVector{Vector}(cpu))))

        @finch begin
            for y = parallel(_, cpu)
                tmp .= 0
                for x = _
                    tmp[x] += input[x-1, y] + input[x, y] + input[x+1, y]
                end

                for x = _
                    output[x, y] = tmp[x]
                end
            end
        end
    end
end
