using Finch
using Base.Meta
using Test

include("utils.jl")

@testset "fiber constructors" begin

    @testset "@fiber(sl(e(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "@fiber(sl(e(0)) constructors:")

        fbr = dropdefaults!(Fiber!(SparseList(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseList(lvl.I, lvl.pos, lvl.idx, lvl.lvl)))
        @test isstructequal(fbr, Fiber(SparseList{Int}(lvl.I, lvl.pos, lvl.idx, lvl.lvl)))

        fbr = dropdefaults!(Fiber!(SparseList{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseList{Int16}(lvl.I, lvl.pos, lvl.idx, lvl.lvl)))

        fbr = Fiber!(SparseList(7, Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseList(7, Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseList{Int}(7, Element(0.0))))
        @test isstructequal(fbr, @fiber(sl(7, e(0.0))))
        @test isstructequal(fbr, @fiber(sl{Int}(7, e(0.0))))

        fbr = Fiber!(SparseList{Int16}(7, Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseList(Int16(7), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseList{Int16}(7, Element(0.0))))
        @test isstructequal(fbr, @fiber(sl(Int16(7), e(0.0))))
        @test isstructequal(fbr, @fiber(sl{Int16}(7, e(0.0))))

        fbr = Fiber!(SparseList(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseList(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseList{Int}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseList(0, Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseList{Int}(0, Element(0.0))))
        @test isstructequal(fbr, @fiber(sl(e(0.0))))
        @test isstructequal(fbr, @fiber(sl{Int}(e(0.0))))
        @test isstructequal(fbr, @fiber(sl(0, e(0.0))))
        @test isstructequal(fbr, @fiber(sl{Int}(0, e(0.0))))

        fbr = Fiber!(SparseList{Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseList{Int16}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseList(Int16(0), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseList{Int16}(0, Element(0.0))))
        @test isstructequal(fbr, @fiber(sl{Int16}(e(0.0))))
        @test isstructequal(fbr, @fiber(sl(Int16(0), e(0.0))))
        @test isstructequal(fbr, @fiber(sl{Int16}(0, e(0.0))))

        @test diff("format_constructors_sl_e.txt", String(take!(io)))
    end

    @testset "@fiber(sv(e(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "@fiber(sv(e(0)) constructors:")

        fbr = dropdefaults!(Fiber!(SparseVBL(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseVBL(lvl.I, lvl.pos, lvl.idx, lvl.ofs, lvl.lvl)))
        @test isstructequal(fbr, Fiber(SparseVBL{Int}(lvl.I, lvl.pos, lvl.idx, lvl.ofs, lvl.lvl)))

        fbr = dropdefaults!(Fiber!(SparseVBL{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseVBL{Int16}(lvl.I, lvl.pos, lvl.idx, lvl.ofs, lvl.lvl)))

        fbr = Fiber!(SparseVBL(7, Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseVBL(7, Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseVBL{Int}(7, Element(0.0))))
        @test isstructequal(fbr, @fiber(sv(7, e(0.0))))
        @test isstructequal(fbr, @fiber(sv{Int}(7, e(0.0))))

        fbr = Fiber!(SparseVBL{Int16}(7, Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseVBL(Int16(7), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseVBL{Int16}(7, Element(0.0))))
        @test isstructequal(fbr, @fiber(sv(Int16(7), e(0.0))))
        @test isstructequal(fbr, @fiber(sv{Int16}(7, e(0.0))))

        fbr = Fiber!(SparseVBL(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseVBL(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseVBL{Int}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseVBL(0, Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseVBL{Int}(0, Element(0.0))))
        @test isstructequal(fbr, @fiber(sv(e(0.0))))
        @test isstructequal(fbr, @fiber(sv{Int}(e(0.0))))
        @test isstructequal(fbr, @fiber(sv(0, e(0.0))))
        @test isstructequal(fbr, @fiber(sv{Int}(0, e(0.0))))

        fbr = Fiber!(SparseVBL{Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseVBL{Int16}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseVBL(Int16(0), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseVBL{Int16}(0, Element(0.0))))
        @test isstructequal(fbr, @fiber(sv{Int16}(e(0.0))))
        @test isstructequal(fbr, @fiber(sv(Int16(0), e(0.0))))
        @test isstructequal(fbr, @fiber(sv{Int16}(0, e(0.0))))

        @test diff("format_constructors_sv_e.txt", String(take!(io)))
    end

    @testset "@fiber(sm(e(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "@fiber(sm(e(0)) constructors:")

        fbr = dropdefaults!(Fiber!(SparseBytemap(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseBytemap(lvl.I, lvl.pos, lvl.tbl, lvl.srt, lvl.lvl)))
        @test isstructequal(fbr, Fiber(SparseBytemap{Int}(lvl.I, lvl.pos, lvl.tbl, lvl.srt, lvl.lvl)))

        fbr = dropdefaults!(Fiber!(SparseBytemap{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseBytemap{Int16}(lvl.I, lvl.pos, lvl.tbl, lvl.srt, lvl.lvl)))

        fbr = Fiber!(SparseBytemap(7, Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseBytemap(7, Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseBytemap{Int}(7, Element(0.0))))
        @test isstructequal(fbr, @fiber(sm(7, e(0.0))))
        @test isstructequal(fbr, @fiber(sm{Int}(7, e(0.0))))

        fbr = Fiber!(SparseBytemap{Int16}(7, Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseBytemap(Int16(7), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseBytemap{Int16}(7, Element(0.0))))
        @test isstructequal(fbr, @fiber(sm(Int16(7), e(0.0))))
        @test isstructequal(fbr, @fiber(sm{Int16}(7, e(0.0))))

        fbr = Fiber!(SparseBytemap(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseBytemap(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseBytemap{Int}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseBytemap(0, Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseBytemap{Int}(0, Element(0.0))))
        @test isstructequal(fbr, @fiber(sm(e(0.0))))
        @test isstructequal(fbr, @fiber(sm{Int}(e(0.0))))
        @test isstructequal(fbr, @fiber(sm(0, e(0.0))))
        @test isstructequal(fbr, @fiber(sm{Int}(0, e(0.0))))

        fbr = Fiber!(SparseBytemap{Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseBytemap{Int16}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseBytemap(Int16(0), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseBytemap{Int16}(0, Element(0.0))))
        @test isstructequal(fbr, @fiber(sm{Int16}(e(0.0))))
        @test isstructequal(fbr, @fiber(sm(Int16(0), e(0.0))))
        @test isstructequal(fbr, @fiber(sm{Int16}(0, e(0.0))))

        @test diff("format_constructors_sm_e.txt", String(take!(io)))
    end

    @testset "@fiber(sc{1}(e(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "@fiber(sc{1}(e(0)) constructors:")

        fbr = dropdefaults!(Fiber!(SparseCoo{1}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseCoo{1}(lvl.I, lvl.tbl, lvl.pos, lvl.lvl)))
        @test isstructequal(fbr, Fiber(SparseCoo{1, Tuple{Int}}(lvl.I, lvl.tbl, lvl.pos, lvl.lvl)))

        fbr = dropdefaults!(Fiber!(SparseCoo{1, Tuple{Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseCoo{1, Tuple{Int16}}(lvl.I, lvl.tbl, lvl.pos, lvl.lvl)))

        fbr = Fiber!(SparseCoo{1}((7,), Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseCoo{1}((7,), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseCoo{1, Tuple{Int}}((7,), Element(0.0))))
        @test isstructequal(fbr, @fiber(sc{1}((7,), e(0.0))))
        @test isstructequal(fbr, @fiber(sc{1, Tuple{Int}}((7,), e(0.0))))

        fbr = Fiber!(SparseCoo{1}{Tuple{Int16}}(7, Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseCoo{1}((Int16(7),), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseCoo{1, Tuple{Int16}}((7,), Element(0.0))))
        @test isstructequal(fbr, @fiber(sc{1}((Int16(7),), e(0.0))))
        @test isstructequal(fbr, @fiber(sc{1, Tuple{Int16}}(7, e(0.0))))

        fbr = Fiber!(SparseCoo{1}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseCoo{1}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseCoo{1, Tuple{Int}}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseCoo{1}((0,), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseCoo{1, Tuple{Int}}((0,), Element(0.0))))
        @test isstructequal(fbr, @fiber(sc{1}(e(0.0))))
        @test isstructequal(fbr, @fiber(sc{1, Tuple{Int}}(e(0.0))))
        @test isstructequal(fbr, @fiber(sc{1}((0,), e(0.0))))
        @test isstructequal(fbr, @fiber(sc{1, Tuple{Int}}((0,), e(0.0))))

        fbr = Fiber!(SparseCoo{1, Tuple{Int16}}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseCoo{1, Tuple{Int16}}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseCoo{1}((Int16(0),), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseCoo{1, Tuple{Int16}}((0,), Element(0.0))))
        @test isstructequal(fbr, @fiber(sc{1, Tuple{Int16}}(e(0.0))))
        @test isstructequal(fbr, @fiber(sc{1}((Int16(0),), e(0.0))))
        @test isstructequal(fbr, @fiber(sc{1, Tuple{Int16}}((0,), e(0.0))))

        @test diff("format_constructors_sc1_e.txt", String(take!(io)))
    end

    @testset "@fiber(sc{2}(e(0))" begin
        io = IOBuffer()
        arr = [0.0 2.0 2.0 0.0 3.0 3.0;
               1.0 0.0 7.0 1.0 0.0 0.0;
               0.0 0.0 0.0 0.0 0.0 9.0]

        println(io, "@fiber(sc{2}(e(0)) constructors:")

        fbr = dropdefaults!(Fiber!(SparseCoo{2}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseCoo{2}(lvl.I, lvl.tbl, lvl.pos, lvl.lvl)))
        @test isstructequal(fbr, Fiber(SparseCoo{2, Tuple{Int, Int}}(lvl.I, lvl.tbl, lvl.pos, lvl.lvl)))

        fbr = dropdefaults!(Fiber!(SparseCoo{2, Tuple{Int16, Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseCoo{2, Tuple{Int16, Int16}}(lvl.I, lvl.tbl, lvl.pos, lvl.lvl)))

        fbr = Fiber!(SparseCoo{2}((3, 7), Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseCoo{2}((3, 7,), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseCoo{2}{Tuple{Int, Int}}((3, 7,), Element(0.0))))
        @test isstructequal(fbr, @fiber(sc{2}((3, 7,), e(0.0))))
        @test isstructequal(fbr, @fiber(sc{2, Tuple{Int, Int}}((3, 7,), e(0.0))))

        fbr = Fiber!(SparseCoo{2, Tuple{Int16, Int16}}((3, 7), Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseCoo{2}((Int16(3), Int16(7),), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseCoo{2, Tuple{Int16, Int16}}((3, 7,), Element(0.0))))
        @test isstructequal(fbr, @fiber(sc{2}((Int16(3), Int16(7),), e(0.0))))
        @test isstructequal(fbr, @fiber(sc{2, Tuple{Int16, Int16}}((3, 7,), e(0.0))))

        fbr = Fiber!(SparseCoo{2}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseCoo{2}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseCoo{2, Tuple{Int, Int}}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseCoo{2}((0,0,), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseCoo{2, Tuple{Int, Int}}((0,0,), Element(0.0))))
        @test isstructequal(fbr, @fiber(sc{2}(e(0.0))))
        @test isstructequal(fbr, @fiber(sc{2}{Tuple{Int, Int}}(e(0.0))))
        @test isstructequal(fbr, @fiber(sc{2}((0,0,), e(0.0))))
        @test isstructequal(fbr, @fiber(sc{2, Tuple{Int, Int}}((0,0,), e(0.0))))

        fbr = Fiber!(SparseCoo{2, Tuple{Int16, Int16}}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseCoo{2, Tuple{Int16, Int16}}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseCoo{2}((Int16(0), Int16(0),), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseCoo{2, Tuple{Int16, Int16}}((0,0), Element(0.0))))
        @test isstructequal(fbr, @fiber(sc{2}{Tuple{Int16, Int16}}(e(0.0))))
        @test isstructequal(fbr, @fiber(sc{2}((Int16(0), Int16(0),), e(0.0))))
        @test isstructequal(fbr, @fiber(sc{2, Tuple{Int16, Int16}}((0,0,), e(0.0))))

        @test diff("format_constructors_sc2_e.txt", String(take!(io)))
    end

    @testset "@fiber(sh{1}(e(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "@fiber(sh{1}(e(0)) constructors:")

        fbr = dropdefaults!(Fiber!(SparseHash{1}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseHash{1}(lvl.I, lvl.tbl, lvl.pos, lvl.srt, lvl.lvl)))
        @test isstructequal(fbr, Fiber(SparseHash{1, Tuple{Int}}(lvl.I, lvl.tbl, lvl.pos, lvl.srt, lvl.lvl)))

        fbr = dropdefaults!(Fiber!(SparseHash{1, Tuple{Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseHash{1, Tuple{Int16}}(lvl.I, lvl.tbl, lvl.pos, lvl.srt, lvl.lvl)))

        fbr = Fiber!(SparseHash{1}((7,), Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseHash{1}((7,), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseHash{1, Tuple{Int}}((7,), Element(0.0))))
        @test isstructequal(fbr, @fiber(sh{1}((7,), e(0.0))))
        @test isstructequal(fbr, @fiber(sh{1, Tuple{Int}}((7,), e(0.0))))

        fbr = Fiber!(SparseHash{1}{Tuple{Int16}}(7, Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseHash{1}((Int16(7),), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseHash{1, Tuple{Int16}}((7,), Element(0.0))))
        @test isstructequal(fbr, @fiber(sh{1}((Int16(7),), e(0.0))))
        @test isstructequal(fbr, @fiber(sh{1, Tuple{Int16}}(7, e(0.0))))

        fbr = Fiber!(SparseHash{1}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseHash{1}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseHash{1, Tuple{Int}}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseHash{1}((0,), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseHash{1, Tuple{Int}}((0,), Element(0.0))))
        @test isstructequal(fbr, @fiber(sh{1}(e(0.0))))
        @test isstructequal(fbr, @fiber(sh{1, Tuple{Int}}(e(0.0))))
        @test isstructequal(fbr, @fiber(sh{1}((0,), e(0.0))))
        @test isstructequal(fbr, @fiber(sh{1, Tuple{Int}}((0,), e(0.0))))

        fbr = Fiber!(SparseHash{1, Tuple{Int16}}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseHash{1, Tuple{Int16}}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseHash{1}((Int16(0),), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseHash{1, Tuple{Int16}}((0,), Element(0.0))))
        @test isstructequal(fbr, @fiber(sh{1, Tuple{Int16}}(e(0.0))))
        @test isstructequal(fbr, @fiber(sh{1}((Int16(0),), e(0.0))))
        @test isstructequal(fbr, @fiber(sh{1, Tuple{Int16}}((0,), e(0.0))))

        @test diff("format_constructors_sh1_e.txt", String(take!(io)))
    end

    @testset "@fiber(sh{2}(e(0))" begin
        io = IOBuffer()
        arr = [0.0 2.0 2.0 0.0 3.0 3.0;
               1.0 0.0 7.0 1.0 0.0 0.0;
               0.0 0.0 0.0 0.0 0.0 9.0]

        println(io, "@fiber(sh{2}(e(0)) constructors:")

        fbr = dropdefaults!(Fiber!(SparseHash{2}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseHash{2}(lvl.I, lvl.tbl, lvl.pos, lvl.srt, lvl.lvl)))
        @test isstructequal(fbr, Fiber(SparseHash{2, Tuple{Int, Int}}(lvl.I, lvl.tbl, lvl.pos, lvl.srt, lvl.lvl)))

        fbr = dropdefaults!(Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber(SparseHash{2, Tuple{Int16, Int16}}(lvl.I, lvl.tbl, lvl.pos, lvl.srt, lvl.lvl)))

        fbr = Fiber!(SparseHash{2}((3, 7), Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseHash{2}((3, 7,), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseHash{2}{Tuple{Int, Int}}((3, 7,), Element(0.0))))
        @test isstructequal(fbr, @fiber(sh{2}((3, 7,), e(0.0))))
        @test isstructequal(fbr, @fiber(sh{2, Tuple{Int, Int}}((3, 7,), e(0.0))))

        fbr = Fiber!(SparseHash{2, Tuple{Int16, Int16}}((3, 7), Element(0.0)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseHash{2}((Int16(3), Int16(7),), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseHash{2, Tuple{Int16, Int16}}((3, 7,), Element(0.0))))
        @test isstructequal(fbr, @fiber(sh{2}((Int16(3), Int16(7),), e(0.0))))
        @test isstructequal(fbr, @fiber(sh{2, Tuple{Int16, Int16}}((3, 7,), e(0.0))))

        fbr = Fiber!(SparseHash{2}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseHash{2}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseHash{2, Tuple{Int, Int}}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseHash{2}((0,0,), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseHash{2, Tuple{Int, Int}}((0,0,), Element(0.0))))
        @test isstructequal(fbr, @fiber(sh{2}(e(0.0))))
        @test isstructequal(fbr, @fiber(sh{2}{Tuple{Int, Int}}(e(0.0))))
        @test isstructequal(fbr, @fiber(sh{2}((0,0,), e(0.0))))
        @test isstructequal(fbr, @fiber(sh{2, Tuple{Int, Int}}((0,0,), e(0.0))))

        fbr = Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test isstructequal(fbr, Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseHash{2}((Int16(0), Int16(0),), Element(0.0))))
        @test isstructequal(fbr, Fiber!(SparseHash{2, Tuple{Int16, Int16}}((0,0), Element(0.0))))
        @test isstructequal(fbr, @fiber(sh{2}{Tuple{Int16, Int16}}(e(0.0))))
        @test isstructequal(fbr, @fiber(sh{2}((Int16(0), Int16(0),), e(0.0))))
        @test isstructequal(fbr, @fiber(sh{2, Tuple{Int16, Int16}}((0,0,), e(0.0))))

        @test diff("format_constructors_sh2_e.txt", String(take!(io)))
    end

end