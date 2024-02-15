@testset "constructors" begin
    @info "Testing Tensor Constructors"

    using Base.Meta

    @testset "Tensor(SparseList(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Tensor(SparseList(Element(0))) constructors:")

        fbr = dropdefaults!(Tensor(SparseList(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseList(lvl.lvl, lvl.shape, lvl.ptr, lvl.idx)))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int}(lvl.lvl, lvl.shape, lvl.ptr, lvl.idx)))

        fbr = dropdefaults!(Tensor(SparseList{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseList{Int16}(lvl.lvl, lvl.shape, lvl.ptr, lvl.idx)))

        fbr = Tensor(SparseList(Element(0.0), 7))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseList(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseList(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int}(Element(0.0), 7)))

        fbr = Tensor(SparseList{Int16}(Element(0.0), 7))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseList(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int16}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseList(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int16}(Element(0.0), 7)))

        fbr = Tensor(SparseList(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseList(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseList(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseList(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseList(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int}(Element(0.0), 0)))

        fbr = Tensor(SparseList{Int16}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseList{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseList(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int16}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseList(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int16}(Element(0.0), 0)))

        @test check_output("format_constructors_sl_e.txt", String(take!(io)))
    end

    @testset "Tensor(SparseVBL(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Tensor(SparseVBL(Element(0))) constructors:")

        fbr = dropdefaults!(Tensor(SparseVBL(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseVBL(lvl.lvl, lvl.shape, lvl.ptr, lvl.idx, lvl.ofs)))
        @test Structure(fbr) == Structure(Tensor(SparseVBL{Int}(lvl.lvl, lvl.shape, lvl.ptr, lvl.idx, lvl.ofs)))

        fbr = dropdefaults!(Tensor(SparseVBL{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseVBL{Int16}(lvl.lvl, lvl.shape, lvl.ptr, lvl.idx, lvl.ofs)))

        fbr = Tensor(SparseVBL(Element(0.0), 7))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseVBL(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseVBL{Int}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseVBL(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseVBL{Int}(Element(0.0), 7)))

        fbr = Tensor(SparseVBL{Int16}(Element(0.0), 7))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseVBL(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Tensor(SparseVBL{Int16}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseVBL(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Tensor(SparseVBL{Int16}(Element(0.0), 7)))

        fbr = Tensor(SparseVBL(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseVBL(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseVBL{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseVBL(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseVBL{Int}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseVBL(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseVBL{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseVBL(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseVBL{Int}(Element(0.0), 0)))

        fbr = Tensor(SparseVBL{Int16}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseVBL{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseVBL(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Tensor(SparseVBL{Int16}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseVBL{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseVBL(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Tensor(SparseVBL{Int16}(Element(0.0), 0)))

        @test check_output("format_constructors_sv_e.txt", String(take!(io)))
    end

    @testset "Tensor(SparseByteMap(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Tensor(SparseByteMap(Element(0))) constructors:")

        fbr = dropdefaults!(Tensor(SparseByteMap(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseByteMap(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap{Int}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))

        fbr = dropdefaults!(Tensor(SparseByteMap{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseByteMap{Int16}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))

        fbr = Tensor(SparseByteMap(Element(0.0), 7))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseByteMap(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap{Int}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap{Int}(Element(0.0), 7)))

        fbr = Tensor(SparseByteMap{Int16}(Element(0.0), 7))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseByteMap(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap{Int16}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap{Int16}(Element(0.0), 7)))

        fbr = Tensor(SparseByteMap(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseByteMap(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap{Int}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap{Int}(Element(0.0), 0)))

        fbr = Tensor(SparseByteMap{Int16}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseByteMap{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap{Int16}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Tensor(SparseByteMap{Int16}(Element(0.0), 0)))

        @test check_output("format_constructors_sm_e.txt", String(take!(io)))
    end

    @testset "Tensor(SparseCOO{1}(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Tensor(SparseCOO{1}(Element(0))) constructors:")

        fbr = dropdefaults!(Tensor(SparseCOO{1}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl)))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1, Tuple{Int}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl)))

        fbr = dropdefaults!(Tensor(SparseCOO{1, Tuple{Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1, Tuple{Int16}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl)))

        fbr = Tensor(SparseCOO{1}(Element(0.0), (7,)))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1, Tuple{Int}}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1, Tuple{Int}}(Element(0.0), (7,))))

        fbr = Tensor(SparseCOO{1, Tuple{Int16}}(Element(0.0), 7))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1}(Element(0.0), (Int16(7),))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1, Tuple{Int16}}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1}(Element(0.0), (Int16(7),))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1, Tuple{Int16}}(Element(0.0), 7)))

        fbr = Tensor(SparseCOO{1}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1, Tuple{Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1, Tuple{Int}}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1, Tuple{Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1, Tuple{Int}}(Element(0.0), (0,))))

        fbr = Tensor(SparseCOO{1, Tuple{Int16}}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1, Tuple{Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1}(Element(0.0), (Int16(0),))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1, Tuple{Int16}}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1, Tuple{Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1}(Element(0.0), (Int16(0),))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{1, Tuple{Int16}}(Element(0.0), (0,))))

        @test check_output("format_constructors_sc1_e.txt", String(take!(io)))
    end

    @testset "Tensor(SparseCOO{2}(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0 2.0 2.0 0.0 3.0 3.0;
               1.0 0.0 7.0 1.0 0.0 0.0;
               0.0 0.0 0.0 0.0 0.0 9.0]

        println(io, "Tensor(SparseCOO{2}(Element(0))) constructors:")

        fbr = dropdefaults!(Tensor(SparseCOO{2}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl)))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2, Tuple{Int, Int}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl)))

        fbr = dropdefaults!(Tensor(SparseCOO{2, Tuple{Int16, Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2, Tuple{Int16, Int16}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl)))

        fbr = Tensor(SparseCOO{2}(Element(0.0), (3, 7)))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2, Tuple{Int, Int}}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2, Tuple{Int, Int}}(Element(0.0), (3, 7,))))

        fbr = Tensor(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7)))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2}(Element(0.0), (Int16(3), Int16(7),))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2}(Element(0.0), (Int16(3), Int16(7),),)))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7,))))

        fbr = Tensor(SparseCOO{2}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2, Tuple{Int, Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2}(Element(0.0), (0,0,))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2, Tuple{Int, Int}}(Element(0.0), (0,0,))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2, Tuple{Int, Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2}(Element(0.0), (0,0,))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2, Tuple{Int, Int}}(Element(0.0), (0,0,))))

        fbr = Tensor(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2}(Element(0.0), (Int16(0), Int16(0),))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0), (0,0))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2}(Element(0.0), (Int16(0), Int16(0),))))
        @test Structure(fbr) == Structure(Tensor(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0), (0,0,))))

        @test check_output("format_constructors_sc2_e.txt", String(take!(io)))
    end

    @testset "Tensor(SparseHash{1}(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Tensor(SparseHash{1}(Element(0))) constructors:")

        fbr = dropdefaults!(Tensor(SparseHash{1}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseHash{1}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1, Tuple{Int}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))

        fbr = dropdefaults!(Tensor(SparseHash{1, Tuple{Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseHash{1, Tuple{Int16}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))

        fbr = Tensor(SparseHash{1}(Element(0.0), (7,)))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseHash{1}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1, Tuple{Int}}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1, Tuple{Int}}(Element(0.0), (7,))))

        fbr = Tensor(SparseHash{1, Tuple{Int16}}(Element(0.0), (7,)))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseHash{1}(Element(0.0), (Int16(7),))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1, Tuple{Int16}}(Element(0.0), (7,))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1}(Element(0.0), (Int16(7),))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1, Tuple{Int16}}(Element(0.0), (7,))))

        fbr = Tensor(SparseHash{1}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseHash{1}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1, Tuple{Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1, Tuple{Int}}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1, Tuple{Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1, Tuple{Int}}(Element(0.0), (0,))))

        fbr = Tensor(SparseHash{1, Tuple{Int16}}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseHash{1, Tuple{Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1}(Element(0.0), (Int16(0),))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1, Tuple{Int16}}(Element(0.0), (0,))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1, Tuple{Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1}(Element(0.0), (Int16(0),))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{1, Tuple{Int16}}(Element(0.0), (0,))))

        @test check_output("format_constructors_sh1_e.txt", String(take!(io)))
    end

    @testset "Tensor(SparseHash{2}(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0 2.0 2.0 0.0 3.0 3.0;
               1.0 0.0 7.0 1.0 0.0 0.0;
               0.0 0.0 0.0 0.0 0.0 9.0]

        println(io, "Tensor(SparseHash{2}(Element(0))) constructors:")

        fbr = dropdefaults!(Tensor(SparseHash{2}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseHash{2}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2, Tuple{Int, Int}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))

        fbr = dropdefaults!(Tensor(SparseHash{2, Tuple{Int16, Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseHash{2, Tuple{Int16, Int16}}(lvl.lvl, lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)))

        fbr = Tensor(SparseHash{2}(Element(0.0), (3, 7)))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseHash{2}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2, Tuple{Int, Int}}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2, Tuple{Int, Int}}(Element(0.0), (3, 7,))))

        fbr = Tensor(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7)))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseHash{2}(Element(0.0), (Int16(3), Int16(7),))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7,))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2}(Element(0.0), (Int16(3), Int16(7),))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7,))))

        fbr = Tensor(SparseHash{2}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseHash{2}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2, Tuple{Int, Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2}(Element(0.0), (0,0,))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2, Tuple{Int, Int}}(Element(0.0), (0,0,))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2, Tuple{Int, Int}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2}(Element(0.0), (0,0,))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2, Tuple{Int, Int}}(Element(0.0), (0,0,))))

        fbr = Tensor(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2}(Element(0.0), (Int16(0), Int16(0),))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0), (0,0))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2}(Element(0.0), (Int16(0), Int16(0),))))
        @test Structure(fbr) == Structure(Tensor(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0), (0,0,))))

        @test check_output("format_constructors_sh2_e.txt", String(take!(io)))
    end

    @testset "Tensor(SparseTriangle{2}(Element(0)))" begin
        io = IOBuffer()
        arr = [1.0  2.0  3.0  4.0  5.0; 
               6.0  7.0  8.0  9.0  10.0; 
               11.0 12.0 13.0 14.0 15.0; 
               16.0 17.0 18.0 19.0 20.0; 
               21.0 22.0 23.0 24.0 25.0]

        println(io, "Tensor(SparseTriangle{2}(Element(0))) constructors:")

        fbr = dropdefaults!(Tensor(SparseTriangle{2}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2}(lvl.lvl, lvl.shape)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2, Int}(lvl.lvl, lvl.shape)))

        fbr = dropdefaults!(Tensor(SparseTriangle{2, Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2, Int16}(lvl.lvl, lvl.shape)))

        fbr = Tensor(SparseTriangle{2}(Element(0.0), 7))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2, Int}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2, Int}(Element(0.0), 7)))

        fbr = Tensor(SparseTriangle{2, Int16}(Element(0.0), 7))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2}(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2, Int16}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2}(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2, Int16}(Element(0.0), 7)))

        fbr = Tensor(SparseTriangle{2}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2, Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2, Int}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2, Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2, Int}(Element(0.0), 0)))

        fbr = Tensor(SparseTriangle{2, Int16}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2, Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2}(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2, Int16}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2, Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2}(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{2, Int16}(Element(0.0), 0)))

        @test check_output("format_constructors_st2_e.txt", String(take!(io)))
    end

    @testset "Tensor(SparseTriangle{3}(Element(0)))" begin
        io = IOBuffer()
        arr = collect(reshape(1.0 .* (1:27), 3, 3, 3))

        println(io, "Tensor(SparseTriangle{3}(Element(0))) constructors:")

        fbr = dropdefaults!(Tensor(SparseTriangle{3}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3}(lvl.lvl, lvl.shape)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3, Int}(lvl.lvl, lvl.shape)))

        fbr = dropdefaults!(Tensor(SparseTriangle{3, Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3, Int16}(lvl.lvl, lvl.shape)))

        fbr = Tensor(SparseTriangle{3}(Element(0.0), 7))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3, Int}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3, Int}(Element(0.0), 7)))

        fbr = Tensor(SparseTriangle{3, Int16}(Element(0.0), 7))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3}(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3, Int16}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3}(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3, Int16}(Element(0.0), 7)))

        fbr = Tensor(SparseTriangle{3}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3, Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3, Int}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3, Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3, Int}(Element(0.0), 0)))

        fbr = Tensor(SparseTriangle{3, Int16}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3, Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3}(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3, Int16}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3, Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3}(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Tensor(SparseTriangle{3, Int16}(Element(0.0), 0)))

        @test check_output("format_constructors_st3_e.txt", String(take!(io))) 
    end
     
    @testset "Tensor(SparseRLE(Element(0)))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Tensor(SparseRLE(Element(0))) constructors:")

        fbr = dropdefaults!(Tensor(SparseRLE(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseRLE(lvl.lvl, lvl.shape, lvl.ptr, lvl.left, lvl.right)))
        @test Structure(fbr) == Structure(Tensor(SparseRLE{Int}(lvl.lvl, lvl.shape, lvl.ptr, lvl.left, lvl.right)))

        fbr = dropdefaults!(Tensor(SparseRLE{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseRLE{Int16}(lvl.lvl, lvl.shape, lvl.ptr, lvl.left, lvl.right)))

        fbr = Tensor(SparseRLE(Element(0.0), 7))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseRLE(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseRLE{Int}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseRLE(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseRLE{Int}(Element(0.0), 7)))

        fbr = Tensor(SparseRLE{Int16}(Element(0.0), 7))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseRLE(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Tensor(SparseRLE{Int16}(Element(0.0), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseRLE(Element(0.0), Int16(7))))
        @test Structure(fbr) == Structure(Tensor(SparseRLE{Int16}(Element(0.0), 7)))

        fbr = Tensor(SparseRLE(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseRLE(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseRLE{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseRLE(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseRLE{Int}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseRLE(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseRLE{Int}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseRLE(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseRLE{Int}(Element(0.0), 0)))

        fbr = Tensor(SparseRLE{Int16}(Element(0.0)))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseRLE{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseRLE(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Tensor(SparseRLE{Int16}(Element(0.0), 0)))
        @test Structure(fbr) == Structure(Tensor(SparseRLE{Int16}(Element(0.0))))
        @test Structure(fbr) == Structure(Tensor(SparseRLE(Element(0.0), Int16(0))))
        @test Structure(fbr) == Structure(Tensor(SparseRLE{Int16}(Element(0.0), 0)))

        @test check_output("format_constructors_srl_e.txt", String(take!(io)))
    end

      @testset "Tensor(Dense(Atomic(Separation(Dense(Element(0))))))" begin
          io = IOBuffer()
          arr = [0.0 2.0 2.0 0.0 3.0 3.0;
              1.0 0.0 7.0 1.0 0.0 0.0;
              0.0 0.0 0.0 0.0 0.0 9.0]
          
          println(io, "Tensor(Dense(Atomic(Separation(Dense(Element(0)))))):")
          
          fbr = dropdefaults!(Tensor(Dense(Atomic(Separation(Dense(Element(0)))))), arr)

          # sublvl = Tensor(Dense(Element(0)), [])
          # col1 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 1])
          # col2 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 2])
          # col3 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 3])
          # col4 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 4])
          # col5 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 5])
          # col6 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 6])
          # vals = [col1, col2, col3, col4, col5, col6]
          
          
          println(io, "initialized tensor: ", fbr)
          @test Structure(fbr) == Structure(Tensor(Dense(Atomic(Separation(fbr.lvl.lvl.lvl.val, fbr.lvl.lvl.lvl.lvl), fbr.lvl.lvl.locks), 6)))
          @test Structure(fbr) == Structure(Tensor(Dense(Atomic{typeof(fbr.lvl.lvl.locks), Separation{typeof(fbr.lvl.lvl.lvl.val), typeof(fbr.lvl.lvl.lvl.lvl)}}(Separation{typeof(fbr.lvl.lvl.lvl.val), typeof(fbr.lvl.lvl.lvl.lvl)}(fbr.lvl.lvl.lvl.val, fbr.lvl.lvl.lvl.lvl), fbr.lvl.lvl.locks), 6)))

          fbr = Tensor(Dense(Atomic(Separation(Dense(Element(0), 3))), 6))
          println(io, "sized tensor: ", fbr)
          @test Structure(fbr) == Structure(Tensor(Dense(Atomic(Separation(Dense(Element(0), 3))), 6)))


          fbr = Tensor(Dense(Atomic(Separation(Dense(Element(0))))))
          println(io, "empty tensor: ", fbr)
          @test Structure(fbr) == Structure(Tensor(Dense(Atomic(Separation(Dense(Element(0)))))))

          @test check_output("format_constructors_d_a_p_d_e.txt", String(take!(io)))
      end

      @testset "Tensor(Dense(Separation(Dense(Element(0)))))" begin
        io = IOBuffer()
        arr = [0.0 2.0 2.0 0.0 3.0 3.0;
            1.0 0.0 7.0 1.0 0.0 0.0;
            0.0 0.0 0.0 0.0 0.0 9.0]
        
        println(io, "Tensor(Dense(Separation(Dense(Element(0))))):")
        
        fbr = dropdefaults!(Tensor(Dense(Separation(Dense(Element(0))))), arr)

        # sublvl = Tensor(Dense(Element(0)), [])
        # col1 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 1])
        # col2 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 2])
        # col3 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 3])
        # col4 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 4])
        # col5 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 5])
        # col6 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 6])
        # vals = [col1, col2, col3, col4, col5, col6]
        
        
        println(io, "initialized tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(Dense(Separation(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6)))
        @test Structure(fbr) == Structure(Tensor(Dense(Separation{typeof(fbr.lvl.lvl.val), typeof(fbr.lvl.lvl.lvl)}(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6)))

        fbr = Tensor(Dense(Separation(Dense(Element(0), 3)), 6))
        println(io, "sized tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(Dense(Separation(Dense(Element(0), 3)), 6)))


        fbr = Tensor(Dense(Separation(Dense(Element(0)))))
        println(io, "empty tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(Dense(Separation(Dense(Element(0))))))

        @test check_output("format_constructors_d_p_d_e.txt", String(take!(io)))
    end
    

    @testset "Tensor(Dense(Atomic(Dense(Element(0)))))" begin
        io = IOBuffer()
        arr = [0.0 2.0 2.0 0.0 3.0 3.0;
            1.0 0.0 7.0 1.0 0.0 0.0;
            0.0 0.0 0.0 0.0 0.0 9.0]
        
        fbr = dropdefaults!(Tensor(Dense(Atomic(Dense(Element(0))))), arr)

        # sublvl = Tensor(Dense(Element(0)), [])
        # col1 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 1])
        # col2 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 2])
        # col3 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 3])
        # col4 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 4])
        # col5 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 5])
        # col6 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 6])
        # vals = [col1, col2, col3, col4, col5, col6]
        
        
        println(io, "initialized tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(Dense(Atomic(fbr.lvl.lvl.lvl, fbr.lvl.lvl.locks), 6)))
        @test Structure(fbr) == Structure(Tensor(Dense(Atomic{Vector{Base.Threads.SpinLock}, typeof(fbr.lvl.lvl.lvl)}(fbr.lvl.lvl.lvl, fbr.lvl.lvl.locks), 6)))

        fbr = Tensor(Dense(Atomic(Dense(Element(0), 3)), 6))
        println(io, "sized tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(Dense(Atomic(Dense(Element(0), 3)), 6)))


        fbr = Tensor(Dense(Atomic(Dense(Element(0)))))
        println(io, "empty tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(Dense(Atomic(Dense(Element(0))))))

        @test check_output("format_constructors_d_a_d_e.txt", String(take!(io)))
    end

    @testset "Tensor(Dense(Separation(SparseList(Element(0)))))" begin
        io = IOBuffer()
        arr = [0.0 2.0 2.0 0.0 3.0 3.0;
            1.0 0.0 7.0 1.0 0.0 0.0;
            0.0 0.0 0.0 0.0 0.0 9.0]
        
        println(io, "Tensor(Dense(Separation(SparseList(Element(0))))):")
        
        fbr = dropdefaults!(Tensor(Dense(Separation(SparseList(Element(0))))), arr)

        # sublvl = Tensor(Dense(Element(0)), [])
        # col1 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 1])
        # col2 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 2])
        # col3 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 3])
        # col4 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 4])
        # col5 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 5])
        # col6 = dropdefaults!(Tensor((Dense(Element(0)))), arr[:, 6])
        # vals = [col1, col2, col3, col4, col5, col6]
        
        println(io, "initialized tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(Dense(Separation(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6)))
        @test Structure(fbr) == Structure(Tensor(Dense(Separation{typeof(fbr.lvl.lvl.val), typeof(fbr.lvl.lvl.lvl)}(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6)))

        fbr = Tensor(Dense(Separation(SparseList(Element(0), 3)), 6))
        println(io, "sized tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(Dense(Separation(SparseList(Element(0), 3)), 6)))

        fbr = Tensor(Dense(Separation(SparseList(Element(0)))))
        println(io, "empty tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(Dense(Separation(SparseList(Element(0))))))

        @test check_output("format_constructors_d_p_sl_e.txt", String(take!(io)))
    end

    @testset "Tensor(SparseList(Separation(Dense(Element(0)))))" begin
        io = IOBuffer()
        arr = [0.0 2.0 2.0 0.0 3.0 3.0;
            1.0 0.0 7.0 1.0 0.0 0.0;
            0.0 0.0 0.0 0.0 0.0 9.0]
        
        println(io, "Tensor(SparseList(Separation(Dense(Element(0))))):")
        
        fbr = dropdefaults!(Tensor(SparseList(Separation(Dense(Element(0))))), arr)
        
        println(io, "initialized tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(SparseList(Separation(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6, fbr.lvl.ptr, fbr.lvl.idx)))
        @test Structure(fbr) == Structure(Tensor(SparseList(Separation{typeof(fbr.lvl.lvl.val), typeof(fbr.lvl.lvl.lvl)}(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6, fbr.lvl.ptr, fbr.lvl.idx)))

        fbr = Tensor(SparseList(Separation(Dense(Element(0), 3)), 6))
        println(io, "sized tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(SparseList(Separation(Dense(Element(0), 3)), 6)))


        fbr = Tensor(SparseList(Separation(Dense(Element(0)))))
        println(io, "empty tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(SparseList(Separation(Dense(Element(0))))))

        @test check_output("format_constructors_sl_p_d_e.txt", String(take!(io)))
    end

    @testset "Tensor(SparseList(Atomic(Dense(Element(0)))))" begin
        io = IOBuffer()
        arr = [0.0 2.0 2.0 0.0 3.0 3.0;
            1.0 0.0 7.0 1.0 0.0 0.0;
            0.0 0.0 0.0 0.0 0.0 9.0]
        
        println(io, "Tensor(SparseList(Atomic(Dense(Element(0))))):")
        
        fbr = dropdefaults!(Tensor(SparseList(Atomic(Dense(Element(0))))), arr)
        
        println(io, "initialized tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(SparseList(Atomic(fbr.lvl.lvl.lvl, fbr.lvl.lvl.locks), 6, fbr.lvl.ptr, fbr.lvl.idx)))
        @test Structure(fbr) == Structure(Tensor(SparseList(Atomic{typeof(fbr.lvl.lvl.locks), typeof(fbr.lvl.lvl.lvl)}(fbr.lvl.lvl.lvl, fbr.lvl.lvl.locks), 6, fbr.lvl.ptr, fbr.lvl.idx)))

        fbr = Tensor(SparseList(Atomic(Dense(Element(0), 3)), 6))
        println(io, "sized tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(SparseList(Atomic(Dense(Element(0), 3)), 6)))


        fbr = Tensor(SparseList(Atomic(Dense(Element(0)))))
        println(io, "empty tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(SparseList(Atomic(Dense(Element(0))))))

        @test check_output("format_constructors_sl_a_d_e.txt", String(take!(io)))
    end

    @testset "Tensor(SparseList(Separation(SparseList(Element(0)))))" begin
          io = IOBuffer()
          arr = [0.0 2.0 2.0 0.0 3.0 3.0;
              1.0 0.0 7.0 1.0 0.0 0.0;
              0.0 0.0 0.0 0.0 0.0 9.0]
          
          println(io, "Tensor(SparseList(Separation(SparseList(Element(0))))):")
          
          fbr = dropdefaults!(Tensor(SparseList(Separation(SparseList(Element(0))))), arr)
          
          println(io, "initialized tensor: ", fbr)
          @test Structure(fbr) == Structure(Tensor(SparseList(Separation(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6, fbr.lvl.ptr, fbr.lvl.idx)))
          @test Structure(fbr) == Structure(Tensor(SparseList(Separation{typeof(fbr.lvl.lvl.val), typeof(fbr.lvl.lvl.lvl)}(fbr.lvl.lvl.val, fbr.lvl.lvl.lvl), 6, fbr.lvl.ptr, fbr.lvl.idx)))

          fbr = Tensor(SparseList(Separation(SparseList(Element(0), 3)), 6))
          println(io, "sized tensor: ", fbr)
          @test Structure(fbr) == Structure(Tensor(SparseList(Separation(SparseList(Element(0), 3)), 6)))

          fbr = Tensor(SparseList(Separation(SparseList(Element(0)))))
          println(io, "empty tensor: ", fbr)
          @test Structure(fbr) == Structure(Tensor(SparseList(Separation(SparseList(Element(0))))))

        @test check_output("format_constructors_sl_p_sl_e.txt", String(take!(io)))
    end

    @testset "Tensor(Atomic(SparseList(Element(0))))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Tensor(Atomic(SparseList(Element(0)))) constructors:")

        fbr = dropdefaults!(Tensor(Atomic(SparseList(Element(zero(eltype(arr)))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(Atomic(SparseList(lvl.lvl.lvl, lvl.lvl.shape, lvl.lvl.ptr, lvl.lvl.idx), lvl.locks)))
        @test Structure(fbr) == Structure(Tensor(Atomic(SparseList{Int}(lvl.lvl.lvl, lvl.lvl.shape, lvl.lvl.ptr, lvl.lvl.idx), lvl.locks)))

        fbr = dropdefaults!(Tensor(Atomic(SparseList{Int16}(Element(zero(eltype(arr)))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(Atomic(SparseList{Int16}(lvl.lvl.lvl, lvl.lvl.shape, lvl.lvl.ptr, lvl.lvl.idx), lvl.locks)))

        fbr = Tensor(Atomic(SparseList(Element(0.0), 7)))
        println(io, "sized tensor: ", fbr)
        @test Structure(fbr) == Structure(Tensor(Atomic(SparseList(Element(0.0), 7))))
        @test Structure(fbr) == Structure(Tensor(Atomic(SparseList{Int}(Element(0.0), 7))))
        @test Structure(fbr) == Structure(Tensor(Atomic(SparseList(Element(0.0), 7))))
        @test Structure(fbr) == Structure(Tensor(Atomic(SparseList{Int}(Element(0.0), 7))))

        @test check_output("format_constructors_a_sl_e.txt", String(take!(io)))
    end

    @testset "Tensor(SparseList(Atomic(Element(0))))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Tensor(SparseList(Atomic(Element(0)))) constructors:")

        fbr = dropdefaults!(Tensor(SparseList(Atomic(Element(zero(eltype(arr)))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseList(lvl.lvl, lvl.shape, lvl.ptr, lvl.idx)))

        fbr = dropdefaults!(Tensor(SparseList{Int16}(Atomic(Element(zero(eltype(arr)))))), arr)
        println(io, "initialized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseList{Int16}(lvl.lvl, lvl.shape, lvl.ptr, lvl.idx)))

        fbr = Tensor(SparseList(Atomic(Element(0.0)), 7))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseList(Atomic(Element(0.0)), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int}(Atomic(Element(0.0)), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseList(Atomic(Element(0.0)), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int}(Atomic(Element(0.0)), 7)))

        fbr = Tensor(SparseList{Int16}(Atomic(Element(0.0)), 7))
        println(io, "sized tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseList(Atomic(Element(0.0)), Int16(7))))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int16}(Atomic(Element(0.0)), 7)))
        @test Structure(fbr) == Structure(Tensor(SparseList(Atomic(Element(0.0)), Int16(7))))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int16}(Atomic(Element(0.0)), 7)))

        fbr = Tensor(SparseList(Atomic(Element(0.0))))
        println(io, "empty tensor: ", fbr)
        lvl = fbr.lvl
        @test Structure(fbr) == Structure(Tensor(SparseList(Atomic(Element(0.0)))))
        @test Structure(fbr) == Structure(Tensor(SparseList{Int}(Atomic(Element(0.0)))))

        @test check_output("format_constructors_sl_a_e.txt", String(take!(io)))
    end

    @testset "OffByOneVector" begin
        # test off-by-one
        v = Vector([1, 0, 2, 3])
        obov = OffByOneVector(v)
        @test obov == v .+ 1
        @test obov.data == v

        # test off-by-one in a tensor
        coo = Tensor(
            SparseCOO{2}(
                Element(0, Vector([1, 2, 3])),  # data
                (3, 3),  # shape
                Vector([1, 4]),  # ptr
                (
                    OffByOneVector(Vector([0, 0, 2])),
                    OffByOneVector(Vector([0, 2, 2])),
                ),  # off-by-one indices
            )
        )
        @test Array(Tensor(Dense(Dense(Element(0))), coo)) == [1 0 2; 0 0 0; 0 0 3]

        # test off-by-one write operation
        val = 10
        obov[2] = val
        @test obov == [2, val, 3, 4] && obov.data == [1, val - 1, 2, 3]
        obov[1:3] .= val
        @test obov == [val, val, val, 4] && obov.data == [val-1, val-1, val-1, 3]

    end
end
