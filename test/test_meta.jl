@testset "meta" begin
    A = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        SparseList{Int64, Int64}(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    @test A == B

    A = Finch.Fiber(
        Dense{Int64}(2,
        SparseList{Int64, Int64}(4, [1, 1, 3], [1, 4],
        Element{0.0}([1.0, 1.0]))))
    B = Finch.Fiber(
        Dense{Int64}(2,
        Dense{Int64}(4,
        Element{0.0}([0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0]))))
    @test A == B

    A = [0.0 0.0 0.0 0.0; 1.0 0.0 0.0 1.0]
    B = Finch.Fiber(
        Dense{Int64}(2,
        SparseList{Int64, Int64}(4, [1, 1, 3], [1, 4],
        Element{0.0}([1.0, 1.0]))))
    @test A == B

    A = Finch.Fiber(
        Dense{Int64}(2,
        Dense{Int64}(2,
        Element{0.0}([0, 0, 0, 0]))))
    B = [0 0; 0 0]
    @test A == B



    A = Finch.Fiber(
        Dense{Int64}(4,
        Element{0.0}([0, 0, 0, 0])))
    B = Finch.Fiber(
        Dense{Int64}(5,
        Element{0.0}([0, 0, 0, 0, 0])))
    @test size(A) != size(B) && A != B
        
    A = [0.0 0.0 0.0 0.0 1.0 0.0 0.0 1.0];
    B = Finch.Fiber(
        Dense{Int64}(2,
        SparseList{Int64, Int64}(4, [1, 1, 3], [1, 4],
        Element{0.0}([1.0, 1.0]))))
    @test size(A) != size(B) && A != B

    A = Finch.Fiber(
        Dense{Int64}(3,
        SparseList{Int64, Int64}(4, [1, 2, 4, 7], [1, 1, 2, 1, 2, 3],
        Element{0.0}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0]))))
    B = [0 0 0 0; 1 1 0 0; 1 1 1 0]
    @test size(A) == size(B) && A != B

    C = Finch.Fiber(
        Dense{Int64}(3,
        Dense{Int64}(4, 
        Element{0.0}([0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0]))))
    @test size(A) == size(B) && A != B
    @test B == C

end