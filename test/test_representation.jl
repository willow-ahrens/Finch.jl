using Base.Meta

@testset "representation" begin
    @info "Testing Fiber Representation"

    function test_format(f, arrs; name, key)
        @testset "$name" begin
            io = IOBuffer()
            println(io, "$name representation:")
            println(io)
            for arr in arrs
                println(io, "array: ", arr)
                fbr = f(arr)
                @test isstructequal(fbr, eval(Meta.parse(repr(fbr))))
                @test reference_isequal(fbr, arr)
                println(io, "fiber: ", repr(fbr))
            end

            @test check_output("format_representation_$key.txt", String(take!(io)))
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

    test_format(vecs, name = "@fiber(d(e(zero))", key = "d_e") do arr
        dropdefaults!(Fiber!(Dense(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "@fiber(sl(e(zero))", key = "sl_e") do arr
        dropdefaults!(Fiber!(SparseList(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "@fiber(svb(e(zero))", key = "sv_e") do arr
        dropdefaults!(Fiber!(SparseVBL(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "@fiber(rl(zero)", key = "rl") do arr
        dropdefaults!(Fiber!(RepeatRLE(zero(eltype(arr)))), arr)
    end
    test_format(vecs, name = "@fiber(sbm(e(zero))", key = "sm_e") do arr
        dropdefaults!(Fiber!(SparseByteMap(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "@fiber(sh{1}(e(zero))", key = "sh1_e") do arr
        dropdefaults!(Fiber!(SparseHash{1}(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "@fiber(sc{1}(e(zero))", key = "sc1_e") do arr
        dropdefaults!(Fiber!(SparseCOO{1}(Element(zero(eltype(arr))))), arr)
    end

    mats = [
        fill(0.0, 5, 5),
        fill(1.0, 5, 5),
        [0.0 1.0 2.0 2.0 ;
         0.0 0.0 0.0 0.0 ;
         1.0 1.0 2.0 0.0 ;
         0.0 0.0 0.0 0.0 ]
    ]

    test_format(mats, name = "@fiber(d(d(e(zero)))", key = "d_d_e") do arr
        dropdefaults!(Fiber!(Dense(Dense(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(d(sl(e(zero)))", key = "d_sl_e") do arr
        dropdefaults!(Fiber!(Dense(SparseList(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(d(svb(e(zero)))", key = "d_sv_e") do arr
        dropdefaults!(Fiber!(Dense(SparseVBL(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(d(rl(zero))", key = "d_rl") do arr
        dropdefaults!(Fiber!(Dense(RepeatRLE(zero(eltype(arr))))), arr)
    end
    test_format(mats, name = "@fiber(d(sbm(e(zero)))", key = "d_sm_e") do arr
        dropdefaults!(Fiber!(Dense(SparseByteMap(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(d(sh{1}(e(zero)))", key = "d_sh1_e") do arr
        dropdefaults!(Fiber!(Dense(SparseHash{1}(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(d(sc{1}(e(zero)))", key = "d_sc1_e") do arr
        dropdefaults!(Fiber!(Dense(SparseCOO{1}(Element(zero(eltype(arr)))))), arr)
    end

    test_format(mats, name = "@fiber(sl(d(e(zero)))", key = "sl_d_e") do arr
        dropdefaults!(Fiber!(SparseList(Dense(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(sl(sl(e(zero)))", key = "sl_sl_e") do arr
        dropdefaults!(Fiber!(SparseList(SparseList(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(sl(svb(e(zero)))", key = "sl_sv_e") do arr
        dropdefaults!(Fiber!(SparseList(SparseVBL(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(sl(rl(zero))", key = "sl_rl") do arr
        dropdefaults!(Fiber!(SparseList(RepeatRLE(zero(eltype(arr))))), arr)
    end
    test_format(mats, name = "@fiber(sl(sbm(e(zero)))", key = "sl_sm_e") do arr
        dropdefaults!(Fiber!(SparseList(SparseByteMap(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(sl(sh{1}(e(zero)))", key = "sl_sh1_e") do arr
        dropdefaults!(Fiber!(SparseList(SparseHash{1}(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(sl(sc{1}(e(zero)))", key = "sl_sc1_e") do arr
        dropdefaults!(Fiber!(SparseList(SparseCOO{1}(Element(zero(eltype(arr)))))), arr)
    end
end