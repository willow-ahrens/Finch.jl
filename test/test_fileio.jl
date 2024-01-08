using Pkg
@testset "fileio" begin
    if haskey(Pkg.project().dependencies, "HDF5")
        using HDF5
        using CIndices
        @info "Testing HDF5 fileio"
        @testset "h5 binsparse" begin
            mktempdir() do f
                A = [0.0 1.0 2.0 2.0 ;
                0.0 0.0 0.0 0.0 ;
                1.0 1.0 2.0 0.0 ;
                0.0 0.0 0.0 1.0 ]
                A_COO = Fiber(SparseCOO{2}(Element(0.0)), A)
                A_COO_fname = joinpath(f, "A_COO.bsp.h5")
                fwrite(A_COO_fname, A_COO)
                A_COO_test = fread(A_COO_fname)
                @test A_COO_test == A_COO

                for (iA, A) in enumerate([
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
                ])
                    @testset "$(typeof(A))" begin
                        for (iD, D) in [
                            0 => zero(eltype(A)),
                            1 => one(eltype(A)),
                        ]
                            elem = Element{D, eltype(A), Int}()
                            for (name, fmt) in [
                                "A_dense" => swizzle(Fiber(Dense{Int}(Dense{Int}(elem))), 2, 1),
                                "A_denseC" => Fiber(Dense{Int}(Dense{Int}(elem))),
                                "A_CSC" => Fiber(Dense{Int}(SparseList{Int}(elem))),
                                "A_CSR" => swizzle(Fiber(Dense{Int}(SparseList{Int}(elem))), 2, 1),
                                "A_COO" => swizzle(Fiber(SparseCOO{2, Tuple{Int, Int}}(elem)), 2, 1),
                                "A_COOC" => Fiber(SparseCOO{2, Tuple{Int, Int}}(elem)),
                            ]
                                @testset "binsparse $name($D)" begin
                                    fmt = copyto!(fmt, A)
                                    fname = joinpath(f, "foo.bsp.h5")
                                    bspwrite(fname, fmt)
                                    @test Structure(fmt) == Structure(bspread(fname))
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if haskey(Pkg.project().dependencies, "NPZ")
        using NPZ
        using CIndices
        @info "Testing NPY fileio"
        @testset "npy binsparse" begin
            mktempdir() do f
                A = [0.0 1.0 2.0 2.0 ;
                0.0 0.0 0.0 0.0 ;
                1.0 1.0 2.0 0.0 ;
                0.0 0.0 0.0 1.0 ]
                A_COO = Fiber(SparseCOO{2}(Element(0.0)), A)
                A_COO_fname = joinpath(f, "A_COO.bspnpy")
                fwrite(A_COO_fname, A_COO)
                A_COO_test = fread(A_COO_fname)
                @test A_COO_test == A_COO

                for (iA, A) in enumerate([
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
                ])
                    @testset "$(typeof(A))" begin
                        for (iD, D) in [
                            0 => zero(eltype(A)),
                            1 => one(eltype(A)),
                        ]
                            elem = Element{D, eltype(A), Int}()
                            for (name, fmt) in [
                                "A_dense" => swizzle(Fiber(Dense{Int}(Dense{Int}(elem))), 2, 1),
                                "A_denseC" => Fiber(Dense{Int}(Dense{Int}(elem))),
                                "A_CSC" => Fiber(Dense{Int}(SparseList{Int}(elem))),
                                "A_CSR" => swizzle(Fiber(Dense{Int}(SparseList{Int}(elem))), 2, 1),
                                "A_COO" => swizzle(Fiber(SparseCOO{2, Tuple{Int, Int}}(elem)), 2, 1),
                                "A_COOC" => Fiber(SparseCOO{2, Tuple{Int, Int}}(elem)),
                            ]
                                @testset "binsparse $name($D)" begin
                                    fmt = copyto!(fmt, A)
                                    fname = joinpath(f, "A$(iA)_D$(iD)_$name.bspnpy")
                                    bspwrite(fname, fmt)
                                    @test Structure(fmt) == Structure(bspread(fname))
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
            A_COO = Fiber(SparseCOO{2}(Element(0.0)), A)
            A_COO_fname = joinpath(f, "A_COO.ttx")
            fttwrite(A_COO_fname, A_COO)
            A_COO_test = fttread(A_COO_fname)
            @test Structure(A_COO_test) == Structure(A_COO)

            A_COO_fname2 = joinpath(f, "A_COO.ttx")
            fwrite(A_COO_fname2, A_COO)
            A_COO_test = fread(A_COO_fname2)
            @test A_COO_test == A_COO

            A_COO_fname2 = joinpath(f, "A_COO.mtx")
            fwrite(A_COO_fname2, A_COO)
            A_COO_test = fread(A_COO_fname2)
            @test A_COO_test == A_COO

            A_COO = Fiber(SparseCOO{2}(Element(0.0)), A)
            A_COO_fname = joinpath(f, "A_COO.tns")
            ftnswrite(A_COO_fname, A_COO)
            A_COO_test = ftnsread(A_COO_fname)
            @test Structure(A_COO_test) == Structure(A_COO)

            A_COO_fname2 = joinpath(f, "A_COO.tns")
            fwrite(A_COO_fname2, A_COO)
            A_COO_test = fread(A_COO_fname2)
            @test A_COO_test == A_COO
        end
    end
end