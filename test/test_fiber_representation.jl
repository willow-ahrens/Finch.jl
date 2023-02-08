using Finch
using Base.Meta
using Test

include("utils.jl")

@testset "fiber representation" begin
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

            @test diff("format_representation_$key.txt", String(take!(io)))
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
        dropdefaults!(allocate_fiber(Dense(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "@fiber(sl(e(zero))", key = "sl_e") do arr
        dropdefaults!(allocate_fiber(SparseList(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "@fiber(sv(e(zero))", key = "sv_e") do arr
        dropdefaults!(allocate_fiber(SparseVBL(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "@fiber(rl(zero)", key = "rl") do arr
        dropdefaults!(allocate_fiber(RepeatRLE(zero(eltype(arr)))), arr)
    end
    test_format(vecs, name = "@fiber(sm(e(zero))", key = "sm_e") do arr
        dropdefaults!(allocate_fiber(SparseBytemap(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "@fiber(sh{1}(e(zero))", key = "sh1_e") do arr
        dropdefaults!(allocate_fiber(SparseHash{1}(Element(zero(eltype(arr))))), arr)
    end
    test_format(vecs, name = "@fiber(sc{1}(e(zero))", key = "sc1_e") do arr
        dropdefaults!(allocate_fiber(SparseCoo{1}(Element(zero(eltype(arr))))), arr)
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
        dropdefaults!(allocate_fiber(Dense(Dense(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(d(sl(e(zero)))", key = "d_sl_e") do arr
        dropdefaults!(allocate_fiber(Dense(SparseList(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(d(sv(e(zero)))", key = "d_sv_e") do arr
        dropdefaults!(allocate_fiber(Dense(SparseVBL(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(d(rl(zero))", key = "d_rl") do arr
        dropdefaults!(allocate_fiber(Dense(RepeatRLE(zero(eltype(arr))))), arr)
    end
    test_format(mats, name = "@fiber(d(sm(e(zero)))", key = "d_sm_e") do arr
        dropdefaults!(allocate_fiber(Dense(SparseBytemap(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(d(sh{1}(e(zero)))", key = "d_sh1_e") do arr
        dropdefaults!(allocate_fiber(Dense(SparseHash{1}(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(d(sc{1}(e(zero)))", key = "d_sc1_e") do arr
        dropdefaults!(allocate_fiber(Dense(SparseCoo{1}(Element(zero(eltype(arr)))))), arr)
    end

    test_format(mats, name = "@fiber(sl(d(e(zero)))", key = "sl_d_e") do arr
        dropdefaults!(allocate_fiber(SparseList(Dense(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(sl(sl(e(zero)))", key = "sl_sl_e") do arr
        dropdefaults!(allocate_fiber(SparseList(SparseList(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(sl(sv(e(zero)))", key = "sl_sv_e") do arr
        dropdefaults!(allocate_fiber(SparseList(SparseVBL(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(sl(rl(zero))", key = "sl_rl") do arr
        dropdefaults!(allocate_fiber(SparseList(RepeatRLE(zero(eltype(arr))))), arr)
    end
    test_format(mats, name = "@fiber(sl(sm(e(zero)))", key = "sl_sm_e") do arr
        dropdefaults!(allocate_fiber(SparseList(SparseBytemap(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(sl(sh{1}(e(zero)))", key = "sl_sh1_e") do arr
        dropdefaults!(allocate_fiber(SparseList(SparseHash{1}(Element(zero(eltype(arr)))))), arr)
    end
    test_format(mats, name = "@fiber(sl(sc{1}(e(zero)))", key = "sl_sc1_e") do arr
        dropdefaults!(allocate_fiber(SparseList(SparseCoo{1}(Element(zero(eltype(arr)))))), arr)
    end
end