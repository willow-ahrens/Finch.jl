using Finch
using Base.Meta
using Test

include("utils.jl")

@testset "fiber constructors" begin

    @testset "@fiber(sl(e(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "@fiber(sl(e(0)) constructors:")

        fbr = dropdefaults!(allocate_fiber(SparseList(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseList(lvl.I, lvl.pos, lvl.idx, lvl.lvl)))
        @test isstructequal(fbr, Fiber(SparseList{Int}(lvl.I, lvl.pos, lvl.idx, lvl.lvl)))
        @test isstructequal(fbr, @fiber(sl(lvl.I, lvl.pos, lvl.idx, lvl.lvl)))
        @test isstructequal(fbr, @fiber(sl{Int}(lvl.I, lvl.pos, lvl.idx, lvl.lvl)))

        fbr = dropdefaults!(allocate_fiber(SparseList{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseList{Int16}(lvl.I, lvl.pos, lvl.idx, lvl.lvl)))
        @test isstructequal(fbr, @fiber(sl{Int16}(lvl.I, lvl.pos, lvl.idx, lvl.lvl)))

        fbr = Fiber(SparseList(7, Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseList(7, Element(0.0))))
        @test isstructequal(fbr, Fiber(SparseList{Int}(7, Element(0.0))))
        @test isstructequal(fbr, @fiber(sl(7, e(0.0))))
        @test isstructequal(fbr, @fiber(sl{Int}(7, e(0.0))))

        fbr = Fiber(SparseList{Int16}(7, Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseList(Int16(7), Element(0.0))))
        @test isstructequal(fbr, Fiber(SparseList{Int16}(7, Element(0.0))))
        @test isstructequal(fbr, @fiber(sl(Int16(7), e(0.0))))
        @test isstructequal(fbr, @fiber(sl{Int16}(7, e(0.0))))

        fbr = Fiber(SparseList(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseList(Element(0.0))))
        @test isstructequal(fbr, Fiber(SparseList{Int}(Element(0.0))))
        @test isstructequal(fbr, Fiber(SparseList(0, Element(0.0))))
        @test isstructequal(fbr, Fiber(SparseList{Int}(0, Element(0.0))))
        @test isstructequal(fbr, @fiber(sl(e(0.0))))
        @test isstructequal(fbr, @fiber(sl{Int}(e(0.0))))
        @test isstructequal(fbr, @fiber(sl(0, e(0.0))))
        @test isstructequal(fbr, @fiber(sl{Int}(0, e(0.0))))

        fbr = Fiber(SparseList{Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseList{Int16}(Element(0.0))))
        @test isstructequal(fbr, Fiber(SparseList(Int16(0), Element(0.0))))
        @test isstructequal(fbr, Fiber(SparseList{Int16}(0, Element(0.0))))
        @test isstructequal(fbr, @fiber(sl{Int16}(e(0.0))))
        @test isstructequal(fbr, @fiber(sl(Int16(0), e(0.0))))
        @test isstructequal(fbr, @fiber(sl{Int16}(0, e(0.0))))

        @test diff("format_constructors_sl_e.txt", String(take!(io)))
    end
end