if isfile(joinpath(@__DIR__, "test_embed_simple"))
    @testset "embed" begin

        io = IOBuffer()
        run(sequence(`$(joinpath(@__DIR__, "test_embed_simple"))`, stdout = io, stderr=io))
        @test check_output("embed/test_embed_simple.txt", String(take!(io)))

        io = IOBuffer()
        try
            run(sequence(`$(joinpath(@__DIR__, "test_embed_not_initialized"))`, stdout = io, stderr=io))
        catch
        end
        @test check_output("embed/test_embed_not_initialized.txt", String(take!(io)))

        io = IOBuffer()
        try
            run(sequence(`$(joinpath(@__DIR__, "test_embed_not_rooted"))`, stdout = io, stderr=io))
        catch
        end
        @test check_output("embed/test_embed_not_rooted.txt", String(take!(io)))
    end
end