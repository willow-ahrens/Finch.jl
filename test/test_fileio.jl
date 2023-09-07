using Pkg
@testset "fileio" begin
    if haskey(Pkg.project().dependencies, "HDF5")
        using HDF5
        using CIndices
        @info "Testing HDF5 fileio"
        @testset "binsparse" begin
            mktempdir() do f
                for A in [
                    [false true false false ;
                    true true true true],
                    [0 1 2 2 ;
                    0 0 0 0 ;
                    1 1 2 0 ;
                    0 0 0 0 ],
                    [0.0 1.0 2.0 2.0 ;
                    0.0 0.0 0.0 0.0 ;
                    1.0 1.0 2.0 0.0 ;
                    0.0 0.0 0.0 0.0 ],
                    [0 + 1im 1 + 0im 0 + 0im ;
                    0 + 0im 1 + 0im 0 + 0im ]
                ]
                    @testset "$(typeof(A))" begin
                        for D in [
                            zero(eltype(A)),
                            one(eltype(A)),
                        ]
                            for (name, fmt) in [
                                "A_dense" => Fiber!(Dense{CIndex{Int}}(Dense{CIndex{Int}}(Element(D)))),
                                "A_CSC" => Fiber!(Dense{CIndex{Int}}(SparseList{CIndex{Int}}(Element(D)))),
                                "A_CSR" => swizzle(Fiber!(Dense{CIndex{Int}}(SparseList{CIndex{Int}}(Element(D)))), 2, 1),
                                "A_COO" => Fiber!(SparseCOO{2, Tuple{CIndex{Int}, CIndex{Int}}, CIndex{Int}}(Element(D))),
                            ]
                                @testset "binsparse $name($D)" begin
                                    fmt = copyto!(fmt, A)
                                    bswrite(joinpath(f, "$name.bs"), fmt)
                                    @test isstructequal(bsread(joinpath(f, "$name.bs")), fmt)
                                end
                            end
                        end
                    end
                end
            end
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