@testset "meta" begin
    A = Fiber(
        SparseList{Int64, Int64}(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Fiber(
        SparseList{Int64, Int64}(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    @test A == B

    A = Fiber(
        Dense{Int64}(2,
        SparseList{Int64, Int64}(4, [1, 1, 3], [1, 4],
        Element{0.0}([1.0, 1.0]))))
    B = Fiber(
        Dense{Int64}(2,
        Dense{Int64}(4,
        Element{0.0}([0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0]))))
    @test A == B

    A = [0.0 0.0 0.0 0.0; 1.0 0.0 0.0 1.0]
    B = Fiber(
        Dense{Int64}(2,
        SparseList{Int64, Int64}(4, [1, 1, 3], [1, 4],
        Element{0.0}([1.0, 1.0]))))
    @test A == B

    A = Fiber(
        Dense{Int64}(2,
        Dense{Int64}(2,
        Element{0.0}([0, 0, 0, 0]))))
    B = [0 0; 0 0]
    @test A == B



    A = Fiber(
        Dense{Int64}(4,
        Element{0.0}([0, 0, 0, 0])))
    B = Fiber(
        Dense{Int64}(5,
        Element{0.0}([0, 0, 0, 0, 0])))
    @test size(A) != size(B) && A != B
        
    A = [0.0 0.0 0.0 0.0 1.0 0.0 0.0 1.0];
    B = Fiber(
        Dense{Int64}(2,
        SparseList{Int64, Int64}(4, [1, 1, 3], [1, 4],
        Element{0.0}([1.0, 1.0]))))
    @test size(A) != size(B) && A != B

    A = Fiber(
        Dense{Int64}(3,
        SparseList{Int64, Int64}(4, [1, 2, 4, 7], [1, 1, 2, 1, 2, 3],
        Element{0.0}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0]))))
    B = [0 0 0 0; 1 1 0 0; 1 1 1 0]
    @test size(A) == size(B) && A != B

    C = Fiber(
        Dense{Int64}(3,
        Dense{Int64}(4, 
        Element{0.0}([0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0]))))
    @test size(A) == size(B) && A != B
    @test B == C
    
    A = [NaN, 0.0, 3.14, 0.0]
    B = copyto!(@fiber(sl(e(0.0))), [NaN, 0.0, 3.14, 0.0])
    C = copyto!(@fiber(sl(e(0.0))), [NaN, 0.0, 3.14, 0.0])
    D = [1.0, 2.0, 4.0, 8.0]
    @test isequal(A, B)
    @test isequal(A, C)
    @test isequal(B, C)
    @test isequal(B, A)
    @test !isequal(A, D)
    @test A != B

    @test Finch.data_rep(@fiber(d(d(sl(e(0.0)))))) ==
        Finch.SolidData(Finch.DenseData(Finch.DenseData(Finch.SparseData(Finch.ElementData(0.0, Float64)))))

    @test Finch.getindex_rep(Finch.data_rep(@fiber(d(d(sl(e(0.0)))))), Int, Int, Int) ==
        Finch.HollowData(Finch.ElementData(0.0, Float64))

    @test Finch.fiber_ctr(Finch.getindex_rep(Finch.data_rep(@fiber(d(d(sl(e(0.0)))))), Int, Int, Int)) ==
        :(Fiber!(Element{$Float64, $0.0}()))

    @test Finch.fiber_ctr(Finch.getindex_rep(Finch.data_rep(@fiber(d(d(sl(e(0.0)))))), Int, Int, typeof(Base.Slice(1:10)))) ==
        :(Fiber!(SparseList(Element{$Float64, $0.0}())))

    @test Finch.fiber_ctr(Finch.getindex_rep(Finch.data_rep(@fiber(d(d(sl(e(0.0)))))), Int, typeof(1:2), typeof(Base.Slice(1:10)))) ==
        :(Fiber!(Dense(SparseList(Element{$Float64, $0.0}()))))
end