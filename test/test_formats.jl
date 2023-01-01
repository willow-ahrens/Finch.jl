@testset "formats" begin
    arr = fill(false)
    ref = Fiber(Pattern())
    res = dropdefaults!(Fiber(Pattern()), arr)
    @test isstructequal(res, ref)
    arr = fill(true)
    ref = Fiber(Pattern())
    res = dropdefaults!(Fiber(Pattern()), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(Dense{Int}(5, Pattern()))
    res = dropdefaults!(Fiber(Dense(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(Dense{Int}(5, Pattern()))
    res = dropdefaults!(Fiber(Dense(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(Dense{Int}(4, Pattern()))
    res = dropdefaults!(Fiber(Dense(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, Dense{Int}(5, Pattern())))
    res = dropdefaults!(Fiber(Dense(Dense(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, Dense{Int}(5, Pattern())))
    res = dropdefaults!(Fiber(Dense(Dense(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, Dense{Int}(4, Pattern())))
    res = dropdefaults!(Fiber(Dense(Dense(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], Dense{Int}(5, Pattern())))
    res = dropdefaults!(Fiber(SparseList(Dense(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], Dense{Int}(5, Pattern())))
    res = dropdefaults!(Fiber(SparseList(Dense(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 3, 4], Dense{Int}(4, Pattern())))
    res = dropdefaults!(Fiber(SparseList(Dense(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], Pattern()))
    res = dropdefaults!(Fiber(SparseList(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], Pattern()))
    res = dropdefaults!(Fiber(SparseList(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 3], [2, 4], Pattern()))
    res = dropdefaults!(Fiber(SparseList(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseList{Int, Int}(5, [1, 1, 1, 1, 1, 1], [], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseList(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseList{Int, Int}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseList(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseList{Int, Int}(4, [1, 3, 3, 7, 9], [2, 4, 1, 2, 3, 4, 2, 4], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseList(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseList{Int, Int}(5, [1], [], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseList(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseList{Int, Int}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseList(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 3, 4], SparseList{Int, Int}(4, [1, 3, 7, 9], [2, 4, 1, 2, 3, 4, 2, 4], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseList(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseListDiff{Int, Int}(5, [1, 1], [], [0], Pattern()))
    res = dropdefaults!(Fiber(SparseListDiff(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseListDiff{Int, Int}(5, [1, 6], [0x01, 0x01, 0x01, 0x01, 0x01], [5], Pattern()))
    res = dropdefaults!(Fiber(SparseListDiff(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseListDiff{Int, Int}(4, [1, 3], [0x02, 0x02], [4], Pattern()))
    res = dropdefaults!(Fiber(SparseListDiff(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseListDiff{Int, Int}(5, [1, 1, 1, 1, 1, 1], [], [0, 0, 0, 0, 0], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseListDiff(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseListDiff{Int, Int}(5, [1, 6, 11, 16, 21, 26], [0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01], [5, 5, 5, 5, 5], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseListDiff(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseListDiff{Int, Int}(4, [1, 3, 3, 7, 9], [0x02, 0x02, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02], [4, 0, 4, 4], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseListDiff(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseListDiff{Int, Int}(5, [1], [], [], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseListDiff(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseListDiff{Int, Int}(5, [1, 6, 11, 16, 21, 26], [0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01], [5, 5, 5, 5, 5], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseListDiff(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 3, 4], SparseListDiff{Int, Int}(4, [1, 3, 7, 9], [0x02, 0x02, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02], [4, 4, 4], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseListDiff(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseVBL{Int, Int}(5, [1, 1], [], [1], Pattern()))
    res = dropdefaults!(Fiber(SparseVBL(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseVBL{Int, Int}(5, [1, 2], [5], [1, 6], Pattern()))
    res = dropdefaults!(Fiber(SparseVBL(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseVBL{Int, Int}(4, [1, 3], [2, 4], [1, 2, 3], Pattern()))
    res = dropdefaults!(Fiber(SparseVBL(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseVBL{Int, Int}(5, [1, 1, 1, 1, 1, 1], [], [1], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseVBL(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseVBL{Int, Int}(5, [1, 2, 3, 4, 5, 6], [5, 5, 5, 5, 5], [1, 6, 11, 16, 21, 26], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseVBL(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseVBL{Int, Int}(4, [1, 3, 3, 4, 6], [2, 4, 4, 2, 4], [1, 2, 3, 7, 8, 9], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseVBL(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseVBL{Int, Int}(5, [1], [], [1], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseVBL(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseVBL{Int, Int}(5, [1, 2, 3, 4, 5, 6], [5, 5, 5, 5, 5], [1, 6, 11, 16, 21, 26], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseVBL(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 3, 4], SparseVBL{Int, Int}(4, [1, 3, 4, 6], [2, 4, 4, 2, 4], [1, 2, 3, 7, 8, 9], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseVBL(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseBytemap{Int, Int}(5, [1, 1], [0, 0, 0, 0, 0], [], Base.RefValue{Int}(0), Pattern()))
    res = dropdefaults!(Fiber(SparseBytemap(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseBytemap{Int, Int}(5, [1, 6], [1, 1, 1, 1, 1], [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5)], Base.RefValue{Int}(5), Pattern()))
    res = dropdefaults!(Fiber(SparseBytemap(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseBytemap{Int, Int}(4, [1, 3], [0, 1, 0, 1], [(1, 2), (1, 4)], Base.RefValue{Int}(2), Pattern()))
    res = dropdefaults!(Fiber(SparseBytemap(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseBytemap{Int, Int}(5, [1, 1, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [], Base.RefValue{Int}(0), Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseBytemap(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseBytemap{Int, Int}(5, [1, 6, 11, 16, 21, 26], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5)], Base.RefValue{Int}(25), Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseBytemap(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseBytemap{Int, Int}(4, [1, 3, 3, 7, 9], [0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1], [(1, 2), (1, 4), (3, 1), (3, 2), (3, 3), (3, 4), (4, 2), (4, 4)], Base.RefValue{Int}(8), Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseBytemap(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseBytemap{Int, Int}(5, [1], [], [], Base.RefValue{Int}(0), Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseBytemap(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseBytemap{Int, Int}(5, [1, 6, 11, 16, 21, 26], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5)], Base.RefValue{Int}(25), Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseBytemap(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 3, 4], SparseBytemap{Int, Int}(4, [1, 3, 7, 9], [0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1], [(1, 2), (1, 4), (2, 1), (2, 2), (2, 3), (2, 4), (3, 2), (3, 4)], Base.RefValue{Int}(8), Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseBytemap(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}(), [1, 1], [], Pattern()))
    res = dropdefaults!(Fiber(SparseHash{1}(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5), [1, 6], [(1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5], Pattern()))
    res = dropdefaults!(Fiber(SparseHash{1}(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseHash{1, Tuple{Int}, Int}((4,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (2,)) => 1, (1, (4,)) => 2), [1, 3], [(1, (2,)) => 1, (1, (4,)) => 2], Pattern()))
    res = dropdefaults!(Fiber(SparseHash{1}(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}(), [1, 1, 1, 1, 1, 1], [], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseHash{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25), [1, 6, 11, 16, 21, 26], [(1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseHash{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseHash{1, Tuple{Int}, Int}((4,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (2,)) => 1, (1, (4,)) => 2, (3, (1,)) => 3, (3, (2,)) => 4, (3, (3,)) => 5, (3, (4,)) => 6, (4, (2,)) => 7, (4, (4,)) => 8), [1, 3, 3, 7, 9], [(1, (2,)) => 1, (1, (4,)) => 2, (3, (1,)) => 3, (3, (2,)) => 4, (3, (3,)) => 5, (3, (4,)) => 6, (4, (2,)) => 7, (4, (4,)) => 8], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseHash{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}(), [1], [], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseHash{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25), [1, 6, 11, 16, 21, 26], [(1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseHash{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 3, 4], SparseHash{1, Tuple{Int}, Int}((4,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (2,)) => 1, (1, (4,)) => 2, (2, (1,)) => 3, (2, (2,)) => 4, (2, (3,)) => 5, (2, (4,)) => 6, (3, (2,)) => 7, (3, (4,)) => 8), [1, 3, 7, 9], [(1, (2,)) => 1, (1, (4,)) => 2, (2, (1,)) => 3, (2, (2,)) => 4, (2, (3,)) => 5, (2, (4,)) => 6, (3, (2,)) => 7, (3, (4,)) => 8], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseHash{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseCoo{1, Tuple{Int}, Int}((5,), (Int[], ), [1, 1], Pattern()))
    res = dropdefaults!(Fiber(SparseCoo{1}(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int}, Int}((5,), (Int[1, 2, 3, 4, 5], ), [1, 6], Pattern()))
    res = dropdefaults!(Fiber(SparseCoo{1}(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int}, Int}((4,), (Int[2, 4], ), [1, 3], Pattern()))
    res = dropdefaults!(Fiber(SparseCoo{1}(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseCoo{1, Tuple{Int}, Int}((5,), (Int[], ), [1, 1, 1, 1, 1, 1], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseCoo{1, Tuple{Int}, Int}((5,), (Int[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseCoo{1, Tuple{Int}, Int}((4,), (Int[2, 4, 1, 2, 3, 4, 2, 4], ), [1, 3, 3, 7, 9], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseCoo{1, Tuple{Int}, Int}((5,), (Int[], ), [1], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseCoo{1, Tuple{Int}, Int}((5,), (Int[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 3, 4], SparseCoo{1, Tuple{Int}, Int}((4,), (Int[2, 4, 1, 2, 3, 4, 2, 4], ), [1, 3, 7, 9], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseCoo{2, Tuple{Int, Int}, Int}((5, 5), (Int[], Int[], ), [1, 1], Pattern()))
    res = dropdefaults!(Fiber(SparseCoo{2}(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseCoo{2, Tuple{Int, Int}, Int}((5, 5), (Int[1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5], Int[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 26], Pattern()))
    res = dropdefaults!(Fiber(SparseCoo{2}(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseCoo{2, Tuple{Int, Int}, Int}((4, 4), (Int[1, 1, 3, 3, 3, 3, 4, 4], Int[2, 4, 1, 2, 3, 4, 2, 4], ), [1, 9], Pattern()))
    res = dropdefaults!(Fiber(SparseCoo{2}(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseHash{2, Tuple{Int, Int}, Int}((5, 5), Dict{Tuple{Int, Tuple{Int, Int}}, Int}(), [1, 1], [], Pattern()))
    res = dropdefaults!(Fiber(SparseHash{2}(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseHash{2, Tuple{Int, Int}, Int}((5, 5), Dict{Tuple{Int, Tuple{Int, Int}}, Int}((1, (1, 1)) => 1, (1, (1, 2)) => 2, (1, (1, 3)) => 3, (1, (1, 4)) => 4, (1, (1, 5)) => 5, (1, (2, 1)) => 6, (1, (2, 2)) => 7, (1, (2, 3)) => 8, (1, (2, 4)) => 9, (1, (2, 5)) => 10, (1, (3, 1)) => 11, (1, (3, 2)) => 12, (1, (3, 3)) => 13, (1, (3, 4)) => 14, (1, (3, 5)) => 15, (1, (4, 1)) => 16, (1, (4, 2)) => 17, (1, (4, 3)) => 18, (1, (4, 4)) => 19, (1, (4, 5)) => 20, (1, (5, 1)) => 21, (1, (5, 2)) => 22, (1, (5, 3)) => 23, (1, (5, 4)) => 24, (1, (5, 5)) => 25), [1, 26], [(1, (1, 1)) => 1, (1, (1, 2)) => 2, (1, (1, 3)) => 3, (1, (1, 4)) => 4, (1, (1, 5)) => 5, (1, (2, 1)) => 6, (1, (2, 2)) => 7, (1, (2, 3)) => 8, (1, (2, 4)) => 9, (1, (2, 5)) => 10, (1, (3, 1)) => 11, (1, (3, 2)) => 12, (1, (3, 3)) => 13, (1, (3, 4)) => 14, (1, (3, 5)) => 15, (1, (4, 1)) => 16, (1, (4, 2)) => 17, (1, (4, 3)) => 18, (1, (4, 4)) => 19, (1, (4, 5)) => 20, (1, (5, 1)) => 21, (1, (5, 2)) => 22, (1, (5, 3)) => 23, (1, (5, 4)) => 24, (1, (5, 5)) => 25], Pattern()))
    res = dropdefaults!(Fiber(SparseHash{2}(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseHash{2, Tuple{Int, Int}, Int}((4, 4), Dict{Tuple{Int, Tuple{Int, Int}}, Int}((1, (1, 2)) => 1, (1, (1, 4)) => 2, (1, (3, 1)) => 3, (1, (3, 2)) => 4, (1, (3, 3)) => 5, (1, (3, 4)) => 6, (1, (4, 2)) => 7, (1, (4, 4)) => 8), [1, 9], [(1, (1, 2)) => 1, (1, (1, 4)) => 2, (1, (3, 1)) => 3, (1, (3, 2)) => 4, (1, (3, 3)) => 5, (1, (3, 4)) => 6, (1, (4, 2)) => 7, (1, (4, 4)) => 8], Pattern()))
    res = dropdefaults!(Fiber(SparseHash{2}(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = fill(false)
    ref = Fiber(Element{false, Bool}([0]))
    res = dropdefaults!(Fiber(Element(false)), arr)
    @test isstructequal(res, ref)
    arr = fill(true)
    ref = Fiber(Element{false, Bool}([1]))
    res = dropdefaults!(Fiber(Element(false)), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(Dense{Int}(5, Element{false, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(Dense(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(Dense{Int}(5, Element{false, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(Dense(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(Dense{Int}(4, Element{false, Bool}([0, 1, 0, 1])))
    res = dropdefaults!(Fiber(Dense(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, Dense{Int}(5, Element{false, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, Dense{Int}(5, Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, Dense{Int}(4, Element{false, Bool}([0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1]))))
    res = dropdefaults!(Fiber(Dense(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], Dense{Int}(5, Element{false, Bool}([]))))
    res = dropdefaults!(Fiber(SparseList(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], Dense{Int}(5, Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 3, 4], Dense{Int}(4, Element{false, Bool}([0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1]))))
    res = dropdefaults!(Fiber(SparseList(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], Element{false, Bool}([])))
    res = dropdefaults!(Fiber(SparseList(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], Element{false, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(SparseList(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 3], [2, 4], Element{false, Bool}([1, 1])))
    res = dropdefaults!(Fiber(SparseList(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseList{Int, Int}(5, [1, 1, 1, 1, 1, 1], [], Element{false, Bool}([]))))
    res = dropdefaults!(Fiber(Dense(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseList{Int, Int}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseList{Int, Int}(4, [1, 3, 3, 7, 9], [2, 4, 1, 2, 3, 4, 2, 4], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseList{Int, Int}(5, [1], [], Element{false, Bool}([]))))
    res = dropdefaults!(Fiber(SparseList(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseList{Int, Int}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 3, 4], SparseList{Int, Int}(4, [1, 3, 7, 9], [2, 4, 1, 2, 3, 4, 2, 4], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseListDiff{Int, Int}(5, [1, 1], [], [0], Element{false, Bool}([])))
    res = dropdefaults!(Fiber(SparseListDiff(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseListDiff{Int, Int}(5, [1, 6], [0x01, 0x01, 0x01, 0x01, 0x01], [5], Element{false, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(SparseListDiff(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseListDiff{Int, Int}(4, [1, 3], [0x02, 0x02], [4], Element{false, Bool}([1, 1])))
    res = dropdefaults!(Fiber(SparseListDiff(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseListDiff{Int, Int}(5, [1, 1, 1, 1, 1, 1], [], [0, 0, 0, 0, 0], Element{false, Bool}([]))))
    res = dropdefaults!(Fiber(Dense(SparseListDiff(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseListDiff{Int, Int}(5, [1, 6, 11, 16, 21, 26], [0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01], [5, 5, 5, 5, 5], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseListDiff(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseListDiff{Int, Int}(4, [1, 3, 3, 7, 9], [0x02, 0x02, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02], [4, 0, 4, 4], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseListDiff(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseListDiff{Int, Int}(5, [1], [], [], Element{false, Bool}([]))))
    res = dropdefaults!(Fiber(SparseList(SparseListDiff(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseListDiff{Int, Int}(5, [1, 6, 11, 16, 21, 26], [0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01], [5, 5, 5, 5, 5], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseListDiff(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 3, 4], SparseListDiff{Int, Int}(4, [1, 3, 7, 9], [0x02, 0x02, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02], [4, 4, 4], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseListDiff(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseVBL{Int, Int}(5, [1, 1], [], [1], Element{false, Bool}([])))
    res = dropdefaults!(Fiber(SparseVBL(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseVBL{Int, Int}(5, [1, 2], [5], [1, 6], Element{false, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(SparseVBL(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseVBL{Int, Int}(4, [1, 3], [2, 4], [1, 2, 3], Element{false, Bool}([1, 1])))
    res = dropdefaults!(Fiber(SparseVBL(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseVBL{Int, Int}(5, [1, 1, 1, 1, 1, 1], [], [1], Element{false, Bool}([]))))
    res = dropdefaults!(Fiber(Dense(SparseVBL(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseVBL{Int, Int}(5, [1, 2, 3, 4, 5, 6], [5, 5, 5, 5, 5], [1, 6, 11, 16, 21, 26], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseVBL(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseVBL{Int, Int}(4, [1, 3, 3, 4, 6], [2, 4, 4, 2, 4], [1, 2, 3, 7, 8, 9], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseVBL(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseVBL{Int, Int}(5, [1], [], [1], Element{false, Bool}([]))))
    res = dropdefaults!(Fiber(SparseList(SparseVBL(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseVBL{Int, Int}(5, [1, 2, 3, 4, 5, 6], [5, 5, 5, 5, 5], [1, 6, 11, 16, 21, 26], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseVBL(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 3, 4], SparseVBL{Int, Int}(4, [1, 3, 4, 6], [2, 4, 4, 2, 4], [1, 2, 3, 7, 8, 9], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseVBL(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseBytemap{Int, Int}(5, [1, 1], [0, 0, 0, 0, 0], [], Base.RefValue{Int}(0), Element{false, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(SparseBytemap(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseBytemap{Int, Int}(5, [1, 6], [1, 1, 1, 1, 1], [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5)], Base.RefValue{Int}(5), Element{false, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(SparseBytemap(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseBytemap{Int, Int}(4, [1, 3], [0, 1, 0, 1], [(1, 2), (1, 4)], Base.RefValue{Int}(2), Element{false, Bool}([0, 1, 0, 1])))
    res = dropdefaults!(Fiber(SparseBytemap(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseBytemap{Int, Int}(5, [1, 1, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [], Base.RefValue{Int}(0), Element{false, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseBytemap(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseBytemap{Int, Int}(5, [1, 6, 11, 16, 21, 26], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5)], Base.RefValue{Int}(25), Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseBytemap(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseBytemap{Int, Int}(4, [1, 3, 3, 7, 9], [0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1], [(1, 2), (1, 4), (3, 1), (3, 2), (3, 3), (3, 4), (4, 2), (4, 4)], Base.RefValue{Int}(8), Element{false, Bool}([0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseBytemap(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseBytemap{Int, Int}(5, [1], [], [], Base.RefValue{Int}(0), Element{false, Bool}([]))))
    res = dropdefaults!(Fiber(SparseList(SparseBytemap(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseBytemap{Int, Int}(5, [1, 6, 11, 16, 21, 26], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5)], Base.RefValue{Int}(25), Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseBytemap(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 3, 4], SparseBytemap{Int, Int}(4, [1, 3, 7, 9], [0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1], [(1, 2), (1, 4), (2, 1), (2, 2), (2, 3), (2, 4), (3, 2), (3, 4)], Base.RefValue{Int}(8), Element{false, Bool}([0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseBytemap(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}(), [1, 1], [], Element{false, Bool}([])))
    res = dropdefaults!(Fiber(SparseHash{1}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5), [1, 6], [(1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5], Element{false, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(SparseHash{1}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseHash{1, Tuple{Int}, Int}((4,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (2,)) => 1, (1, (4,)) => 2), [1, 3], [(1, (2,)) => 1, (1, (4,)) => 2], Element{false, Bool}([1, 1])))
    res = dropdefaults!(Fiber(SparseHash{1}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}(), [1, 1, 1, 1, 1, 1], [], Element{false, Bool}([]))))
    res = dropdefaults!(Fiber(Dense(SparseHash{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25), [1, 6, 11, 16, 21, 26], [(1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseHash{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseHash{1, Tuple{Int}, Int}((4,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (2,)) => 1, (1, (4,)) => 2, (3, (1,)) => 3, (3, (2,)) => 4, (3, (3,)) => 5, (3, (4,)) => 6, (4, (2,)) => 7, (4, (4,)) => 8), [1, 3, 3, 7, 9], [(1, (2,)) => 1, (1, (4,)) => 2, (3, (1,)) => 3, (3, (2,)) => 4, (3, (3,)) => 5, (3, (4,)) => 6, (4, (2,)) => 7, (4, (4,)) => 8], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseHash{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}(), [1], [], Element{false, Bool}([]))))
    res = dropdefaults!(Fiber(SparseList(SparseHash{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25), [1, 6, 11, 16, 21, 26], [(1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseHash{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 3, 4], SparseHash{1, Tuple{Int}, Int}((4,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (2,)) => 1, (1, (4,)) => 2, (2, (1,)) => 3, (2, (2,)) => 4, (2, (3,)) => 5, (2, (4,)) => 6, (3, (2,)) => 7, (3, (4,)) => 8), [1, 3, 7, 9], [(1, (2,)) => 1, (1, (4,)) => 2, (2, (1,)) => 3, (2, (2,)) => 4, (2, (3,)) => 5, (2, (4,)) => 6, (3, (2,)) => 7, (3, (4,)) => 8], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseHash{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseCoo{1, Tuple{Int}, Int}((5,), (Int[], ), [1, 1], Element{false, Bool}([])))
    res = dropdefaults!(Fiber(SparseCoo{1}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int}, Int}((5,), (Int[1, 2, 3, 4, 5], ), [1, 6], Element{false, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(SparseCoo{1}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int}, Int}((4,), (Int[2, 4], ), [1, 3], Element{false, Bool}([1, 1])))
    res = dropdefaults!(Fiber(SparseCoo{1}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseCoo{1, Tuple{Int}, Int}((5,), (Int[], ), [1, 1, 1, 1, 1, 1], Element{false, Bool}([]))))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseCoo{1, Tuple{Int}, Int}((5,), (Int[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseCoo{1, Tuple{Int}, Int}((4,), (Int[2, 4, 1, 2, 3, 4, 2, 4], ), [1, 3, 3, 7, 9], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseCoo{1, Tuple{Int}, Int}((5,), (Int[], ), [1], Element{false, Bool}([]))))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseCoo{1, Tuple{Int}, Int}((5,), (Int[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 3, 4], SparseCoo{1, Tuple{Int}, Int}((4,), (Int[2, 4, 1, 2, 3, 4, 2, 4], ), [1, 3, 7, 9], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseCoo{2, Tuple{Int, Int}, Int}((5, 5), (Int[], Int[], ), [1, 1], Element{false, Bool}([])))
    res = dropdefaults!(Fiber(SparseCoo{2}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseCoo{2, Tuple{Int, Int}, Int}((5, 5), (Int[1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5], Int[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 26], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(SparseCoo{2}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseCoo{2, Tuple{Int, Int}, Int}((4, 4), (Int[1, 1, 3, 3, 3, 3, 4, 4], Int[2, 4, 1, 2, 3, 4, 2, 4], ), [1, 9], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(SparseCoo{2}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseHash{2, Tuple{Int, Int}, Int}((5, 5), Dict{Tuple{Int, Tuple{Int, Int}}, Int}(), [1, 1], [], Element{false, Bool}([])))
    res = dropdefaults!(Fiber(SparseHash{2}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseHash{2, Tuple{Int, Int}, Int}((5, 5), Dict{Tuple{Int, Tuple{Int, Int}}, Int}((1, (1, 1)) => 1, (1, (1, 2)) => 2, (1, (1, 3)) => 3, (1, (1, 4)) => 4, (1, (1, 5)) => 5, (1, (2, 1)) => 6, (1, (2, 2)) => 7, (1, (2, 3)) => 8, (1, (2, 4)) => 9, (1, (2, 5)) => 10, (1, (3, 1)) => 11, (1, (3, 2)) => 12, (1, (3, 3)) => 13, (1, (3, 4)) => 14, (1, (3, 5)) => 15, (1, (4, 1)) => 16, (1, (4, 2)) => 17, (1, (4, 3)) => 18, (1, (4, 4)) => 19, (1, (4, 5)) => 20, (1, (5, 1)) => 21, (1, (5, 2)) => 22, (1, (5, 3)) => 23, (1, (5, 4)) => 24, (1, (5, 5)) => 25), [1, 26], [(1, (1, 1)) => 1, (1, (1, 2)) => 2, (1, (1, 3)) => 3, (1, (1, 4)) => 4, (1, (1, 5)) => 5, (1, (2, 1)) => 6, (1, (2, 2)) => 7, (1, (2, 3)) => 8, (1, (2, 4)) => 9, (1, (2, 5)) => 10, (1, (3, 1)) => 11, (1, (3, 2)) => 12, (1, (3, 3)) => 13, (1, (3, 4)) => 14, (1, (3, 5)) => 15, (1, (4, 1)) => 16, (1, (4, 2)) => 17, (1, (4, 3)) => 18, (1, (4, 4)) => 19, (1, (4, 5)) => 20, (1, (5, 1)) => 21, (1, (5, 2)) => 22, (1, (5, 3)) => 23, (1, (5, 4)) => 24, (1, (5, 5)) => 25], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(SparseHash{2}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseHash{2, Tuple{Int, Int}, Int}((4, 4), Dict{Tuple{Int, Tuple{Int, Int}}, Int}((1, (1, 2)) => 1, (1, (1, 4)) => 2, (1, (3, 1)) => 3, (1, (3, 2)) => 4, (1, (3, 3)) => 5, (1, (3, 4)) => 6, (1, (4, 2)) => 7, (1, (4, 4)) => 8), [1, 9], [(1, (1, 2)) => 1, (1, (1, 4)) => 2, (1, (3, 1)) => 3, (1, (3, 2)) => 4, (1, (3, 3)) => 5, (1, (3, 4)) => 6, (1, (4, 2)) => 7, (1, (4, 4)) => 8], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(SparseHash{2}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = fill(false)
    ref = Fiber(Element{true, Bool}([0]))
    res = dropdefaults!(Fiber(Element(true)), arr)
    @test isstructequal(res, ref)
    arr = fill(true)
    ref = Fiber(Element{true, Bool}([1]))
    res = dropdefaults!(Fiber(Element(true)), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(Dense{Int}(5, Element{true, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(Dense(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(Dense{Int}(5, Element{true, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(Dense(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(Dense{Int}(4, Element{true, Bool}([0, 1, 0, 1])))
    res = dropdefaults!(Fiber(Dense(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, Dense{Int}(5, Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, Dense{Int}(5, Element{true, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, Dense{Int}(4, Element{true, Bool}([0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1]))))
    res = dropdefaults!(Fiber(Dense(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], Dense{Int}(5, Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], Dense{Int}(5, Element{true, Bool}([]))))
    res = dropdefaults!(Fiber(SparseList(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 2, 4], Dense{Int}(4, Element{true, Bool}([0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1]))))
    res = dropdefaults!(Fiber(SparseList(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], Element{true, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(SparseList(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], Element{true, Bool}([])))
    res = dropdefaults!(Fiber(SparseList(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 3], [1, 3], Element{true, Bool}([0, 0])))
    res = dropdefaults!(Fiber(SparseList(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseList{Int, Int}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseList{Int, Int}(5, [1, 1, 1, 1, 1, 1], [], Element{true, Bool}([]))))
    res = dropdefaults!(Fiber(Dense(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseList{Int, Int}(4, [1, 3, 7, 7, 9], [1, 3, 1, 2, 3, 4, 1, 3], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseList{Int, Int}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseList{Int, Int}(5, [1], [], Element{true, Bool}([]))))
    res = dropdefaults!(Fiber(SparseList(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 2, 4], SparseList{Int, Int}(4, [1, 3, 7, 9], [1, 3, 1, 2, 3, 4, 1, 3], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseListDiff{Int, Int}(5, [1, 6], [0x01, 0x01, 0x01, 0x01, 0x01], [5], Element{true, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(SparseListDiff(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseListDiff{Int, Int}(5, [1, 1], [], [0], Element{true, Bool}([])))
    res = dropdefaults!(Fiber(SparseListDiff(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseListDiff{Int, Int}(4, [1, 3], [0x01, 0x02], [3], Element{true, Bool}([0, 0])))
    res = dropdefaults!(Fiber(SparseListDiff(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseListDiff{Int, Int}(5, [1, 6, 11, 16, 21, 26], [0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01], [5, 5, 5, 5, 5], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseListDiff(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseListDiff{Int, Int}(5, [1, 1, 1, 1, 1, 1], [], [0, 0, 0, 0, 0], Element{true, Bool}([]))))
    res = dropdefaults!(Fiber(Dense(SparseListDiff(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseListDiff{Int, Int}(4, [1, 3, 7, 7, 9], [0x01, 0x02, 0x01, 0x01, 0x01, 0x01, 0x01, 0x02], [3, 4, 0, 3], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseListDiff(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseListDiff{Int, Int}(5, [1, 6, 11, 16, 21, 26], [0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01], [5, 5, 5, 5, 5], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(SparseListDiff(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseListDiff{Int, Int}(5, [1], [], [], Element{true, Bool}([]))))
    res = dropdefaults!(Fiber(SparseList(SparseListDiff(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 2, 4], SparseListDiff{Int, Int}(4, [1, 3, 7, 9], [0x01, 0x02, 0x01, 0x01, 0x01, 0x01, 0x01, 0x02], [3, 4, 3], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(SparseListDiff(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseVBL{Int, Int}(5, [1, 2], [5], [1, 6], Element{true, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(SparseVBL(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseVBL{Int, Int}(5, [1, 1], [], [1], Element{true, Bool}([])))
    res = dropdefaults!(Fiber(SparseVBL(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseVBL{Int, Int}(4, [1, 3], [1, 3], [1, 2, 3], Element{true, Bool}([0, 0])))
    res = dropdefaults!(Fiber(SparseVBL(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseVBL{Int, Int}(5, [1, 2, 3, 4, 5, 6], [5, 5, 5, 5, 5], [1, 6, 11, 16, 21, 26], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseVBL(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseVBL{Int, Int}(5, [1, 1, 1, 1, 1, 1], [], [1], Element{true, Bool}([]))))
    res = dropdefaults!(Fiber(Dense(SparseVBL(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseVBL{Int, Int}(4, [1, 3, 4, 4, 6], [1, 3, 4, 1, 3], [1, 2, 3, 7, 8, 9], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseVBL(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseVBL{Int, Int}(5, [1, 2, 3, 4, 5, 6], [5, 5, 5, 5, 5], [1, 6, 11, 16, 21, 26], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(SparseVBL(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseVBL{Int, Int}(5, [1], [], [1], Element{true, Bool}([]))))
    res = dropdefaults!(Fiber(SparseList(SparseVBL(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 2, 4], SparseVBL{Int, Int}(4, [1, 3, 4, 6], [1, 3, 4, 1, 3], [1, 2, 3, 7, 8, 9], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(SparseVBL(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseBytemap{Int, Int}(5, [1, 6], [1, 1, 1, 1, 1], [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5)], Base.RefValue{Int}(5), Element{true, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(SparseBytemap(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseBytemap{Int, Int}(5, [1, 1], [0, 0, 0, 0, 0], [], Base.RefValue{Int}(0), Element{true, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(SparseBytemap(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseBytemap{Int, Int}(4, [1, 3], [1, 0, 1, 0], [(1, 1), (1, 3)], Base.RefValue{Int}(2), Element{true, Bool}([0, 1, 0, 1])))
    res = dropdefaults!(Fiber(SparseBytemap(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseBytemap{Int, Int}(5, [1, 6, 11, 16, 21, 26], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5)], Base.RefValue{Int}(25), Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseBytemap(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseBytemap{Int, Int}(5, [1, 1, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [], Base.RefValue{Int}(0), Element{true, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseBytemap(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseBytemap{Int, Int}(4, [1, 3, 7, 7, 9], [1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 1, 0], [(1, 1), (1, 3), (2, 1), (2, 2), (2, 3), (2, 4), (4, 1), (4, 3)], Base.RefValue{Int}(8), Element{true, Bool}([0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseBytemap(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseBytemap{Int, Int}(5, [1, 6, 11, 16, 21, 26], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5)], Base.RefValue{Int}(25), Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(SparseBytemap(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseBytemap{Int, Int}(5, [1], [], [], Base.RefValue{Int}(0), Element{true, Bool}([]))))
    res = dropdefaults!(Fiber(SparseList(SparseBytemap(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 2, 4], SparseBytemap{Int, Int}(4, [1, 3, 7, 9], [1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0], [(1, 1), (1, 3), (2, 1), (2, 2), (2, 3), (2, 4), (3, 1), (3, 3)], Base.RefValue{Int}(8), Element{true, Bool}([0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseBytemap(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5), [1, 6], [(1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5], Element{true, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(SparseHash{1}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}(), [1, 1], [], Element{true, Bool}([])))
    res = dropdefaults!(Fiber(SparseHash{1}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseHash{1, Tuple{Int}, Int}((4,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (1,)) => 1, (1, (3,)) => 2), [1, 3], [(1, (1,)) => 1, (1, (3,)) => 2], Element{true, Bool}([0, 0])))
    res = dropdefaults!(Fiber(SparseHash{1}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25), [1, 6, 11, 16, 21, 26], [(1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseHash{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}(), [1, 1, 1, 1, 1, 1], [], Element{true, Bool}([]))))
    res = dropdefaults!(Fiber(Dense(SparseHash{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseHash{1, Tuple{Int}, Int}((4,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (1,)) => 1, (1, (3,)) => 2, (2, (1,)) => 3, (2, (2,)) => 4, (2, (3,)) => 5, (2, (4,)) => 6, (4, (1,)) => 7, (4, (3,)) => 8), [1, 3, 7, 7, 9], [(1, (1,)) => 1, (1, (3,)) => 2, (2, (1,)) => 3, (2, (2,)) => 4, (2, (3,)) => 5, (2, (4,)) => 6, (4, (1,)) => 7, (4, (3,)) => 8], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseHash{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25), [1, 6, 11, 16, 21, 26], [(1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(SparseHash{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseHash{1, Tuple{Int}, Int}((5,), Dict{Tuple{Int, Tuple{Int}}, Int}(), [1], [], Element{true, Bool}([]))))
    res = dropdefaults!(Fiber(SparseList(SparseHash{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 2, 4], SparseHash{1, Tuple{Int}, Int}((4,), Dict{Tuple{Int, Tuple{Int}}, Int}((1, (1,)) => 1, (1, (3,)) => 2, (2, (1,)) => 3, (2, (2,)) => 4, (2, (3,)) => 5, (2, (4,)) => 6, (3, (1,)) => 7, (3, (3,)) => 8), [1, 3, 7, 9], [(1, (1,)) => 1, (1, (3,)) => 2, (2, (1,)) => 3, (2, (2,)) => 4, (2, (3,)) => 5, (2, (4,)) => 6, (3, (1,)) => 7, (3, (3,)) => 8], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(SparseHash{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseCoo{1, Tuple{Int}, Int}((5,), (Int[1, 2, 3, 4, 5], ), [1, 6], Element{true, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(SparseCoo{1}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int}, Int}((5,), (Int[], ), [1, 1], Element{true, Bool}([])))
    res = dropdefaults!(Fiber(SparseCoo{1}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int}, Int}((4,), (Int[1, 3], ), [1, 3], Element{true, Bool}([0, 0])))
    res = dropdefaults!(Fiber(SparseCoo{1}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int}(5, SparseCoo{1, Tuple{Int}, Int}((5,), (Int[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int}(5, SparseCoo{1, Tuple{Int}, Int}((5,), (Int[], ), [1, 1, 1, 1, 1, 1], Element{true, Bool}([]))))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int}(4, SparseCoo{1, Tuple{Int}, Int}((4,), (Int[1, 3, 1, 2, 3, 4, 1, 3], ), [1, 3, 7, 7, 9], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int, Int}(5, [1, 6], [1, 2, 3, 4, 5], SparseCoo{1, Tuple{Int}, Int}((5,), (Int[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int, Int}(5, [1, 1], [], SparseCoo{1, Tuple{Int}, Int}((5,), (Int[], ), [1], Element{true, Bool}([]))))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int, Int}(4, [1, 4], [1, 2, 4], SparseCoo{1, Tuple{Int}, Int}((4,), (Int[1, 3, 1, 2, 3, 4, 1, 3], ), [1, 3, 7, 9], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseCoo{2, Tuple{Int, Int}, Int}((5, 5), (Int[1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5], Int[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 26], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(SparseCoo{2}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseCoo{2, Tuple{Int, Int}, Int}((5, 5), (Int[], Int[], ), [1, 1], Element{true, Bool}([])))
    res = dropdefaults!(Fiber(SparseCoo{2}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseCoo{2, Tuple{Int, Int}, Int}((4, 4), (Int[1, 1, 2, 2, 2, 2, 4, 4], Int[1, 3, 1, 2, 3, 4, 1, 3], ), [1, 9], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(SparseCoo{2}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseHash{2, Tuple{Int, Int}, Int}((5, 5), Dict{Tuple{Int, Tuple{Int, Int}}, Int}((1, (1, 1)) => 1, (1, (1, 2)) => 2, (1, (1, 3)) => 3, (1, (1, 4)) => 4, (1, (1, 5)) => 5, (1, (2, 1)) => 6, (1, (2, 2)) => 7, (1, (2, 3)) => 8, (1, (2, 4)) => 9, (1, (2, 5)) => 10, (1, (3, 1)) => 11, (1, (3, 2)) => 12, (1, (3, 3)) => 13, (1, (3, 4)) => 14, (1, (3, 5)) => 15, (1, (4, 1)) => 16, (1, (4, 2)) => 17, (1, (4, 3)) => 18, (1, (4, 4)) => 19, (1, (4, 5)) => 20, (1, (5, 1)) => 21, (1, (5, 2)) => 22, (1, (5, 3)) => 23, (1, (5, 4)) => 24, (1, (5, 5)) => 25), [1, 26], [(1, (1, 1)) => 1, (1, (1, 2)) => 2, (1, (1, 3)) => 3, (1, (1, 4)) => 4, (1, (1, 5)) => 5, (1, (2, 1)) => 6, (1, (2, 2)) => 7, (1, (2, 3)) => 8, (1, (2, 4)) => 9, (1, (2, 5)) => 10, (1, (3, 1)) => 11, (1, (3, 2)) => 12, (1, (3, 3)) => 13, (1, (3, 4)) => 14, (1, (3, 5)) => 15, (1, (4, 1)) => 16, (1, (4, 2)) => 17, (1, (4, 3)) => 18, (1, (4, 4)) => 19, (1, (4, 5)) => 20, (1, (5, 1)) => 21, (1, (5, 2)) => 22, (1, (5, 3)) => 23, (1, (5, 4)) => 24, (1, (5, 5)) => 25], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(SparseHash{2}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseHash{2, Tuple{Int, Int}, Int}((5, 5), Dict{Tuple{Int, Tuple{Int, Int}}, Int}(), [1, 1], [], Element{true, Bool}([])))
    res = dropdefaults!(Fiber(SparseHash{2}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseHash{2, Tuple{Int, Int}, Int}((4, 4), Dict{Tuple{Int, Tuple{Int, Int}}, Int}((1, (1, 1)) => 1, (1, (1, 3)) => 2, (1, (2, 1)) => 3, (1, (2, 2)) => 4, (1, (2, 3)) => 5, (1, (2, 4)) => 6, (1, (4, 1)) => 7, (1, (4, 3)) => 8), [1, 9], [(1, (1, 1)) => 1, (1, (1, 3)) => 2, (1, (2, 1)) => 3, (1, (2, 2)) => 4, (1, (2, 3)) => 5, (1, (2, 4)) => 6, (1, (4, 1)) => 7, (1, (4, 3)) => 8], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(SparseHash{2}(Element(true))), arr)
    @test isstructequal(res, ref)
end
