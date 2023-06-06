@testset "debug" begin
    @info "Testing Compiler Debugging"
    function test_debug_code(code; imax=10000)
        codes:: Vector{Any}
        debug = Finch.stage_code(code)
        append!(codes, debug)
        i = 0
        while true
           global debug = Finch.step_code(debug, sdisplay=false)
           append!(codes, debug)
           global i+=1
           if i > imax
              return nothing
           end
           if Finch.iscompiled(debug.code)
              break
           end
        end
        ret = end_debug(debug)
        return codes
     end
     

    y = @fiber d(e(0.0))
    A = @fiber d(sl(e(0.0)))
    x = @fiber sl(e(0.0))

    code1 = Finch.@finch_program_instance begin
        @loop j i y[i] += A[i, j] * x[j]
    end

    @test check_output("debug_spmv_resume.txt", test_debug_code(code1))

end