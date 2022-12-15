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
    ref = Fiber(Dense{Int64}(5, Pattern()))
    res = dropdefaults!(Fiber(Dense(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(Dense{Int64}(5, Pattern()))
    res = dropdefaults!(Fiber(Dense(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(Dense{Int64}(4, Pattern()))
    res = dropdefaults!(Fiber(Dense(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, Dense{Int64}(5, Pattern())))
    res = dropdefaults!(Fiber(Dense(Dense(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, Dense{Int64}(5, Pattern())))
    res = dropdefaults!(Fiber(Dense(Dense(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, Dense{Int64}(4, Pattern())))
    res = dropdefaults!(Fiber(Dense(Dense(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64}(5, [1, 1], Int64[], Dense{Int64}(5, Pattern())))
    res = dropdefaults!(Fiber(SparseList(Dense(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64}(5, [1, 6], [1, 2, 3, 4, 5], Dense{Int64}(5, Pattern())))
    res = dropdefaults!(Fiber(SparseList(Dense(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64}(4, [1, 4], [1, 3, 4], Dense{Int64}(4, Pattern())))
    res = dropdefaults!(Fiber(SparseList(Dense(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseList{Int64}(5, [1, 1], Int64[], Pattern()))
    res = dropdefaults!(Fiber(SparseList(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseList{Int64}(5, [1, 6], [1, 2, 3, 4, 5], Pattern()))
    res = dropdefaults!(Fiber(SparseList(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseList{Int64}(4, [1, 3], [2, 4], Pattern()))
    res = dropdefaults!(Fiber(SparseList(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseList{Int64}(5, [1, 1, 1, 1, 1, 1], Int64[], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseList(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseList{Int64}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseList(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseList{Int64}(4, [1, 3, 3, 7, 9], [2, 4, 1, 2, 3, 4, 2, 4], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseList(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64}(5, [1, 1], Int64[], SparseList{Int64}(5, [1], Int64[], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseList(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseList{Int64}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseList(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64}(4, [1, 4], [1, 3, 4], SparseList{Int64}(4, [1, 3, 7, 9], [2, 4, 1, 2, 3, 4, 2, 4], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseList(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseCoo{1, Tuple{Int64}}((5,), (Int64[], ), [1, 1], Pattern()))
    res = dropdefaults!(Fiber(SparseCoo{1}(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int64}}((5,), ([1, 2, 3, 4, 5], ), [1, 6], Pattern()))
    res = dropdefaults!(Fiber(SparseCoo{1}(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int64}}((4,), ([2, 4], ), [1, 3], Pattern()))
    res = dropdefaults!(Fiber(SparseCoo{1}(Pattern())), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseCoo{1, Tuple{Int64}}((5,), (Int64[], ), [1, 1, 1, 1, 1, 1], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseCoo{1, Tuple{Int64}}((5,), ([1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseCoo{1, Tuple{Int64}}((4,), ([2, 4, 1, 2, 3, 4, 2, 4], ), [1, 3, 3, 7, 9], Pattern())))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64}(5, [1, 1], Int64[], SparseCoo{1, Tuple{Int64}}((5,), (Int64[], ), [1], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseCoo{1, Tuple{Int64}}((5,), ([1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64}(4, [1, 4], [1, 3, 4], SparseCoo{1, Tuple{Int64}}((4,), ([2, 4, 1, 2, 3, 4, 2, 4], ), [1, 3, 7, 9], Pattern())))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Pattern()))), arr)
    @test isstructequal(res, ref)
    arr = fill(false)
    ref = Fiber(Element{false}(Bool[0]))
    res = dropdefaults!(Fiber(Element(false)), arr)
    @test isstructequal(res, ref)
    arr = fill(true)
    ref = Fiber(Element{false}(Bool[1]))
    res = dropdefaults!(Fiber(Element(false)), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(Dense{Int64}(5, Element{false}(Bool[0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(Dense(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(Dense{Int64}(5, Element{false}(Bool[1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(Dense(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(Dense{Int64}(4, Element{false}(Bool[0, 1, 0, 1])))
    res = dropdefaults!(Fiber(Dense(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, Dense{Int64}(5, Element{false}(Bool[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, Dense{Int64}(5, Element{false}(Bool[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, Dense{Int64}(4, Element{false}(Bool[0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1]))))
    res = dropdefaults!(Fiber(Dense(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64}(5, [1, 1], Int64[], Dense{Int64}(5, Element{false}(Bool[]))))
    res = dropdefaults!(Fiber(SparseList(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64}(5, [1, 6], [1, 2, 3, 4, 5], Dense{Int64}(5, Element{false}(Bool[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64}(4, [1, 4], [1, 3, 4], Dense{Int64}(4, Element{false}(Bool[0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1]))))
    res = dropdefaults!(Fiber(SparseList(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseList{Int64}(5, [1, 1], Int64[], Element{false}(Bool[])))
    res = dropdefaults!(Fiber(SparseList(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseList{Int64}(5, [1, 6], [1, 2, 3, 4, 5], Element{false}(Bool[1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(SparseList(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseList{Int64}(4, [1, 3], [2, 4], Element{false}(Bool[1, 1])))
    res = dropdefaults!(Fiber(SparseList(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseList{Int64}(5, [1, 1, 1, 1, 1, 1], Int64[], Element{false}(Bool[]))))
    res = dropdefaults!(Fiber(Dense(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseList{Int64}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Element{false}(Bool[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseList{Int64}(4, [1, 3, 3, 7, 9], [2, 4, 1, 2, 3, 4, 2, 4], Element{false}(Bool[1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64}(5, [1, 1], Int64[], SparseList{Int64}(5, [1], Int64[], Element{false}(Bool[]))))
    res = dropdefaults!(Fiber(SparseList(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseList{Int64}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Element{false}(Bool[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64}(4, [1, 4], [1, 3, 4], SparseList{Int64}(4, [1, 3, 7, 9], [2, 4, 1, 2, 3, 4, 2, 4], Element{false}(Bool[1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseCoo{1, Tuple{Int64}}((5,), (Int64[], ), [1, 1], Element{false}(Bool[])))
    res = dropdefaults!(Fiber(SparseCoo{1}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int64}}((5,), ([1, 2, 3, 4, 5], ), [1, 6], Element{false}(Bool[1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(SparseCoo{1}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int64}}((4,), ([2, 4], ), [1, 3], Element{false}(Bool[1, 1])))
    res = dropdefaults!(Fiber(SparseCoo{1}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseCoo{1, Tuple{Int64}}((5,), (Int64[], ), [1, 1, 1, 1, 1, 1], Element{false}(Bool[]))))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseCoo{1, Tuple{Int64}}((5,), ([1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Element{false}(Bool[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseCoo{1, Tuple{Int64}}((4,), ([2, 4, 1, 2, 3, 4, 2, 4], ), [1, 3, 3, 7, 9], Element{false}(Bool[1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64}(5, [1, 1], Int64[], SparseCoo{1, Tuple{Int64}}((5,), (Int64[], ), [1], Element{false}(Bool[]))))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseCoo{1, Tuple{Int64}}((5,), ([1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Element{false}(Bool[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64}(4, [1, 4], [1, 3, 4], SparseCoo{1, Tuple{Int64}}((4,), ([2, 4, 1, 2, 3, 4, 2, 4], ), [1, 3, 7, 9], Element{false}(Bool[1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = fill(false)
    ref = Fiber(Element{true}(Bool[0]))
    res = dropdefaults!(Fiber(Element(true)), arr)
    @test isstructequal(res, ref)
    arr = fill(true)
    ref = Fiber(Element{true}(Bool[1]))
    res = dropdefaults!(Fiber(Element(true)), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(Dense{Int64}(5, Element{true}(Bool[0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(Dense(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(Dense{Int64}(5, Element{true}(Bool[1, 1, 1, 1, 1])))
    res = dropdefaults!(Fiber(Dense(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(Dense{Int64}(4, Element{true}(Bool[0, 1, 0, 1])))
    res = dropdefaults!(Fiber(Dense(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, Dense{Int64}(5, Element{true}(Bool[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, Dense{Int64}(5, Element{true}(Bool[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(Fiber(Dense(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, Dense{Int64}(4, Element{true}(Bool[0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1]))))
    res = dropdefaults!(Fiber(Dense(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64}(5, [1, 6], [1, 2, 3, 4, 5], Dense{Int64}(5, Element{true}(Bool[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64}(5, [1, 1], Int64[], Dense{Int64}(5, Element{true}(Bool[]))))
    res = dropdefaults!(Fiber(SparseList(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64}(4, [1, 4], [1, 2, 4], Dense{Int64}(4, Element{true}(Bool[0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1]))))
    res = dropdefaults!(Fiber(SparseList(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseList{Int64}(5, [1, 6], [1, 2, 3, 4, 5], Element{true}(Bool[0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(SparseList(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseList{Int64}(5, [1, 1], Int64[], Element{true}(Bool[])))
    res = dropdefaults!(Fiber(SparseList(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseList{Int64}(4, [1, 3], [1, 3], Element{true}(Bool[0, 0])))
    res = dropdefaults!(Fiber(SparseList(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseList{Int64}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Element{true}(Bool[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseList{Int64}(5, [1, 1, 1, 1, 1, 1], Int64[], Element{true}(Bool[]))))
    res = dropdefaults!(Fiber(Dense(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseList{Int64}(4, [1, 3, 7, 7, 9], [1, 3, 1, 2, 3, 4, 1, 3], Element{true}(Bool[0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseList{Int64}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Element{true}(Bool[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64}(5, [1, 1], Int64[], SparseList{Int64}(5, [1], Int64[], Element{true}(Bool[]))))
    res = dropdefaults!(Fiber(SparseList(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64}(4, [1, 4], [1, 2, 4], SparseList{Int64}(4, [1, 3, 7, 9], [1, 3, 1, 2, 3, 4, 1, 3], Element{true}(Bool[0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseCoo{1, Tuple{Int64}}((5,), ([1, 2, 3, 4, 5], ), [1, 6], Element{true}(Bool[0, 0, 0, 0, 0])))
    res = dropdefaults!(Fiber(SparseCoo{1}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int64}}((5,), (Int64[], ), [1, 1], Element{true}(Bool[])))
    res = dropdefaults!(Fiber(SparseCoo{1}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int64}}((4,), ([1, 3], ), [1, 3], Element{true}(Bool[0, 0])))
    res = dropdefaults!(Fiber(SparseCoo{1}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseCoo{1, Tuple{Int64}}((5,), ([1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Element{true}(Bool[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseCoo{1, Tuple{Int64}}((5,), (Int64[], ), [1, 1, 1, 1, 1, 1], Element{true}(Bool[]))))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseCoo{1, Tuple{Int64}}((4,), ([1, 3, 1, 2, 3, 4, 1, 3], ), [1, 3, 7, 7, 9], Element{true}(Bool[0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(Dense(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseCoo{1, Tuple{Int64}}((5,), ([1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Element{true}(Bool[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64}(5, [1, 1], Int64[], SparseCoo{1, Tuple{Int64}}((5,), (Int64[], ), [1], Element{true}(Bool[]))))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64}(4, [1, 4], [1, 2, 4], SparseCoo{1, Tuple{Int64}}((4,), ([1, 3, 1, 2, 3, 4, 1, 3], ), [1, 3, 7, 9], Element{true}(Bool[0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(Fiber(SparseList(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
end
