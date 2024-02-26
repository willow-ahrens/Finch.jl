using Base.Meta

@testset "representation" begin
    @info "Testing Tensor Representation"

    function test_format(f, arrs; name, key)
        @testset "$name" begin
            io = IOBuffer()
            println(io, "$name representation:")
            println(io)
            for arr in arrs
                println(io, "array: ", arr)
                fbr = f(arr)
                @test Structure(fbr) == Structure(eval(Meta.parse(repr(fbr))))
                @test reference_isequal(fbr, arr)
                println(io, "tensor: ", repr(fbr))
            end

            @test check_output("format_representation_$key.txt", String(take!(io)))
            print(String(take!(io)))
        end
    end

    vecs = [
        [0.0, 2.0, 2.0, 0.0, 3.0, 3.0],
        [false, false, false, false],
        [false, true, false, true, false, false],
        [0.0, 0.0, 0.0, 0.0],
        fill(0.0, 5),
        fill(1.0, 5),
        [0.0, 1.0, 1.0, 2.0, 2.0, 0.0, 0.0, 3.0, 0.0],
        begin
            x = zeros(1111)
            x[2] = 20.0
            x[3]=30.0
            x[555]=5550.0
            x[666]=6660.0
            x
        end,
    ]

    test_format(vecs, name = "Tensor(Dense(Element(zero)))", key = "d_e") do arr
        dropdefaults!(Tensor(Dense(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "Tensor(SparseList(Element(zero)))", key = "sl_e") do arr
        dropdefaults!(Tensor(SparseList(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "Tensor(SparseVBL(Element(zero)))", key = "sv_e") do arr
        dropdefaults!(Tensor(SparseVBL(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "Tensor(RepeatRLE(zero))", key = "rl") do arr
        dropdefaults!(Tensor(RepeatRLE(zero(eltype(arr)))), arr)
    end
    test_format(vecs, name = "Tensor(SparseByteMap(Element(zero)))", key = "sm_e") do arr
        dropdefaults!(Tensor(SparseByteMap(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "Tensor(SparseDict(Element(zero)))", key = "sh_e") do arr
        dropdefaults!(Tensor(Sparse(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "Tensor(SparseHash{1}(Element(zero)))", key = "sh1_e") do arr
        dropdefaults!(Tensor(SparseHash{1}(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "Tensor(SparseCOO{1}(Element(zero)))", key = "sc1_e") do arr
        dropdefaults!(Tensor(SparseCOO{1}(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "Tensor(SparseTriangle{1}(Element(zero)))", key = "st1_e") do arr
        dropdefaults!(Tensor(SparseTriangle{1}(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "Tensor(SparseRLE(Element(zero)))", key = "srl_e") do arr
        dropdefaults!(Tensor(SparseRLE(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "Tensor(DenseRLE(Element(zero)))", key = "drl_e") do arr
        dropdefaults!(Tensor(DenseRLE(Element(zero(eltype(arr))))), arr)
    end


    mats = [
        fill(0.0, 5, 5),
        fill(1.0, 5, 5),
        [0.0 1.0 2.0 2.0 ;
         0.0 0.0 0.0 0.0 ;
         1.0 1.0 2.0 0.0 ;
         0.0 0.0 0.0 0.0 ]
    ]

    test_format(mats, name = "Tensor(Dense(Dense(Element(zero))))", key = "d_d_e") do arr
        dropdefaults!(Tensor(Dense(Dense(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(Dense(SparseList(Element(zero))))", key = "d_sl_e") do arr
        dropdefaults!(Tensor(Dense(SparseList(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(Dense(SparseVBL(Element(zero))))", key = "d_sv_e") do arr
        dropdefaults!(Tensor(Dense(SparseVBL(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(Dense(RepeatRLE(zero)))", key = "d_rl") do arr
        dropdefaults!(Tensor(Dense(RepeatRLE(zero(eltype(arr))))), arr)
    end
    test_format(mats, name = "Tensor(Dense(SparseByteMap(Element(zero))))", key = "d_sm_e") do arr
        dropdefaults!(Tensor(Dense(SparseByteMap(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(Dense(SparseDict(Element(zero))))", key = "d_sh_e") do arr
        dropdefaults!(Tensor(Dense(Sparse(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(Dense(SparseHash{1}(Element(zero))))", key = "d_sh1_e") do arr
        dropdefaults!(Tensor(Dense(SparseHash{1}(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(Dense(SparseCOO{1}(Element(zero))))", key = "d_sc1_e") do arr
        dropdefaults!(Tensor(Dense(SparseCOO{1}(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(Dense(SparseTriangle{1}(Element(zero))))", key = "d_st1_e") do arr
        dropdefaults!(Tensor(Dense(SparseTriangle{1}(Element(zero(eltype(arr)))))), arr)
    end

    test_format(mats, name = "Tensor(SparseList(Dense(Element(zero))))", key = "sl_d_e") do arr
        dropdefaults!(Tensor(SparseList(Dense(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(SparseList(SparseList(Element(zero))))", key = "sl_sl_e") do arr
        dropdefaults!(Tensor(SparseList(SparseList(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(SparseList(SparseVBL(Element(zero))))", key = "sl_sv_e") do arr
        dropdefaults!(Tensor(SparseList(SparseVBL(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(SparseList(RepeatRLE(zero)))", key = "sl_rl") do arr
        dropdefaults!(Tensor(SparseList(RepeatRLE(zero(eltype(arr))))), arr)
    end
    test_format(mats, name = "Tensor(SparseList(SparseByteMap(Element(zero))))", key = "sl_sm_e") do arr
        dropdefaults!(Tensor(SparseList(SparseByteMap(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(SparseList(SparseDict(Element(zero))))", key = "sl_sh_e") do arr
        dropdefaults!(Tensor(SparseList(Sparse(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(SparseList(SparseHash{1}(Element(zero))))", key = "sl_sh1_e") do arr
        dropdefaults!(Tensor(SparseList(SparseHash{1}(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(SparseList(SparseCOO{1}(Element(zero))))", key = "sl_sc1_e") do arr
        dropdefaults!(Tensor(SparseList(SparseCOO{1}(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(SparseList(SparseTriangle{1}(Element(zero))))", key = "sl_st_e") do arr
        dropdefaults!(Tensor(SparseList(SparseTriangle{1}(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(SparseList(SparseRLE(Element(zero))))", key = "sl_srl_e") do arr
        dropdefaults!(Tensor(SparseList(SparseRLE(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(SparseRLE(SparseList(Element(zero))))", key = "srl_sl_e") do arr
        dropdefaults!(Tensor(SparseRLE(SparseList(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(Dense(SparseRLE(Element(zero))))", key = "d_srl_e") do arr
        dropdefaults!(Tensor(Dense(SparseRLE(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(SparseRLE(Dense(Element(zero))))", key = "srl_d_e") do arr
        dropdefaults!(Tensor(SparseRLE(Dense(Element(zero(eltype(arr)))))), arr)
    end

    test_format(mats, name = "Tensor(SparseList(DenseRLE(Element(zero))))", key = "sl_srl_e") do arr
        dropdefaults!(Tensor(SparseList(DenseRLE(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(DenseRLE(SparseList(Element(zero))))", key = "srl_sl_e") do arr
        dropdefaults!(Tensor(DenseRLE(SparseList(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(Dense(DenseRLE(Element(zero))))", key = "d_srl_e") do arr
        dropdefaults!(Tensor(Dense(DenseRLE(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "Tensor(DenseRLE(Dense(Element(zero))))", key = "srl_d_e") do arr
        dropdefaults!(Tensor(DenseRLE(Dense(Element(zero(eltype(arr)))))), arr)
    end

    # Test SingleList

    @testset "SingleList level" begin
        # 1D
        @test Tensor(SingleList(Element(0.0)), [0, 0, 10]) == [0, 0, 10]
        @test Tensor(SingleList(Element(0.0)), [0, 0, 10]) != [0, 20, 10]
        @test_throws Finch.FinchProtocolError Tensor(SingleList(Element(0.0)), [0, 20, 10])

        # 2D
        dense_single = Tensor(Dense(SingleList(Element(0.0))), [10 0 0; 0 20 0; 0 0 30])
        sparse_single = Tensor(SparseList(SingleList(Element(0.0))), [10 0 0; 0 20 0; 0 0 30])
        @test dense_single == sparse_single
        @test_throws Finch.FinchProtocolError Tensor(SingleList(SingleList(Element(0.0))), [10 0 0; 0 20 0; 0 0 30])
        
        @test Tensor(SingleList(Dense(Element(0.0))), [0 0 0; 0 0 30; 0 0 30]) == [0 0 0; 0 0 30; 0 0 30]
        @test_throws Finch.FinchProtocolError Tensor(SingleList(SingleList(Element(0.0))), [0 0 0; 0 0 30; 0 0 30])
    end

    @testset "SingleRLE level" begin
        # 1D
        @test Tensor(SingleRLE(Element(0)), [0, 10, 0]) == [0, 10, 0]
        @test_throws Finch.FinchProtocolError Tensor(SingleRLE(Element(0)), [0, 10, 10]) 


        x = Tensor(SingleRLE(Element(0)), 10);
        @finch begin for i = extent(3,6); x[~i] = 1 end end
        @test x == [0,0,1,1,1,1,0,0,0,0]
    end
end
