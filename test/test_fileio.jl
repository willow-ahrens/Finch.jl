using Pkg
@testset "fileio" begin
    if haskey(Pkg.project().dependencies, "HDF5")
        using HDF5
        using CIndices
        @info "Testing HDF5 fileio"
        A = [0.0 1.0 2.0 2.0 ;
            0.0 0.0 0.0 0.0 ;
            1.0 1.0 2.0 0.0 ;
            0.0 0.0 0.0 0.0 ]
        mktempdir() do f
            A_dense = Fiber!(Dense(Dense(Element(0.0))), A)
            A_dense_fname = joinpath(f, "A_dense.fbr")
            fbrwrite(A_dense_fname, A_dense)
            A_dense_test = fbrread(A_dense_fname)
            @test isstructequal(A_dense_test, A_dense)

            A_CSC = Fiber!(Dense(SparseList(Element(0.0))), A)
            A_CSC_fname = joinpath(f, "A_CSC.fbr")
            fbrwrite(A_CSC_fname, A_CSC)
            A_CSC_test = fbrread(A_CSC_fname)
            @test isstructequal(A_CSC_test, A_CSC)

            A_COO = Fiber!(SparseCOO{2}(Element(0.0)), A)
            A_COO_fname = joinpath(f, "A_COO.fbr")
            fbrwrite(A_COO_fname, A_COO)
            A_COO_test = fbrread(A_COO_fname)
            @test isstructequal(A_COO_test, A_COO)

            A_dense = Fiber!(Dense{CIndex{Int}}(Dense{CIndex{Int}}(Element(0.0))), A)
            A_dense_fname = joinpath(f, "A_dense.bs")
            bswrite(A_dense_fname, A_dense)
            
            A_dense_test = bsread(A_dense_fname)
                        @test isstructequal(A_dense_test, A_dense)

            A_CSC = Fiber!(Dense{CIndex{Int}}(SparseList{CIndex{Int}, CIndex{Int}}(Element(0.0))), A)
            A_CSC_fname = joinpath(f, "A_CSC.bs")
            bswrite(A_CSC_fname, A_CSC)
            A_CSC_test = bsread(A_CSC_fname)
            @test isstructequal(A_CSC_test, A_CSC)

            A_COO = Fiber!(SparseCOO{2, Tuple{CIndex{Int}, CIndex{Int}}, CIndex{Int}}(Element(0.0)), A)
            A_COO_fname = joinpath(f, "A_COO.bs")
            bswrite(A_COO_fname, A_COO)
            A_COO_test = bsread(A_COO_fname)
            println(A_COO_test)
            println(A_COO)
            @test isstructequal(A_COO_test, A_COO)
        end
    end

    if haskey(Pkg.project().dependencies, "TensorMarket")
        using TensorMarket
        @info "Testing TensorMarket fileio"
        A = [0.0 1.0 2.0 2.0 ;
            0.0 0.0 0.0 0.0 ;
            1.0 1.0 2.0 0.0 ;
            0.0 0.0 0.0 1.0 ]
        mktempdir() do f
            A_COO = Fiber!(SparseCOO{2}(Element(0.0)), A)
            A_COO_fname = joinpath(f, "A_COO.ttx")
            fttwrite(A_COO_fname, A_COO)
            A_COO_test = fttread(A_COO_fname)
            @test isstructequal(A_COO_test, A_COO)

            A_COO = Fiber!(SparseCOO{2}(Element(0.0)), A)
            A_COO_fname = joinpath(f, "A_COO.tns")
            ftnswrite(A_COO_fname, A_COO)
            A_COO_test = ftnsread(A_COO_fname)
            @test isstructequal(A_COO_test, A_COO)
        end
    end
end