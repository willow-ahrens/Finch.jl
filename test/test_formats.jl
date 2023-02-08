@testset "formats" begin
    arr = [0.0, 0.0, 0.0, 0.0, 0.0]
    ref = Fiber(RepeatRLE{0.0, Int64, Int64, Float64}(5, [1, 2], [5], [0.0]))
    res = dropdefaults!(allocate_fiber(RepeatRLE(0.0)), arr)
    @test isstructequal(res, ref)
    arr = [1.0, 1.0, 1.0, 1.0, 1.0]
    ref = Fiber(RepeatRLE{0.0, Int64, Int64, Float64}(5, [1, 3], [5, 5], [1.0, 0.0]))
    res = dropdefaults!(allocate_fiber(RepeatRLE(0.0)), arr)
    @test isstructequal(res, ref)
    arr = [0.0, 1.0, 1.0, 2.0, 2.0, 0.0, 0.0, 3.0, 0.0]
    ref = Fiber(RepeatRLE{0.0, Int64, Int64, Float64}(9, [1, 7], [1, 3, 5, 7, 8, 9], [0.0, 1.0, 2.0, 0.0, 3.0, 0.0]))
    res = dropdefaults!(allocate_fiber(RepeatRLE(0.0)), arr)
    @test isstructequal(res, ref)
    arr = [0.0 0.0 0.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0]
    ref = Fiber(Dense{Int64}(5, RepeatRLE{0.0, Int64, Int64, Float64}(5, [1, 2, 3, 4, 5, 6], [5, 5, 5, 5, 5], [0.0, 0.0, 0.0, 0.0, 0.0])))
    res = dropdefaults!(allocate_fiber(Dense(RepeatRLE(0.0))), arr)
    @test isstructequal(res, ref)
    arr = [1.0 1.0 1.0 1.0 1.0; 1.0 1.0 1.0 1.0 1.0; 1.0 1.0 1.0 1.0 1.0; 1.0 1.0 1.0 1.0 1.0; 1.0 1.0 1.0 1.0 1.0]
    ref = Fiber(Dense{Int64}(5, RepeatRLE{0.0, Int64, Int64, Float64}(5, [1, 3, 5, 7, 9, 11], [5, 5, 5, 5, 5, 5, 5, 5, 5, 5], [1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0])))
    res = dropdefaults!(allocate_fiber(Dense(RepeatRLE(0.0))), arr)
    @test isstructequal(res, ref)
    arr = [0.0 1.0 2.0 2.0; 0.0 0.0 0.0 0.0; 1.0 1.0 2.0 0.0; 0.0 0.0 0.0 0.0]
    ref = Fiber(Dense{Int64}(4, RepeatRLE{0.0, Int64, Int64, Float64}(4, [1, 5, 6, 9, 10], [1, 2, 4, 4, 4, 2, 3, 4, 4], [0.0, 1.0, 2.0, 0.0, 0.0, 1.0, 2.0, 0.0, 0.0])))
    res = dropdefaults!(allocate_fiber(Dense(RepeatRLE(0.0))), arr)
    @test isstructequal(res, ref)
    arr = [0.0 0.0 0.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0; 0.0 0.0 0.0 0.0 0.0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 1], [], RepeatRLE{0.0, Int64, Int64, Float64}(5, [1], [], [])))
    res = dropdefaults!(allocate_fiber(SparseList(RepeatRLE(0.0))), arr)
    @test isstructequal(res, ref)
    arr = [1.0 1.0 1.0 1.0 1.0; 1.0 1.0 1.0 1.0 1.0; 1.0 1.0 1.0 1.0 1.0; 1.0 1.0 1.0 1.0 1.0; 1.0 1.0 1.0 1.0 1.0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 6], [1, 2, 3, 4, 5], RepeatRLE{0.0, Int64, Int64, Float64}(5, [1, 3, 5, 7, 9, 11], [5, 5, 5, 5, 5, 5, 5, 5, 5, 5], [1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0])))
    res = dropdefaults!(allocate_fiber(SparseList(RepeatRLE(0.0))), arr)
    @test isstructequal(res, ref)
    arr = [0.0 1.0 2.0 2.0; 0.0 0.0 0.0 0.0; 1.0 1.0 2.0 0.0; 0.0 0.0 0.0 0.0]
    ref = Fiber(SparseList{Int64, Int64}(4, [1, 3], [1, 3], RepeatRLE{0.0, Int64, Int64, Float64}(4, [1, 5, 8], [1, 2, 4, 4, 2, 3, 4], [0.0, 1.0, 2.0, 0.0, 1.0, 2.0, 0.0])))
    res = dropdefaults!(allocate_fiber(SparseList(RepeatRLE(0.0))), arr)
    @test isstructequal(res, ref)
    arr = fill(false)
    ref = Fiber(Element{false, Bool}([0]))
    res = dropdefaults!(allocate_fiber(Element(false)), arr)
    @test isstructequal(res, ref)
    arr = fill(true)
    ref = Fiber(Element{false, Bool}([1]))
    res = dropdefaults!(allocate_fiber(Element(false)), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(Dense{Int64}(5, Element{false, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(allocate_fiber(Dense(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(Dense{Int64}(5, Element{false, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(allocate_fiber(Dense(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(Dense{Int64}(4, Element{false, Bool}([0, 1, 0, 1])))
    res = dropdefaults!(allocate_fiber(Dense(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, Dense{Int64}(5, Element{false, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(Dense(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, Dense{Int64}(5, Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, Dense{Int64}(4, Element{false, Bool}([0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 1], [], Dense{Int64}(5, Element{false, Bool}([]))))
    res = dropdefaults!(allocate_fiber(SparseList(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 6], [1, 2, 3, 4, 5], Dense{Int64}(5, Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(SparseList(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64, Int64}(4, [1, 4], [1, 3, 4], Dense{Int64}(4, Element{false, Bool}([0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1]))))
    res = dropdefaults!(allocate_fiber(SparseList(Dense(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 1], [], Element{false, Bool}([])))
    res = dropdefaults!(allocate_fiber(SparseList(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 6], [1, 2, 3, 4, 5], Element{false, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(allocate_fiber(SparseList(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseList{Int64, Int64}(4, [1, 3], [2, 4], Element{false, Bool}([1, 1])))
    res = dropdefaults!(allocate_fiber(SparseList(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseList{Int64, Int64}(5, [1, 1, 1, 1, 1, 1], [], Element{false, Bool}([]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseList{Int64, Int64}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseList{Int64, Int64}(4, [1, 3, 3, 7, 9], [2, 4, 1, 2, 3, 4, 2, 4], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 1], [], SparseList{Int64, Int64}(5, [1], [], Element{false, Bool}([]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseList{Int64, Int64}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64, Int64}(4, [1, 4], [1, 3, 4], SparseList{Int64, Int64}(4, [1, 3, 7, 9], [2, 4, 1, 2, 3, 4, 2, 4], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseList(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseVBL{Int64, Int64}(5, [1, 1], [], [1], Element{false, Bool}([])))
    res = dropdefaults!(allocate_fiber(SparseVBL(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseVBL{Int64, Int64}(5, [1, 2], [5], [1, 6], Element{false, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(allocate_fiber(SparseVBL(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseVBL{Int64, Int64}(4, [1, 3], [2, 4], [1, 2, 3], Element{false, Bool}([1, 1])))
    res = dropdefaults!(allocate_fiber(SparseVBL(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseVBL{Int64, Int64}(5, [1, 1, 1, 1, 1, 1], [], [1], Element{false, Bool}([]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseVBL(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseVBL{Int64, Int64}(5, [1, 2, 3, 4, 5, 6], [5, 5, 5, 5, 5], [1, 6, 11, 16, 21, 26], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseVBL(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseVBL{Int64, Int64}(4, [1, 3, 3, 4, 6], [2, 4, 4, 2, 4], [1, 2, 3, 7, 8, 9], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseVBL(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 1], [], SparseVBL{Int64, Int64}(5, [1], [], [1], Element{false, Bool}([]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseVBL(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseVBL{Int64, Int64}(5, [1, 2, 3, 4, 5, 6], [5, 5, 5, 5, 5], [1, 6, 11, 16, 21, 26], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseVBL(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64, Int64}(4, [1, 4], [1, 3, 4], SparseVBL{Int64, Int64}(4, [1, 3, 4, 6], [2, 4, 4, 2, 4], [1, 2, 3, 7, 8, 9], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseVBL(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseBytemap{Int64, Int64}(5, [1, 0], [0, 0, 0, 0, 0], [], Element{false, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(allocate_fiber(SparseBytemap(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseBytemap{Int64, Int64}(5, [1, 6], [1, 1, 1, 1, 1], [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5)], Element{false, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(allocate_fiber(SparseBytemap(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseBytemap{Int64, Int64}(4, [1, 3], [0, 1, 0, 1], [(1, 2), (1, 4)], Element{false, Bool}([0, 1, 0, 1])))
    res = dropdefaults!(allocate_fiber(SparseBytemap(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseBytemap{Int64, Int64}(5, [1, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [], Element{false, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseBytemap(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseBytemap{Int64, Int64}(5, [1, 6, 11, 16, 21, 26], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5)], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseBytemap(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseBytemap{Int64, Int64}(4, [1, 3, 3, 7, 9], [0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1], [(1, 2), (1, 4), (3, 1), (3, 2), (3, 3), (3, 4), (4, 2), (4, 4)], Element{false, Bool}([0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseBytemap(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 1], [], SparseBytemap{Int64, Int64}(5, [1], [], [], Element{false, Bool}([]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseBytemap(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseBytemap{Int64, Int64}(5, [1, 6, 11, 16, 21, 26], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5)], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseBytemap(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64, Int64}(4, [1, 4], [1, 3, 4], SparseBytemap{Int64, Int64}(4, [1, 3, 7, 9], [0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1], [(1, 2), (1, 4), (2, 1), (2, 2), (2, 3), (2, 4), (3, 2), (3, 4)], Element{false, Bool}([0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseBytemap(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseHash{1, Tuple{Int64}, Int64}((5,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}(), [1, 1], [], Element{false, Bool}([])))
    res = dropdefaults!(allocate_fiber(SparseHash{1}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseHash{1, Tuple{Int64}, Int64}((5,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}((1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5), [1, 6], [(1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5], Element{false, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(allocate_fiber(SparseHash{1}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseHash{1, Tuple{Int64}, Int64}((4,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}((1, (2,)) => 1, (1, (4,)) => 2), [1, 3], [(1, (2,)) => 1, (1, (4,)) => 2], Element{false, Bool}([1, 1])))
    res = dropdefaults!(allocate_fiber(SparseHash{1}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseHash{1, Tuple{Int64}, Int64}((5,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}(), [1, 1, 1, 1, 1, 1], [], Element{false, Bool}([]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseHash{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseHash{1, Tuple{Int64}, Int64}((5,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}((1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25), [1, 6, 11, 16, 21, 26], [(1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseHash{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseHash{1, Tuple{Int64}, Int64}((4,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}((1, (2,)) => 1, (1, (4,)) => 2, (3, (1,)) => 3, (3, (2,)) => 4, (3, (3,)) => 5, (3, (4,)) => 6, (4, (2,)) => 7, (4, (4,)) => 8), [1, 3, 3, 7, 9], [(1, (2,)) => 1, (1, (4,)) => 2, (3, (1,)) => 3, (3, (2,)) => 4, (3, (3,)) => 5, (3, (4,)) => 6, (4, (2,)) => 7, (4, (4,)) => 8], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseHash{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 1], [], SparseHash{1, Tuple{Int64}, Int64}((5,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}(), [1], [], Element{false, Bool}([]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseHash{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseHash{1, Tuple{Int64}, Int64}((5,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}((1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25), [1, 6, 11, 16, 21, 26], [(1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseHash{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64, Int64}(4, [1, 4], [1, 3, 4], SparseHash{1, Tuple{Int64}, Int64}((4,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}((1, (2,)) => 1, (1, (4,)) => 2, (2, (1,)) => 3, (2, (2,)) => 4, (2, (3,)) => 5, (2, (4,)) => 6, (3, (2,)) => 7, (3, (4,)) => 8), [1, 3, 7, 9], [(1, (2,)) => 1, (1, (4,)) => 2, (2, (1,)) => 3, (2, (2,)) => 4, (2, (3,)) => 5, (2, (4,)) => 6, (3, (2,)) => 7, (3, (4,)) => 8], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseHash{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseCoo{1, Tuple{Int64}, Int64}((5,), (Int64[], ), [1, 1], Element{false, Bool}([])))
    res = dropdefaults!(allocate_fiber(SparseCoo{1}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int64}, Int64}((5,), (Int64[1, 2, 3, 4, 5], ), [1, 6], Element{false, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(allocate_fiber(SparseCoo{1}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int64}, Int64}((4,), (Int64[2, 4], ), [1, 3], Element{false, Bool}([1, 1])))
    res = dropdefaults!(allocate_fiber(SparseCoo{1}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseCoo{1, Tuple{Int64}, Int64}((5,), (Int64[], ), [1, 1, 1, 1, 1, 1], Element{false, Bool}([]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseCoo{1, Tuple{Int64}, Int64}((5,), (Int64[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseCoo{1, Tuple{Int64}, Int64}((4,), (Int64[2, 4, 1, 2, 3, 4, 2, 4], ), [1, 3, 3, 7, 9], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 1], [], SparseCoo{1, Tuple{Int64}, Int64}((5,), (Int64[], ), [1], Element{false, Bool}([]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseCoo{1, Tuple{Int64}, Int64}((5,), (Int64[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64, Int64}(4, [1, 4], [1, 3, 4], SparseCoo{1, Tuple{Int64}, Int64}((4,), (Int64[2, 4, 1, 2, 3, 4, 2, 4], ), [1, 3, 7, 9], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseCoo{1}(Element(false)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseCoo{2, Tuple{Int64, Int64}, Int64}((5, 5), (Int64[], Int64[], ), [1, 1], Element{false, Bool}([])))
    res = dropdefaults!(allocate_fiber(SparseCoo{2}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseCoo{2, Tuple{Int64, Int64}, Int64}((5, 5), (Int64[1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5], Int64[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 26], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])))
    res = dropdefaults!(allocate_fiber(SparseCoo{2}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseCoo{2, Tuple{Int64, Int64}, Int64}((4, 4), (Int64[1, 1, 3, 3, 3, 3, 4, 4], Int64[2, 4, 1, 2, 3, 4, 2, 4], ), [1, 9], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1])))
    res = dropdefaults!(allocate_fiber(SparseCoo{2}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseHash{2, Tuple{Int64, Int64}, Int64}((5, 5), Dict{Tuple{Int64, Tuple{Int64, Int64}}, Int64}(), [1, 1], [], Element{false, Bool}([])))
    res = dropdefaults!(allocate_fiber(SparseHash{2}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseHash{2, Tuple{Int64, Int64}, Int64}((5, 5), Dict{Tuple{Int64, Tuple{Int64, Int64}}, Int64}((1, (1, 1)) => 1, (1, (1, 2)) => 2, (1, (1, 3)) => 3, (1, (1, 4)) => 4, (1, (1, 5)) => 5, (1, (2, 1)) => 6, (1, (2, 2)) => 7, (1, (2, 3)) => 8, (1, (2, 4)) => 9, (1, (2, 5)) => 10, (1, (3, 1)) => 11, (1, (3, 2)) => 12, (1, (3, 3)) => 13, (1, (3, 4)) => 14, (1, (3, 5)) => 15, (1, (4, 1)) => 16, (1, (4, 2)) => 17, (1, (4, 3)) => 18, (1, (4, 4)) => 19, (1, (4, 5)) => 20, (1, (5, 1)) => 21, (1, (5, 2)) => 22, (1, (5, 3)) => 23, (1, (5, 4)) => 24, (1, (5, 5)) => 25), [1, 26], [(1, (1, 1)) => 1, (1, (1, 2)) => 2, (1, (1, 3)) => 3, (1, (1, 4)) => 4, (1, (1, 5)) => 5, (1, (2, 1)) => 6, (1, (2, 2)) => 7, (1, (2, 3)) => 8, (1, (2, 4)) => 9, (1, (2, 5)) => 10, (1, (3, 1)) => 11, (1, (3, 2)) => 12, (1, (3, 3)) => 13, (1, (3, 4)) => 14, (1, (3, 5)) => 15, (1, (4, 1)) => 16, (1, (4, 2)) => 17, (1, (4, 3)) => 18, (1, (4, 4)) => 19, (1, (4, 5)) => 20, (1, (5, 1)) => 21, (1, (5, 2)) => 22, (1, (5, 3)) => 23, (1, (5, 4)) => 24, (1, (5, 5)) => 25], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])))
    res = dropdefaults!(allocate_fiber(SparseHash{2}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseHash{2, Tuple{Int64, Int64}, Int64}((4, 4), Dict{Tuple{Int64, Tuple{Int64, Int64}}, Int64}((1, (1, 2)) => 1, (1, (1, 4)) => 2, (1, (3, 1)) => 3, (1, (3, 2)) => 4, (1, (3, 3)) => 5, (1, (3, 4)) => 6, (1, (4, 2)) => 7, (1, (4, 4)) => 8), [1, 9], [(1, (1, 2)) => 1, (1, (1, 4)) => 2, (1, (3, 1)) => 3, (1, (3, 2)) => 4, (1, (3, 3)) => 5, (1, (3, 4)) => 6, (1, (4, 2)) => 7, (1, (4, 4)) => 8], Element{false, Bool}([1, 1, 1, 1, 1, 1, 1, 1])))
    res = dropdefaults!(allocate_fiber(SparseHash{2}(Element(false))), arr)
    @test isstructequal(res, ref)
    arr = fill(false)
    ref = Fiber(Element{true, Bool}([0]))
    res = dropdefaults!(allocate_fiber(Element(true)), arr)
    @test isstructequal(res, ref)
    arr = fill(true)
    ref = Fiber(Element{true, Bool}([1]))
    res = dropdefaults!(allocate_fiber(Element(true)), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(Dense{Int64}(5, Element{true, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(allocate_fiber(Dense(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(Dense{Int64}(5, Element{true, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(allocate_fiber(Dense(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(Dense{Int64}(4, Element{true, Bool}([0, 1, 0, 1])))
    res = dropdefaults!(allocate_fiber(Dense(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, Dense{Int64}(5, Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(Dense(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, Dense{Int64}(5, Element{true, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, Dense{Int64}(4, Element{true, Bool}([0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 6], [1, 2, 3, 4, 5], Dense{Int64}(5, Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(SparseList(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 1], [], Dense{Int64}(5, Element{true, Bool}([]))))
    res = dropdefaults!(allocate_fiber(SparseList(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64, Int64}(4, [1, 4], [1, 2, 4], Dense{Int64}(4, Element{true, Bool}([0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1]))))
    res = dropdefaults!(allocate_fiber(SparseList(Dense(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 6], [1, 2, 3, 4, 5], Element{true, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(allocate_fiber(SparseList(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 1], [], Element{true, Bool}([])))
    res = dropdefaults!(allocate_fiber(SparseList(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseList{Int64, Int64}(4, [1, 3], [1, 3], Element{true, Bool}([0, 0])))
    res = dropdefaults!(allocate_fiber(SparseList(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseList{Int64, Int64}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseList{Int64, Int64}(5, [1, 1, 1, 1, 1, 1], [], Element{true, Bool}([]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseList{Int64, Int64}(4, [1, 3, 7, 7, 9], [1, 3, 1, 2, 3, 4, 1, 3], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseList{Int64, Int64}(5, [1, 6, 11, 16, 21, 26], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 1], [], SparseList{Int64, Int64}(5, [1], [], Element{true, Bool}([]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64, Int64}(4, [1, 4], [1, 2, 4], SparseList{Int64, Int64}(4, [1, 3, 7, 9], [1, 3, 1, 2, 3, 4, 1, 3], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseList(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseVBL{Int64, Int64}(5, [1, 2], [5], [1, 6], Element{true, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(allocate_fiber(SparseVBL(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseVBL{Int64, Int64}(5, [1, 1], [], [1], Element{true, Bool}([])))
    res = dropdefaults!(allocate_fiber(SparseVBL(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseVBL{Int64, Int64}(4, [1, 3], [1, 3], [1, 2, 3], Element{true, Bool}([0, 0])))
    res = dropdefaults!(allocate_fiber(SparseVBL(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseVBL{Int64, Int64}(5, [1, 2, 3, 4, 5, 6], [5, 5, 5, 5, 5], [1, 6, 11, 16, 21, 26], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseVBL(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseVBL{Int64, Int64}(5, [1, 1, 1, 1, 1, 1], [], [1], Element{true, Bool}([]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseVBL(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseVBL{Int64, Int64}(4, [1, 3, 4, 4, 6], [1, 3, 4, 1, 3], [1, 2, 3, 7, 8, 9], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseVBL(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseVBL{Int64, Int64}(5, [1, 2, 3, 4, 5, 6], [5, 5, 5, 5, 5], [1, 6, 11, 16, 21, 26], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseVBL(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 1], [], SparseVBL{Int64, Int64}(5, [1], [], [1], Element{true, Bool}([]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseVBL(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64, Int64}(4, [1, 4], [1, 2, 4], SparseVBL{Int64, Int64}(4, [1, 3, 4, 6], [1, 3, 4, 1, 3], [1, 2, 3, 7, 8, 9], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseVBL(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseBytemap{Int64, Int64}(5, [1, 6], [1, 1, 1, 1, 1], [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5)], Element{true, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(allocate_fiber(SparseBytemap(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseBytemap{Int64, Int64}(5, [1, 0], [0, 0, 0, 0, 0], [], Element{true, Bool}([1, 1, 1, 1, 1])))
    res = dropdefaults!(allocate_fiber(SparseBytemap(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseBytemap{Int64, Int64}(4, [1, 3], [1, 0, 1, 0], [(1, 1), (1, 3)], Element{true, Bool}([0, 1, 0, 1])))
    res = dropdefaults!(allocate_fiber(SparseBytemap(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseBytemap{Int64, Int64}(5, [1, 6, 11, 16, 21, 26], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5)], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseBytemap(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseBytemap{Int64, Int64}(5, [1, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [], Element{true, Bool}([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseBytemap(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseBytemap{Int64, Int64}(4, [1, 3, 7, 7, 9], [1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 1, 0], [(1, 1), (1, 3), (2, 1), (2, 2), (2, 3), (2, 4), (4, 1), (4, 3)], Element{true, Bool}([0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseBytemap(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseBytemap{Int64, Int64}(5, [1, 6, 11, 16, 21, 26], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5)], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseBytemap(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 1], [], SparseBytemap{Int64, Int64}(5, [1], [], [], Element{true, Bool}([]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseBytemap(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64, Int64}(4, [1, 4], [1, 2, 4], SparseBytemap{Int64, Int64}(4, [1, 3, 7, 9], [1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0], [(1, 1), (1, 3), (2, 1), (2, 2), (2, 3), (2, 4), (3, 1), (3, 3)], Element{true, Bool}([0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseBytemap(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseHash{1, Tuple{Int64}, Int64}((5,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}((1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5), [1, 6], [(1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5], Element{true, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(allocate_fiber(SparseHash{1}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseHash{1, Tuple{Int64}, Int64}((5,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}(), [1, 1], [], Element{true, Bool}([])))
    res = dropdefaults!(allocate_fiber(SparseHash{1}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseHash{1, Tuple{Int64}, Int64}((4,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}((1, (1,)) => 1, (1, (3,)) => 2), [1, 3], [(1, (1,)) => 1, (1, (3,)) => 2], Element{true, Bool}([0, 0])))
    res = dropdefaults!(allocate_fiber(SparseHash{1}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseHash{1, Tuple{Int64}, Int64}((5,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}((1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25), [1, 6, 11, 16, 21, 26], [(1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseHash{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseHash{1, Tuple{Int64}, Int64}((5,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}(), [1, 1, 1, 1, 1, 1], [], Element{true, Bool}([]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseHash{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseHash{1, Tuple{Int64}, Int64}((4,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}((1, (1,)) => 1, (1, (3,)) => 2, (2, (1,)) => 3, (2, (2,)) => 4, (2, (3,)) => 5, (2, (4,)) => 6, (4, (1,)) => 7, (4, (3,)) => 8), [1, 3, 7, 7, 9], [(1, (1,)) => 1, (1, (3,)) => 2, (2, (1,)) => 3, (2, (2,)) => 4, (2, (3,)) => 5, (2, (4,)) => 6, (4, (1,)) => 7, (4, (3,)) => 8], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseHash{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseHash{1, Tuple{Int64}, Int64}((5,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}((1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25), [1, 6, 11, 16, 21, 26], [(1, (1,)) => 1, (1, (2,)) => 2, (1, (3,)) => 3, (1, (4,)) => 4, (1, (5,)) => 5, (2, (1,)) => 6, (2, (2,)) => 7, (2, (3,)) => 8, (2, (4,)) => 9, (2, (5,)) => 10, (3, (1,)) => 11, (3, (2,)) => 12, (3, (3,)) => 13, (3, (4,)) => 14, (3, (5,)) => 15, (4, (1,)) => 16, (4, (2,)) => 17, (4, (3,)) => 18, (4, (4,)) => 19, (4, (5,)) => 20, (5, (1,)) => 21, (5, (2,)) => 22, (5, (3,)) => 23, (5, (4,)) => 24, (5, (5,)) => 25], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseHash{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 1], [], SparseHash{1, Tuple{Int64}, Int64}((5,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}(), [1], [], Element{true, Bool}([]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseHash{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64, Int64}(4, [1, 4], [1, 2, 4], SparseHash{1, Tuple{Int64}, Int64}((4,), Dict{Tuple{Int64, Tuple{Int64}}, Int64}((1, (1,)) => 1, (1, (3,)) => 2, (2, (1,)) => 3, (2, (2,)) => 4, (2, (3,)) => 5, (2, (4,)) => 6, (3, (1,)) => 7, (3, (3,)) => 8), [1, 3, 7, 9], [(1, (1,)) => 1, (1, (3,)) => 2, (2, (1,)) => 3, (2, (2,)) => 4, (2, (3,)) => 5, (2, (4,)) => 6, (3, (1,)) => 7, (3, (3,)) => 8], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseHash{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 0, 0, 0, 0]
    ref = Fiber(SparseCoo{1, Tuple{Int64}, Int64}((5,), (Int64[1, 2, 3, 4, 5], ), [1, 6], Element{true, Bool}([0, 0, 0, 0, 0])))
    res = dropdefaults!(allocate_fiber(SparseCoo{1}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1, 1, 1, 1, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int64}, Int64}((5,), (Int64[], ), [1, 1], Element{true, Bool}([])))
    res = dropdefaults!(allocate_fiber(SparseCoo{1}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0, 1, 0, 1]
    ref = Fiber(SparseCoo{1, Tuple{Int64}, Int64}((4,), (Int64[1, 3], ), [1, 3], Element{true, Bool}([0, 0])))
    res = dropdefaults!(allocate_fiber(SparseCoo{1}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(Dense{Int64}(5, SparseCoo{1, Tuple{Int64}, Int64}((5,), (Int64[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(Dense{Int64}(5, SparseCoo{1, Tuple{Int64}, Int64}((5,), (Int64[], ), [1, 1, 1, 1, 1, 1], Element{true, Bool}([]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(Dense{Int64}(4, SparseCoo{1, Tuple{Int64}, Int64}((4,), (Int64[1, 3, 1, 2, 3, 4, 1, 3], ), [1, 3, 7, 7, 9], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(Dense(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 6], [1, 2, 3, 4, 5], SparseCoo{1, Tuple{Int64}, Int64}((5,), (Int64[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 6, 11, 16, 21, 26], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseList{Int64, Int64}(5, [1, 1], [], SparseCoo{1, Tuple{Int64}, Int64}((5,), (Int64[], ), [1], Element{true, Bool}([]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseList{Int64, Int64}(4, [1, 4], [1, 2, 4], SparseCoo{1, Tuple{Int64}, Int64}((4,), (Int64[1, 3, 1, 2, 3, 4, 1, 3], ), [1, 3, 7, 9], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0]))))
    res = dropdefaults!(allocate_fiber(SparseList(SparseCoo{1}(Element(true)))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseCoo{2, Tuple{Int64, Int64}, Int64}((5, 5), (Int64[1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5], Int64[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], ), [1, 26], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])))
    res = dropdefaults!(allocate_fiber(SparseCoo{2}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseCoo{2, Tuple{Int64, Int64}, Int64}((5, 5), (Int64[], Int64[], ), [1, 1], Element{true, Bool}([])))
    res = dropdefaults!(allocate_fiber(SparseCoo{2}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseCoo{2, Tuple{Int64, Int64}, Int64}((4, 4), (Int64[1, 1, 2, 2, 2, 2, 4, 4], Int64[1, 3, 1, 2, 3, 4, 1, 3], ), [1, 9], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0])))
    res = dropdefaults!(allocate_fiber(SparseCoo{2}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0]
    ref = Fiber(SparseHash{2, Tuple{Int64, Int64}, Int64}((5, 5), Dict{Tuple{Int64, Tuple{Int64, Int64}}, Int64}((1, (1, 1)) => 1, (1, (1, 2)) => 2, (1, (1, 3)) => 3, (1, (1, 4)) => 4, (1, (1, 5)) => 5, (1, (2, 1)) => 6, (1, (2, 2)) => 7, (1, (2, 3)) => 8, (1, (2, 4)) => 9, (1, (2, 5)) => 10, (1, (3, 1)) => 11, (1, (3, 2)) => 12, (1, (3, 3)) => 13, (1, (3, 4)) => 14, (1, (3, 5)) => 15, (1, (4, 1)) => 16, (1, (4, 2)) => 17, (1, (4, 3)) => 18, (1, (4, 4)) => 19, (1, (4, 5)) => 20, (1, (5, 1)) => 21, (1, (5, 2)) => 22, (1, (5, 3)) => 23, (1, (5, 4)) => 24, (1, (5, 5)) => 25), [1, 26], [(1, (1, 1)) => 1, (1, (1, 2)) => 2, (1, (1, 3)) => 3, (1, (1, 4)) => 4, (1, (1, 5)) => 5, (1, (2, 1)) => 6, (1, (2, 2)) => 7, (1, (2, 3)) => 8, (1, (2, 4)) => 9, (1, (2, 5)) => 10, (1, (3, 1)) => 11, (1, (3, 2)) => 12, (1, (3, 3)) => 13, (1, (3, 4)) => 14, (1, (3, 5)) => 15, (1, (4, 1)) => 16, (1, (4, 2)) => 17, (1, (4, 3)) => 18, (1, (4, 4)) => 19, (1, (4, 5)) => 20, (1, (5, 1)) => 21, (1, (5, 2)) => 22, (1, (5, 3)) => 23, (1, (5, 4)) => 24, (1, (5, 5)) => 25], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])))
    res = dropdefaults!(allocate_fiber(SparseHash{2}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1]
    ref = Fiber(SparseHash{2, Tuple{Int64, Int64}, Int64}((5, 5), Dict{Tuple{Int64, Tuple{Int64, Int64}}, Int64}(), [1, 1], [], Element{true, Bool}([])))
    res = dropdefaults!(allocate_fiber(SparseHash{2}(Element(true))), arr)
    @test isstructequal(res, ref)
    arr = Bool[0 1 0 1; 0 0 0 0; 1 1 1 1; 0 1 0 1]
    ref = Fiber(SparseHash{2, Tuple{Int64, Int64}, Int64}((4, 4), Dict{Tuple{Int64, Tuple{Int64, Int64}}, Int64}((1, (1, 1)) => 1, (1, (1, 3)) => 2, (1, (2, 1)) => 3, (1, (2, 2)) => 4, (1, (2, 3)) => 5, (1, (2, 4)) => 6, (1, (4, 1)) => 7, (1, (4, 3)) => 8), [1, 9], [(1, (1, 1)) => 1, (1, (1, 3)) => 2, (1, (2, 1)) => 3, (1, (2, 2)) => 4, (1, (2, 3)) => 5, (1, (2, 4)) => 6, (1, (4, 1)) => 7, (1, (4, 3)) => 8], Element{true, Bool}([0, 0, 0, 0, 0, 0, 0, 0])))
    res = dropdefaults!(allocate_fiber(SparseHash{2}(Element(true))), arr)
    @test isstructequal(res, ref)
end
