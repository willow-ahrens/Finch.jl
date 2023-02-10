@testset "meta" begin
    A = @fiber(sl(e(0.0)), fsparse(([1, 3, 5, 7, 9],), [2.0, 3.0, 4.0, 5.0, 6.0], (10,)))
    B = @fiber(sl(e(0.0)), A)
    @test A == B

    A = [0.0 0.0 0.0 0.0; 1.0 0.0 0.0 1.0]
    B = @fiber(d(sl(e(0.0))), A)
    C = @fiber(d(d(e(0.0))), A)
    @test A == B

    A = [0 0; 0 0]
    B = @fiber(d(d(e(0.0))), A)
    @test A == B

    A = @fiber(d(e(0.0)), [0, 0, 0, 0])
    B = @fiber(d(e(0.0)), [0, 0, 0, 0, 0])
    @test size(A) != size(B) && A != B
        
    A = [0 0 0 0 1 0 0 1]
    B = @fiber(d(sl(e(0))), [0 0 0 0; 1 0 0 1])
    @test size(A) != size(B) && A != B

    A = @fiber(d(sl(e(0.0))), [1 0 0 0; 1 1 0 0; 1 1 1 0])
    B = [0 0 0 0; 1 1 0 0; 1 1 1 0]
    @test size(A) == size(B) && A != B
    C = @fiber(d(sl(e(0.0))), [0 0 0 0; 1 1 0 0; 1 1 1 0])
    @test B == C
    
    A = [NaN, 0.0, 3.14, 0.0]
    B = @fiber(sl(e(0.0)), [NaN, 0.0, 3.14, 0.0])
    C = @fiber(sl(e(0.0)), [NaN, 0.0, 3.14, 0.0])
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