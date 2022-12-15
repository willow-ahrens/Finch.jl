@testset "constructors" begin
    @testset "Finch.DenseLevel constructors" begin
        ref = Fiber(Dense{Int}(0, Element{0.0}(Float64[])))
        res = Fiber(Finch.DenseLevel(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel{Int8} constructors" begin
        ref = Fiber(Dense{Int8}(0, Element{0.0}(Float64[])))
        res = Fiber(Finch.DenseLevel{Int8}(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int8}(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel constructors" begin
        ref = Fiber(SparseList{Int}(0, [1, 1], Int[], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseListLevel(0, [1, 1], Int[], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(0, [1, 1], Int[], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int8} constructors" begin
        ref = Fiber(SparseList{Int8}(0, Int8[1, 1], Int8[], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseListLevel{Int8}(0, Int8[1, 1], Int8[], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int8}(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int8}(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseVBLLevel constructors" begin
        ref = Fiber(SparseVBL{Int}(0, [1, 1], Int[], [1], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseVBLLevel(0, [1, 1], Int[], [1], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int}(0, [1, 1], Int[], [1], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int}(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int}(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseVBLLevel{Int8} constructors" begin
        ref = Fiber(SparseVBL{Int8}(0, Int8[1, 1], Int8[], Int8[1], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseVBLLevel{Int8}(0, Int8[1, 1], Int8[], Int8[1], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int8}(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int8}(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel constructors" begin
        ref = Fiber(Dense{Int}(4, Element{0.0}([0.0, 0.0, 0.0, 0.0])))
        res = Fiber(Finch.DenseLevel(4, Element{0.0}([0.0, 0.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(4, Element{0.0}([0.0, 0.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel{Int8} constructors" begin
        ref = Fiber(Dense{Int8}(4, Element{0.0}([0.0, 0.0, 0.0, 0.0])))
        res = Fiber(Finch.DenseLevel{Int8}(4, Element{0.0}([0.0, 0.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel constructors" begin
        ref = Fiber(SparseList{Int}(4, [1, 1], Int[], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseListLevel(4, [1, 1], Int[], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel(4, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(4, [1, 1], Int[], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(4, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int8} constructors" begin
        ref = Fiber(SparseList{Int8}(4, Int8[1, 1], Int8[], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseListLevel{Int8}(4, Int8[1, 1], Int8[], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int8}(4, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseVBLLevel constructors" begin
        ref = Fiber(SparseVBL{Int}(4, [1, 1], Int[], [1], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseVBLLevel(4, [1, 1], Int[], [1], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel(4, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int}(4, [1, 1], Int[], [1], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int}(4, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseVBLLevel{Int8} constructors" begin
        ref = Fiber(SparseVBL{Int8}(4, Int8[1, 1], Int8[], Int8[1], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseVBLLevel{Int8}(4, Int8[1, 1], Int8[], Int8[1], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int8}(4, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel constructors" begin
        ref = Fiber(Dense{Int}(6, Element{0.0}([0.0, 1.0, 0.0, 1.0, 0.0, 0.0])))
        res = Fiber(Finch.DenseLevel(6, Element{0.0}([0.0, 1.0, 0.0, 1.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(6, Element{0.0}([0.0, 1.0, 0.0, 1.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel{Int8} constructors" begin
        ref = Fiber(Dense{Int8}(6, Element{0.0}([0.0, 1.0, 0.0, 1.0, 0.0, 0.0])))
        res = Fiber(Finch.DenseLevel{Int8}(6, Element{0.0}([0.0, 1.0, 0.0, 1.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel constructors" begin
        ref = Fiber(SparseList{Int}(6, [1, 3], [2, 4], Element{0.0}([1.0, 1.0])))
        res = Fiber(Finch.SparseListLevel(6, [1, 3], [2, 4], Element{0.0}([1.0, 1.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(6, [1, 3], [2, 4], Element{0.0}([1.0, 1.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int8} constructors" begin
        ref = Fiber(SparseList{Int8}(6, Int8[1, 3], Int8[2, 4], Element{0.0}([1.0, 1.0])))
        res = Fiber(Finch.SparseListLevel{Int8}(6, Int8[1, 3], Int8[2, 4], Element{0.0}([1.0, 1.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseVBLLevel constructors" begin
        ref = Fiber(SparseVBL{Int}(6, [1, 3], [2, 4], [1, 2, 3], Element{0.0}([1.0, 1.0])))
        res = Fiber(Finch.SparseVBLLevel(6, [1, 3], [2, 4], [1, 2, 3], Element{0.0}([1.0, 1.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int}(6, [1, 3], [2, 4], [1, 2, 3], Element{0.0}([1.0, 1.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseVBLLevel{Int8} constructors" begin
        ref = Fiber(SparseVBL{Int8}(6, Int8[1, 3], Int8[2, 4], Int8[1, 2, 3], Element{0.0}([1.0, 1.0])))
        res = Fiber(Finch.SparseVBLLevel{Int8}(6, Int8[1, 3], Int8[2, 4], Int8[1, 2, 3], Element{0.0}([1.0, 1.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel constructors" begin
        ref = Fiber(Dense{Int}(0, Element{0.0}(Float64[])))
        res = Fiber(Finch.DenseLevel(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel{Int8} constructors" begin
        ref = Fiber(Dense{Int8}(0, Element{0.0}(Float64[])))
        res = Fiber(Finch.DenseLevel{Int8}(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int8}(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel constructors" begin
        ref = Fiber(SparseList{Int}(0, [1, 1], Int[], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseListLevel(0, [1, 1], Int[], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(0, [1, 1], Int[], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int8} constructors" begin
        ref = Fiber(SparseList{Int8}(0, Int8[1, 1], Int8[], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseListLevel{Int8}(0, Int8[1, 1], Int8[], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int8}(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int8}(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseVBLLevel constructors" begin
        ref = Fiber(SparseVBL{Int}(0, [1, 1], Int[], [1], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseVBLLevel(0, [1, 1], Int[], [1], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int}(0, [1, 1], Int[], [1], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int}(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int}(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseVBLLevel{Int8} constructors" begin
        ref = Fiber(SparseVBL{Int8}(0, Int8[1, 1], Int8[], Int8[1], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseVBLLevel{Int8}(0, Int8[1, 1], Int8[], Int8[1], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int8}(0, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int8}(Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel constructors" begin
        ref = Fiber(Dense{Int}(4, Element{0.0}([0.0, 0.0, 0.0, 0.0])))
        res = Fiber(Finch.DenseLevel(4, Element{0.0}([0.0, 0.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(4, Element{0.0}([0.0, 0.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel{Int8} constructors" begin
        ref = Fiber(Dense{Int8}(4, Element{0.0}([0.0, 0.0, 0.0, 0.0])))
        res = Fiber(Finch.DenseLevel{Int8}(4, Element{0.0}([0.0, 0.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel constructors" begin
        ref = Fiber(SparseList{Int}(4, [1, 1], Int[], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseListLevel(4, [1, 1], Int[], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel(4, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(4, [1, 1], Int[], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(4, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int8} constructors" begin
        ref = Fiber(SparseList{Int8}(4, Int8[1, 1], Int8[], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseListLevel{Int8}(4, Int8[1, 1], Int8[], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int8}(4, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseVBLLevel constructors" begin
        ref = Fiber(SparseVBL{Int}(4, [1, 1], Int[], [1], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseVBLLevel(4, [1, 1], Int[], [1], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel(4, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int}(4, [1, 1], Int[], [1], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int}(4, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseVBLLevel{Int8} constructors" begin
        ref = Fiber(SparseVBL{Int8}(4, Int8[1, 1], Int8[], Int8[1], Element{0.0}(Float64[])))
        res = Fiber(Finch.SparseVBLLevel{Int8}(4, Int8[1, 1], Int8[], Int8[1], Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int8}(4, Element{0.0}(Float64[])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel constructors" begin
        ref = Fiber(Dense{Int}(6, Element{0.0}([0.0, 0.2, 0.0, 0.0, 0.3, 0.4])))
        res = Fiber(Finch.DenseLevel(6, Element{0.0}([0.0, 0.2, 0.0, 0.0, 0.3, 0.4])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(6, Element{0.0}([0.0, 0.2, 0.0, 0.0, 0.3, 0.4])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel{Int8} constructors" begin
        ref = Fiber(Dense{Int8}(6, Element{0.0}([0.0, 0.2, 0.0, 0.0, 0.3, 0.4])))
        res = Fiber(Finch.DenseLevel{Int8}(6, Element{0.0}([0.0, 0.2, 0.0, 0.0, 0.3, 0.4])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel constructors" begin
        ref = Fiber(SparseList{Int}(6, [1, 4], [2, 5, 6], Element{0.0}([0.2, 0.3, 0.4])))
        res = Fiber(Finch.SparseListLevel(6, [1, 4], [2, 5, 6], Element{0.0}([0.2, 0.3, 0.4])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(6, [1, 4], [2, 5, 6], Element{0.0}([0.2, 0.3, 0.4])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int8} constructors" begin
        ref = Fiber(SparseList{Int8}(6, Int8[1, 4], Int8[2, 5, 6], Element{0.0}([0.2, 0.3, 0.4])))
        res = Fiber(Finch.SparseListLevel{Int8}(6, Int8[1, 4], Int8[2, 5, 6], Element{0.0}([0.2, 0.3, 0.4])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseVBLLevel constructors" begin
        ref = Fiber(SparseVBL{Int}(6, [1, 3], [2, 6, 4396003504], [1, 2, 4], Element{0.0}([0.2, 0.3, 0.4])))
        res = Fiber(Finch.SparseVBLLevel(6, [1, 3], [2, 6, 4396003504], [1, 2, 4], Element{0.0}([0.2, 0.3, 0.4])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseVBLLevel{Int}(6, [1, 3], [2, 6, 4396003504], [1, 2, 4], Element{0.0}([0.2, 0.3, 0.4])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseVBLLevel{Int8} constructors" begin
        ref = Fiber(SparseVBL{Int8}(6, Int8[1, 3], Int8[2, 6, -66], Int8[1, 2, 4], Element{0.0}([0.2, 0.3, 0.4])))
        res = Fiber(Finch.SparseVBLLevel{Int8}(6, Int8[1, 3], Int8[2, 6, -66], Int8[1, 2, 4], Element{0.0}([0.2, 0.3, 0.4])))
        @test isstructequal(res, ref)
    end
end
