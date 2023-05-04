using Pkg
@testset "fileio" begin
    if haskey(Pkg.project().dependencies, "HDF5")
        using HDF5
        @info "Testing HDF5 fileio"
        A = [0.0 1.0 2.0 2.0 ;
            0.0 0.0 0.0 0.0 ;
            1.0 1.0 2.0 0.0 ;
            0.0 0.0 0.0 0.0 ]
        mktempdir() do f
            A_dense = @fiber(d(d(e(0.0))), A)
            A_dense_fname = joinpath(f, "A_dense.fbr")
            fbrwrite(A_dense_fname, A_dense)
            A_dense_test = fbrread(A_dense_fname)
            @test isstructequal(A_dense_test, A_dense)

            A_CSC = @fiber(d(sl(e(0.0))), A)
            A_CSC_fname = joinpath(f, "A_CSC.fbr")
            fbrwrite(A_CSC_fname, A_CSC)
            A_CSC_test = fbrread(A_CSC_fname)
            @test isstructequal(A_CSC_test, A_CSC)

            A_COO = @fiber(sc{2}(e(0.0)), A)
            A_COO_fname = joinpath(f, "A_COO.fbr")
            fbrwrite(A_COO_fname, A_COO)
            A_COO_test = fbrread(A_COO_fname)
            @test isstructequal(A_COO_test, A_COO)

            A_dense = @fiber(d(d(e(0.0))), A)
            A_dense_fname = joinpath(f, "A_dense.bs")
            bswrite(A_dense_fname, A_dense)
            
            A_dense_test = bsread(A_dense_fname)
            @test isstructequal(A_dense_test, A_dense)

            A_CSC = @fiber(d(sl(e(0.0))), A)
            A_CSC_fname = joinpath(f, "A_CSC.bs")
            bswrite(A_CSC_fname, A_CSC)
            A_CSC_test = bsread(A_CSC_fname)
            @test isstructequal(A_CSC_test, A_CSC)

            A_COO = @fiber(sc{2}(e(0.0)), A)
            A_COO_fname = joinpath(f, "A_COO.bs")
            bswrite(A_COO_fname, A_COO)
            A_COO_test = bsread(A_COO_fname)
            @test isstructequal(A_COO_test, A_COO)
        end
    end
end