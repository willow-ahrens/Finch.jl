@testset "formats" begin
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
end
