@testset "parallel" begin
    @info "Testing Julia Threads Parallelism and Analysis"
     

    let
        io = IOBuffer()

        @repl io A = sparse([0 0 3.3; 1.1 0 0; 2.2 0 4.4; 0 0 5.5])
        @repl io y = [1.0, 2.0, 3.0, 4.0]
        @repl io x = [1, 2, 3]
        
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
        @test_throws ParallelAnalysisResults try
            @finch_code begin
                y .= 0
                for j = parallel(_)
                    for i = _
                        y[i+j] += x[i] * A[walk(i), j]
                    end
                end
            end
        catch e
            @test e isa ParallelAnalysisResults
            @test !e.naive
            @test e.withAtomics
            @test length(e.nonInjectiveAccss) == 1
            throw(e)
        end
    end

    let
        @test_throws ParallelAnalysisResults try
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
            @test e isa ParallelAnalysisResults
            @test !e.naive
            @test e.withAtomics
            @test length(e.nonInjectiveAccss) == 0
            throw(e)
        end
    end
        let
        @test_throws ParallelAnalysisResults try
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
            @test e isa ParallelAnalysisResults
            @test !e.naive
            @test !e.withAtomics
            @test length(e.nonInjectiveAccss) == 0
            @test e.withAtomicsAndAssoc
            @test length(e.nonAssocAssigns) == 2
            throw(e)
        end
    end


    # Should run
    # Check if it is not injective.
    # 



end
