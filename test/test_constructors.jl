@testset "constructors" begin
    @info "Testing Fiber Constructors"

    using Base.Meta
    
    @testset "Fiber!(SparseList(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseList(Element(0))) constructors:")

        fbr = dropdefaults!(Fiber!(SparseList(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseList(lvl.lvl, lvl.shape, lvl.ptr, lvl.idx)))
        @test Structure(fbr) == Structure(Fiber(SparseList{Int}(lvl.lvl, lvl.shape, lvl.ptr, lvl.idx)))

        fbr = dropdefaults!(Fiber!(SparseList{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseList{Int16}(lvl.lvl, lvl.shape, lvl.ptr, lvl.idx)))

        fbr = Fiber!(SparseList(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseList(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseList{Int}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseList(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseList{Int}(Element(0.0), 7)))

        fbr = Fiber!(SparseList{Int16}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseList(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Fiber!(SparseList{Int16}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseList(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Fiber!(SparseList{Int16}(Element(0.0), 7)))

        fbr = Fiber!(SparseList(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseList(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseList{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseList(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseList{Int}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseList(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseList{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseList(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseList{Int}(Element(0.0), 0)))

        fbr = Fiber!(SparseList{Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseList{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseList(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Fiber!(SparseList{Int16}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseList{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseList(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Fiber!(SparseList{Int16}(Element(0.0), 0)))

        @test check_output("format_constructors_sl_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseVBL(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseVBL(Element(0))) constructors:")

        fbr = dropdefaults!(Fiber!(SparseVBL(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseVBL(lvl.lvl, lvl.shape, lvl.ptr, lvl.idx, lvl.ofs)))
        @test Structure(fbr) == Structure(Fiber(SparseVBL{Int}(lvl.lvl, lvl.shape, lvl.ptr, lvl.idx, lvl.ofs)))

        fbr = dropdefaults!(Fiber!(SparseVBL{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseVBL{Int16}(lvl.lvl, lvl.shape, lvl.ptr, lvl.idx, lvl.ofs)))

        fbr = Fiber!(SparseVBL(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseVBL(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL{Int}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL{Int}(Element(0.0), 7)))

        fbr = Fiber!(SparseVBL{Int16}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseVBL(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL{Int16}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL{Int16}(Element(0.0), 7)))

        fbr = Fiber!(SparseVBL(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseVBL(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL{Int}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL{Int}(Element(0.0), 0)))

        fbr = Fiber!(SparseVBL{Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseVBL{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL{Int16}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Fiber!(SparseVBL{Int16}(Element(0.0), 0)))

        @test check_output("format_constructors_sv_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseByteMap(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseByteMap(Element(0))) constructors:")

        fbr = dropdefaults!(Fiber!(SparseByteMap(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseByteMap(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))
        @test Structure(fbr) == Structure(Fiber(SparseByteMap{Int}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))

        fbr = dropdefaults!(Fiber!(SparseByteMap{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseByteMap{Int16}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))

        fbr = Fiber!(SparseByteMap(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap{Int}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap{Int}(Element(0.0), 7)))

        fbr = Fiber!(SparseByteMap{Int16}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap{Int16}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap{Int16}(Element(0.0), 7)))

        fbr = Fiber!(SparseByteMap(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap{Int}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap{Int}(Element(0.0), 0)))

        fbr = Fiber!(SparseByteMap{Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap{Int16}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Fiber!(SparseByteMap{Int16}(Element(0.0), 0)))

        @test check_output("format_constructors_sm_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseCOO{1}(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseCOO{1}(Element(0))) constructors:")

        fbr = dropdefaults!(Fiber!(SparseCOO{1}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseCOO{1}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl)))
        @test Structure(fbr) == Structure(Fiber(SparseCOO{1, Tuple{Int}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl)))

        fbr = dropdefaults!(Fiber!(SparseCOO{1, Tuple{Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseCOO{1, Tuple{Int16}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl)))

        fbr = Fiber!(SparseCOO{1}(Element(0.0), (7,)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1, Tuple{Int}}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1, Tuple{Int}}(Element(0.0), (7,))))

        fbr = Fiber!(SparseCOO{1, Tuple{Int16}}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1}(Element(0.0), (Int16(7),))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1, Tuple{Int16}}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1}(Element(0.0), (Int16(7),))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1, Tuple{Int16}}(Element(0.0), 7)))

        fbr = Fiber!(SparseCOO{1}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1, Tuple{Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1, Tuple{Int}}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1, Tuple{Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1, Tuple{Int}}(Element(0.0), (0,))))

        fbr = Fiber!(SparseCOO{1, Tuple{Int16}}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1, Tuple{Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1}(Element(0.0), (Int16(0),))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1, Tuple{Int16}}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1, Tuple{Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1}(Element(0.0), (Int16(0),))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{1, Tuple{Int16}}(Element(0.0), (0,))))

        @test check_output("format_constructors_sc1_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseCOO{2}(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0 2.0 2.0 0.0 3.0 3.0;
               1.0 0.0 7.0 1.0 0.0 0.0;
               0.0 0.0 0.0 0.0 0.0 9.0]

        println(io, "Fiber!(SparseCOO{2}(Element(0))) constructors:")

        fbr = dropdefaults!(Fiber!(SparseCOO{2}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseCOO{2}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl)))
        @test Structure(fbr) == Structure(Fiber(SparseCOO{2, Tuple{Int, Int}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl)))

        fbr = dropdefaults!(Fiber!(SparseCOO{2, Tuple{Int16, Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseCOO{2, Tuple{Int16, Int16}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl)))

        fbr = Fiber!(SparseCOO{2}(Element(0.0), (3, 7)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2, Tuple{Int, Int}}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2, Tuple{Int, Int}}(Element(0.0), (3, 7,))))

        fbr = Fiber!(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2}(Element(0.0), (Int16(3), Int16(7),))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2}(Element(0.0), (Int16(3), Int16(7),),)))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7,))))

        fbr = Fiber!(SparseCOO{2}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2, Tuple{Int, Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2}(Element(0.0), (0,0,))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2, Tuple{Int, Int}}(Element(0.0), (0,0,))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2, Tuple{Int, Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2}(Element(0.0), (0,0,))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2, Tuple{Int, Int}}(Element(0.0), (0,0,))))

        fbr = Fiber!(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2}(Element(0.0), (Int16(0), Int16(0),))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0), (0,0))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2}(Element(0.0), (Int16(0), Int16(0),))))
        @test Structure(fbr) == Structure(Fiber!(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0), (0,0,))))

        @test check_output("format_constructors_sc2_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseHash{1}(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseHash{1}(Element(0))) constructors:")

        fbr = dropdefaults!(Fiber!(SparseHash{1}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseHash{1}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))
        @test Structure(fbr) == Structure(Fiber(SparseHash{1, Tuple{Int}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))

        fbr = dropdefaults!(Fiber!(SparseHash{1, Tuple{Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseHash{1, Tuple{Int16}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))

        fbr = Fiber!(SparseHash{1}(Element(0.0), (7,)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1, Tuple{Int}}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1, Tuple{Int}}(Element(0.0), (7,))))

        fbr = Fiber!(SparseHash{1, Tuple{Int16}}(Element(0.0), (7,)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1}(Element(0.0), (Int16(7),))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1, Tuple{Int16}}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1}(Element(0.0), (Int16(7),))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1, Tuple{Int16}}(Element(0.0), (7,))))

        fbr = Fiber!(SparseHash{1}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1, Tuple{Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1, Tuple{Int}}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1, Tuple{Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1, Tuple{Int}}(Element(0.0), (0,))))

        fbr = Fiber!(SparseHash{1, Tuple{Int16}}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1, Tuple{Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1}(Element(0.0), (Int16(0),))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1, Tuple{Int16}}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1, Tuple{Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1}(Element(0.0), (Int16(0),))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{1, Tuple{Int16}}(Element(0.0), (0,))))

        @test check_output("format_constructors_sh1_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseHash{2}(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0 2.0 2.0 0.0 3.0 3.0;
               1.0 0.0 7.0 1.0 0.0 0.0;
               0.0 0.0 0.0 0.0 0.0 9.0]

        println(io, "Fiber!(SparseHash{2}(Element(0))) constructors:")

        fbr = dropdefaults!(Fiber!(SparseHash{2}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseHash{2}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))
        @test Structure(fbr) == Structure(Fiber(SparseHash{2, Tuple{Int, Int}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))

        fbr = dropdefaults!(Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseHash{2, Tuple{Int16, Int16}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))

        fbr = Fiber!(SparseHash{2}(Element(0.0), (3, 7)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2, Tuple{Int, Int}}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2, Tuple{Int, Int}}(Element(0.0), (3, 7,))))

        fbr = Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2}(Element(0.0), (Int16(3), Int16(7),))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2}(Element(0.0), (Int16(3), Int16(7),))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7,))))

        fbr = Fiber!(SparseHash{2}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2, Tuple{Int, Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2}(Element(0.0), (0,0,))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2, Tuple{Int, Int}}(Element(0.0), (0,0,))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2, Tuple{Int, Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2}(Element(0.0), (0,0,))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2, Tuple{Int, Int}}(Element(0.0), (0,0,))))

        fbr = Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2}(Element(0.0), (Int16(0), Int16(0),))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0), (0,0))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2}(Element(0.0), (Int16(0), Int16(0),))))
        @test Structure(fbr) == Structure(Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0), (0,0,))))

        @test check_output("format_constructors_sh2_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseTriangle{2}(Element(0)))" begin
        io = IOBuffer()
        arr = [1.0  2.0  3.0  4.0  5.0; 
               6.0  7.0  8.0  9.0  10.0; 
               11.0 12.0 13.0 14.0 15.0; 
               16.0 17.0 18.0 19.0 20.0; 
               21.0 22.0 23.0 24.0 25.0]

        println(io, "Fiber!(SparseTriangle{2}(Element(0))) constructors:")

        fbr = dropdefaults!(Fiber!(SparseTriangle{2}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseTriangle{2}(lvl.lvl, lvl.shape)))
        @test Structure(fbr) == Structure(Fiber(SparseTriangle{2, Int}(lvl.lvl, lvl.shape)))

        fbr = dropdefaults!(Fiber!(SparseTriangle{2, Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseTriangle{2, Int16}(lvl.lvl, lvl.shape)))

        fbr = Fiber!(SparseTriangle{2}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2, Int}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2, Int}(Element(0.0), 7)))

        fbr = Fiber!(SparseTriangle{2, Int16}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2}(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2, Int16}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2}(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2, Int16}(Element(0.0), 7)))

        fbr = Fiber!(SparseTriangle{2}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2, Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2, Int}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2, Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2, Int}(Element(0.0), 0)))

        fbr = Fiber!(SparseTriangle{2, Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2, Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2}(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2, Int16}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2, Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2}(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{2, Int16}(Element(0.0), 0)))

        @test check_output("format_constructors_st2_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseTriangle{3}(Element(0)))" begin
        io = IOBuffer()
        arr = collect(reshape(1.0 .* (1:27), 3, 3, 3))

        println(io, "Fiber!(SparseTriangle{3}(Element(0))) constructors:")

        fbr = dropdefaults!(Fiber!(SparseTriangle{3}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseTriangle{3}(lvl.lvl, lvl.shape)))
        @test Structure(fbr) == Structure(Fiber(SparseTriangle{3, Int}(lvl.lvl, lvl.shape)))

        fbr = dropdefaults!(Fiber!(SparseTriangle{3, Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseTriangle{3, Int16}(lvl.lvl, lvl.shape)))

        fbr = Fiber!(SparseTriangle{3}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3, Int}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3, Int}(Element(0.0), 7)))

        fbr = Fiber!(SparseTriangle{3, Int16}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3}(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3, Int16}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3}(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3, Int16}(Element(0.0), 7)))

        fbr = Fiber!(SparseTriangle{3}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3, Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3, Int}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3, Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3, Int}(Element(0.0), 0)))

        fbr = Fiber!(SparseTriangle{3, Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3, Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3}(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3, Int16}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3, Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3}(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Fiber!(SparseTriangle{3, Int16}(Element(0.0), 0)))

        @test check_output("format_constructors_st3_e.txt", String(take!(io))) 
    end
     
    @testset "Fiber!(SparseRLE(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseRLE(Element(0))) constructors:")

        fbr = dropdefaults!(Fiber!(SparseRLE(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseRLE(lvl.lvl, lvl.shape, lvl.ptr, lvl.left, lvl.right)))
        @test Structure(fbr) == Structure(Fiber(SparseRLE{Int}(lvl.lvl, lvl.shape, lvl.ptr, lvl.left, lvl.right)))

        fbr = dropdefaults!(Fiber!(SparseRLE{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber(SparseRLE{Int16}(lvl.lvl, lvl.shape, lvl.ptr, lvl.left, lvl.right)))

        fbr = Fiber!(SparseRLE(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseRLE(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE{Int}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE{Int}(Element(0.0), 7)))

        fbr = Fiber!(SparseRLE{Int16}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseRLE(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE{Int16}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE{Int16}(Element(0.0), 7)))

        fbr = Fiber!(SparseRLE(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseRLE(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE{Int}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE{Int}(Element(0.0), 0)))

        fbr = Fiber!(SparseRLE{Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Fiber!(SparseRLE{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE{Int16}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Fiber!(SparseRLE{Int16}(Element(0.0), 0)))

        @test check_output("format_constructors_srl_e.txt", String(take!(io)))
    end

      @testset "Fiber!(Dense(Pointer(Dense(Element(0)))))" begin
          io = IOBuffer()
          arr = [0.0 2.0 2.0 0.0 3.0 3.0;
              1.0 0.0 7.0 1.0 0.0 0.0;
              0.0 0.0 0.0 0.0 0.0 9.0]
          
          println(io, "Fiber!(Dense(Pointer(Dense(Element(0))))):")
          
          fbr = dropdefaults!(Fiber!(Dense(Pointer(Dense(Element(0))))), arr)

          # sublvl = Fiber!(Dense(Element(0)), [])
          # col1 = dropdefaults!(Fiber!((Dense(Element(0)))), arr[:, 1])
          # col2 = dropdefaults!(Fiber!((Dense(Element(0)))), arr[:, 2])
          # col3 = dropdefaults!(Fiber!((Dense(Element(0)))), arr[:, 3])
          # col4 = dropdefaults!(Fiber!((Dense(Element(0)))), arr[:, 4])
          # col5 = dropdefaults!(Fiber!((Dense(Element(0)))), arr[:, 5])
          # col6 = dropdefaults!(Fiber!((Dense(Element(0)))), arr[:, 6])
          # vals = [col1, col2, col3, col4, col5, col6]
          
          
          println(io, "initialized fiber: ", fbr)
          @test Structure(fbr) == Structure(Fiber(Dense(Pointer(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6)))
          @test Structure(fbr) == Structure(Fiber(Dense(Pointer{typeof(fbr.lvl.lvl.val), typeof(fbr.lvl.lvl.lvl)}(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6)))

          fbr = Fiber!(Dense(Pointer(Dense(Element(0), 3)), 6))
          println(io, "sized fiber: ", fbr)
          @test Structure(fbr) == Structure(Fiber!(Dense(Pointer(Dense(Element(0), 3)), 6)))


          fbr = Fiber!(Dense(Pointer(Dense(Element(0)))))
          println(io, "empty fiber: ", fbr)
          @test Structure(fbr) == Structure(Fiber!(Dense(Pointer(Dense(Element(0))))))

          @test check_output("format_constructors_d_p_d_e.txt", String(take!(io)))
      end

    @testset "Fiber!(Dense(Pointer(RootSparseList(Element(0)))))" begin
          io = IOBuffer()
          arr = [0.0 2.0 2.0 0.0 3.0 3.0;
              1.0 0.0 7.0 1.0 0.0 0.0;
              0.0 0.0 0.0 0.0 0.0 9.0]
          
          println(io, "Fiber!(Dense(Pointer(RootSparseList(Element(0))))):")
          
          fbr = dropdefaults!(Fiber!(Dense(Pointer(RootSparseList(Element(0))))), arr)

          # sublvl = Fiber!(Dense(Element(0)), [])
          # col1 = dropdefaults!(Fiber!((Dense(Element(0)))), arr[:, 1])
          # col2 = dropdefaults!(Fiber!((Dense(Element(0)))), arr[:, 2])
          # col3 = dropdefaults!(Fiber!((Dense(Element(0)))), arr[:, 3])
          # col4 = dropdefaults!(Fiber!((Dense(Element(0)))), arr[:, 4])
          # col5 = dropdefaults!(Fiber!((Dense(Element(0)))), arr[:, 5])
          # col6 = dropdefaults!(Fiber!((Dense(Element(0)))), arr[:, 6])
          # vals = [col1, col2, col3, col4, col5, col6]
          
          
          println(io, "initialized fiber: ", fbr)
          @test Structure(fbr) == Structure(Fiber(Dense(Pointer(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6)))
          @test Structure(fbr) == Structure(Fiber(Dense(Pointer{typeof(fbr.lvl.lvl.val), typeof(fbr.lvl.lvl.lvl)}(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6)))

          fbr = Fiber!(Dense(Pointer(RootSparseList(Element(0), 3)), 6))
          println(io, "sized fiber: ", fbr)
          @test Structure(fbr) == Structure(Fiber!(Dense(Pointer(RootSparseList(Element(0), 3)), 6)))


          fbr = Fiber!(Dense(Pointer(RootSparseList(Element(0)))))
          println(io, "empty fiber: ", fbr)
          @test Structure(fbr) == Structure(Fiber!(Dense(Pointer(RootSparseList(Element(0))))))

          @test check_output("format_constructors_d_p_rsl_e.txt", String(take!(io)))
    end

        @testset "Fiber!(RootSparseList(Pointer(Dense(Element(0)))))" begin
          io = IOBuffer()
          arr = [0.0 2.0 2.0 0.0 3.0 3.0;
              1.0 0.0 7.0 1.0 0.0 0.0;
              0.0 0.0 0.0 0.0 0.0 9.0]
          
          println(io, "Fiber!(RootSparseList(Pointer(Dense(Element(0))))):")
          
          fbr = dropdefaults!(Fiber(RootSparseList(Pointer(Dense(Element(0))))), arr)
          
          println(io, "initialized fiber: ", fbr)
          @test Structure(fbr) == Structure(Fiber(RootSparseList(Pointer(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6, fbr.lvl.idx, fbr.lvl.endpoint)))
          @test Structure(fbr) == Structure(Fiber(RootSparseList(Pointer{typeof(fbr.lvl.lvl.val), typeof(fbr.lvl.lvl.lvl)}(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6, fbr.lvl.idx, fbr.lvl.endpoint)))

          fbr = Fiber!(RootSparseList(Pointer(Dense(Element(0), 3)), 6))
          println(io, "sized fiber: ", fbr)
          @test Structure(fbr) == Structure(Fiber!(RootSparseList(Pointer(Dense(Element(0), 3)), 6)))


          fbr = Fiber!(RootSparseList(Pointer(Dense(Element(0)))))
          println(io, "empty fiber: ", fbr)
          @test Structure(fbr) == Structure(Fiber!(RootSparseList(Pointer(Dense(Element(0))))))

          @test check_output("format_constructors_rsl_p_d_e.txt", String(take!(io)))
        end

    @testset "Fiber!(RootSparseList(Pointer(RootSparseList(Element(0)))))" begin
          io = IOBuffer()
          arr = [0.0 2.0 2.0 0.0 3.0 3.0;
              1.0 0.0 7.0 1.0 0.0 0.0;
              0.0 0.0 0.0 0.0 0.0 9.0]
          
          println(io, "Fiber!(RootSparseList(Pointer(RootSparseList(Element(0))))):")
          
          fbr = dropdefaults!(Fiber(RootSparseList(Pointer(RootSparseList(Element(0))))), arr)
          
          println(io, "initialized fiber: ", fbr)
          @test Structure(fbr) == Structure(Fiber(RootSparseList(Pointer(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6, fbr.lvl.idx, fbr.lvl.endpoint)))
          @test Structure(fbr) == Structure(Fiber(RootSparseList(Pointer{typeof(fbr.lvl.lvl.val), typeof(fbr.lvl.lvl.lvl)}(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6, fbr.lvl.idx, fbr.lvl.endpoint)))

          fbr = Fiber!(RootSparseList(Pointer(RootSparseList(Element(0), 3)), 6))
          println(io, "sized fiber: ", fbr)
          @test Structure(fbr) == Structure(Fiber!(RootSparseList(Pointer(RootSparseList(Element(0), 3)), 6)))


          fbr = Fiber!(RootSparseList(Pointer(RootSparseList(Element(0)))))
          println(io, "empty fiber: ", fbr)
          @test Structure(fbr) == Structure(Fiber!(RootSparseList(Pointer(RootSparseList(Element(0))))))

        @test check_output("format_constructors_rsl_p_rsl_e.txt", String(take!(io)))
    end

end
