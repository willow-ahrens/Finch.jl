@testset "constructors" begin
    @testset "Finch.DenseLevel constructors" begin
        ref = Fiber(Dense{Int}(0, Element{0.0, Float64}([])))
        res = Fiber(Finch.DenseLevel(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel{Int16} constructors" begin
        ref = Fiber(Dense{Int16}(0, Element{0.0, Float64}([])))
        res = Fiber(Finch.DenseLevel{Int16}(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int16}(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel constructors" begin
        ref = Fiber(SparseList{Int, Int}(0, [1, 1], [], Element{0.0, Float64}([])))
        res = Fiber(Finch.SparseListLevel(0, [1, 1], Int[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(0, [1, 1], Int[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int, Int}(0, [1, 1], Int[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int, Int}(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int, Int}(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int16} constructors" begin
        ref = Fiber(SparseList{Int16, Int}(0, [1, 1], [], Element{0.0, Float64}([])))
        res = Fiber(Finch.SparseListLevel{Int16}(0, [1, 1], Int16[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16}(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16}(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int}(0, [1, 1], Int16[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int}(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int}(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int16, Int16} constructors" begin
        ref = Fiber(SparseList{Int16, Int16}(0, [1, 1], [], Element{0.0, Float64}([])))
        res = Fiber(Finch.SparseListLevel{Int16, Int16}(0, Int16[1, 1], Int16[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int16}(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int16}(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel constructors" begin
        ref = Fiber(Dense{Int}(4, Element{0.0, Float64}([0.0, 0.0, 0.0, 0.0])))
        res = Fiber(Finch.DenseLevel(4, Element{0.0, Float64}([0.0, 0.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(4, Element{0.0, Float64}([0.0, 0.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel{Int16} constructors" begin
        ref = Fiber(Dense{Int16}(4, Element{0.0, Float64}([0.0, 0.0, 0.0, 0.0])))
        res = Fiber(Finch.DenseLevel{Int16}(4, Element{0.0, Float64}([0.0, 0.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel constructors" begin
        ref = Fiber(SparseList{Int, Int}(4, [1, 1], [], Element{0.0, Float64}([])))
        res = Fiber(Finch.SparseListLevel(4, [1, 1], Int[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel(4, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(4, [1, 1], Int[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(4, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int, Int}(4, [1, 1], Int[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int, Int}(4, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int16} constructors" begin
        ref = Fiber(SparseList{Int16, Int}(4, [1, 1], [], Element{0.0, Float64}([])))
        res = Fiber(Finch.SparseListLevel{Int16}(4, [1, 1], Int16[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16}(4, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int}(4, [1, 1], Int16[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int}(4, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int16, Int16} constructors" begin
        ref = Fiber(SparseList{Int16, Int16}(4, [1, 1], [], Element{0.0, Float64}([])))
        res = Fiber(Finch.SparseListLevel{Int16, Int16}(4, Int16[1, 1], Int16[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int16}(4, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel constructors" begin
        ref = Fiber(Dense{Int}(6, Element{0.0, Float64}([0.0, 1.0, 0.0, 1.0, 0.0, 0.0])))
        res = Fiber(Finch.DenseLevel(6, Element{0.0, Float64}([0.0, 1.0, 0.0, 1.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(6, Element{0.0, Float64}([0.0, 1.0, 0.0, 1.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel{Int16} constructors" begin
        ref = Fiber(Dense{Int16}(6, Element{0.0, Float64}([0.0, 1.0, 0.0, 1.0, 0.0, 0.0])))
        res = Fiber(Finch.DenseLevel{Int16}(6, Element{0.0, Float64}([0.0, 1.0, 0.0, 1.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel constructors" begin
        ref = Fiber(SparseList{Int, Int}(6, [1, 3], [2, 4], Element{0.0, Float64}([1.0, 1.0])))
        res = Fiber(Finch.SparseListLevel(6, [1, 3], [2, 4], Element{0.0, Float64}([1.0, 1.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(6, [1, 3], [2, 4], Element{0.0, Float64}([1.0, 1.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int, Int}(6, [1, 3], [2, 4], Element{0.0, Float64}([1.0, 1.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int16} constructors" begin
        ref = Fiber(SparseList{Int16, Int}(6, [1, 3], [2, 4], Element{0.0, Float64}([1.0, 1.0])))
        res = Fiber(Finch.SparseListLevel{Int16}(6, [1, 3], Int16[2, 4], Element{0.0, Float64}([1.0, 1.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int}(6, [1, 3], Int16[2, 4], Element{0.0, Float64}([1.0, 1.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int16, Int16} constructors" begin
        ref = Fiber(SparseList{Int16, Int16}(6, [1, 3], [2, 4], Element{0.0, Float64}([1.0, 1.0])))
        res = Fiber(Finch.SparseListLevel{Int16, Int16}(6, Int16[1, 3], Int16[2, 4], Element{0.0, Float64}([1.0, 1.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel constructors" begin
        ref = Fiber(Dense{Int}(0, Element{0.0, Float64}([])))
        res = Fiber(Finch.DenseLevel(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel{Int16} constructors" begin
        ref = Fiber(Dense{Int16}(0, Element{0.0, Float64}([])))
        res = Fiber(Finch.DenseLevel{Int16}(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int16}(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel constructors" begin
        ref = Fiber(SparseList{Int, Int}(0, [1, 1], [], Element{0.0, Float64}([])))
        res = Fiber(Finch.SparseListLevel(0, [1, 1], Int[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(0, [1, 1], Int[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int, Int}(0, [1, 1], Int[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int, Int}(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int, Int}(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int16} constructors" begin
        ref = Fiber(SparseList{Int16, Int}(0, [1, 1], [], Element{0.0, Float64}([])))
        res = Fiber(Finch.SparseListLevel{Int16}(0, [1, 1], Int16[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16}(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16}(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int}(0, [1, 1], Int16[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int}(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int}(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int16, Int16} constructors" begin
        ref = Fiber(SparseList{Int16, Int16}(0, [1, 1], [], Element{0.0, Float64}([])))
        res = Fiber(Finch.SparseListLevel{Int16, Int16}(0, Int16[1, 1], Int16[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int16}(0, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int16}(Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel constructors" begin
        ref = Fiber(Dense{Int}(4, Element{0.0, Float64}([0.0, 0.0, 0.0, 0.0])))
        res = Fiber(Finch.DenseLevel(4, Element{0.0, Float64}([0.0, 0.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(4, Element{0.0, Float64}([0.0, 0.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel{Int16} constructors" begin
        ref = Fiber(Dense{Int16}(4, Element{0.0, Float64}([0.0, 0.0, 0.0, 0.0])))
        res = Fiber(Finch.DenseLevel{Int16}(4, Element{0.0, Float64}([0.0, 0.0, 0.0, 0.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel constructors" begin
        ref = Fiber(SparseList{Int, Int}(4, [1, 1], [], Element{0.0, Float64}([])))
        res = Fiber(Finch.SparseListLevel(4, [1, 1], Int[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel(4, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(4, [1, 1], Int[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(4, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int, Int}(4, [1, 1], Int[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int, Int}(4, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int16} constructors" begin
        ref = Fiber(SparseList{Int16, Int}(4, [1, 1], [], Element{0.0, Float64}([])))
        res = Fiber(Finch.SparseListLevel{Int16}(4, [1, 1], Int16[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16}(4, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int}(4, [1, 1], Int16[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int}(4, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int16, Int16} constructors" begin
        ref = Fiber(SparseList{Int16, Int16}(4, [1, 1], [], Element{0.0, Float64}([])))
        res = Fiber(Finch.SparseListLevel{Int16, Int16}(4, Int16[1, 1], Int16[], Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int16}(4, Element{0.0, Float64}([])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel constructors" begin
        ref = Fiber(Dense{Int}(6, Element{0.0, Float64}([0.0, 2.0, 2.0, 0.0, 3.0, 3.0])))
        res = Fiber(Finch.DenseLevel(6, Element{0.0, Float64}([0.0, 2.0, 2.0, 0.0, 3.0, 3.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.DenseLevel{Int}(6, Element{0.0, Float64}([0.0, 2.0, 2.0, 0.0, 3.0, 3.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.DenseLevel{Int16} constructors" begin
        ref = Fiber(Dense{Int16}(6, Element{0.0, Float64}([0.0, 2.0, 2.0, 0.0, 3.0, 3.0])))
        res = Fiber(Finch.DenseLevel{Int16}(6, Element{0.0, Float64}([0.0, 2.0, 2.0, 0.0, 3.0, 3.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel constructors" begin
        ref = Fiber(SparseList{Int, Int}(6, [1, 5], [2, 3, 5, 6], Element{0.0, Float64}([2.0, 2.0, 3.0, 3.0])))
        res = Fiber(Finch.SparseListLevel(6, [1, 5], [2, 3, 5, 6], Element{0.0, Float64}([2.0, 2.0, 3.0, 3.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(6, [1, 5], [2, 3, 5, 6], Element{0.0, Float64}([2.0, 2.0, 3.0, 3.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int, Int}(6, [1, 5], [2, 3, 5, 6], Element{0.0, Float64}([2.0, 2.0, 3.0, 3.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int16} constructors" begin
        ref = Fiber(SparseList{Int16, Int}(6, [1, 5], [2, 3, 5, 6], Element{0.0, Float64}([2.0, 2.0, 3.0, 3.0])))
        res = Fiber(Finch.SparseListLevel{Int16}(6, [1, 5], Int16[2, 3, 5, 6], Element{0.0, Float64}([2.0, 2.0, 3.0, 3.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int}(6, [1, 5], Int16[2, 3, 5, 6], Element{0.0, Float64}([2.0, 2.0, 3.0, 3.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int16, Int16} constructors" begin
        ref = Fiber(SparseList{Int16, Int16}(6, [1, 5], [2, 3, 5, 6], Element{0.0, Float64}([2.0, 2.0, 3.0, 3.0])))
        res = Fiber(Finch.SparseListLevel{Int16, Int16}(6, Int16[1, 5], Int16[2, 3, 5, 6], Element{0.0, Float64}([2.0, 2.0, 3.0, 3.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel constructors" begin
        ref = Fiber(SparseList{Int, Int}(1111, [1, 5], [2, 3, 555, 666], Element{0.0, Float64}([20.0, 30.0, 5550.0, 6660.0])))
        res = Fiber(Finch.SparseListLevel(1111, [1, 5], [2, 3, 555, 666], Element{0.0, Float64}([20.0, 30.0, 5550.0, 6660.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int}(1111, [1, 5], [2, 3, 555, 666], Element{0.0, Float64}([20.0, 30.0, 5550.0, 6660.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int, Int}(1111, [1, 5], [2, 3, 555, 666], Element{0.0, Float64}([20.0, 30.0, 5550.0, 6660.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int16} constructors" begin
        ref = Fiber(SparseList{Int16, Int}(1111, [1, 5], [2, 3, 555, 666], Element{0.0, Float64}([20.0, 30.0, 5550.0, 6660.0])))
        res = Fiber(Finch.SparseListLevel{Int16}(1111, [1, 5], Int16[2, 3, 555, 666], Element{0.0, Float64}([20.0, 30.0, 5550.0, 6660.0])))
        @test isstructequal(res, ref)
        res = Fiber(Finch.SparseListLevel{Int16, Int}(1111, [1, 5], Int16[2, 3, 555, 666], Element{0.0, Float64}([20.0, 30.0, 5550.0, 6660.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.SparseListLevel{Int16, Int16} constructors" begin
        ref = Fiber(SparseList{Int16, Int16}(1111, [1, 5], [2, 3, 555, 666], Element{0.0, Float64}([20.0, 30.0, 5550.0, 6660.0])))
        res = Fiber(Finch.SparseListLevel{Int16, Int16}(1111, Int16[1, 5], Int16[2, 3, 555, 666], Element{0.0, Float64}([20.0, 30.0, 5550.0, 6660.0])))
        @test isstructequal(res, ref)
    end
    @testset "Finch.ElementLevel{0.0} constructors" begin
        ref = Fiber(Element{0.0, Float64}([0.0]))
        res = Fiber(Finch.ElementLevel{0.0}([0.0]))
        @test isstructequal(res, ref)
        res = Fiber(Finch.ElementLevel{0.0}())
        @test isstructequal(res, ref)
        res = Fiber(Finch.ElementLevel{0.0, Float64}([0.0]))
        @test isstructequal(res, ref)
        res = Fiber(Finch.ElementLevel{0.0, Float64}())
        @test isstructequal(res, ref)
    end
    @testset "Finch.ElementLevel{0.0, Any} constructors" begin
        ref = Fiber(Element{0.0, Any}([0.0]))
        res = Fiber(Finch.ElementLevel{0.0, Any}(Any[0.0]))
        @test isstructequal(res, ref)
        res = Fiber(Finch.ElementLevel{0.0, Any}())
        @test isstructequal(res, ref)
    end
    @testset "Finch.ElementLevel constructors" begin
        ref = Fiber(Element{0.0, Float64}([0.0]))
        res = Fiber(Finch.ElementLevel(0.0, [0.0]))
        @test isstructequal(res, ref)
        res = Fiber(Finch.ElementLevel(0.0))
        @test isstructequal(res, ref)
    end
    @testset "Finch.ElementLevel{0.0} constructors" begin
        ref = Fiber(Element{0.0, Float64}([1.0]))
        res = Fiber(Finch.ElementLevel{0.0}([1.0]))
        @test isstructequal(res, ref)
        res = Fiber(Finch.ElementLevel{0.0, Float64}([1.0]))
        @test isstructequal(res, ref)
    end
    @testset "Finch.ElementLevel{0.0, Any} constructors" begin
        ref = Fiber(Element{0.0, Any}([1.0]))
        res = Fiber(Finch.ElementLevel{0.0, Any}(Any[1.0]))
        @test isstructequal(res, ref)
    end
    @testset "Finch.ElementLevel constructors" begin
        ref = Fiber(Element{0.0, Float64}([1.0]))
        res = Fiber(Finch.ElementLevel(0.0, [1.0]))
        @test isstructequal(res, ref)
    end
    @testset "Finch.ElementLevel{0.0} constructors" begin
        ref = Fiber(Element{0.0, Float64}([0.0]))
        res = Fiber(Finch.ElementLevel{0.0}([0.0]))
        @test isstructequal(res, ref)
        res = Fiber(Finch.ElementLevel{0.0}())
        @test isstructequal(res, ref)
        res = Fiber(Finch.ElementLevel{0.0, Float64}([0.0]))
        @test isstructequal(res, ref)
        res = Fiber(Finch.ElementLevel{0.0, Float64}())
        @test isstructequal(res, ref)
    end
    @testset "Finch.ElementLevel{0.0, Any} constructors" begin
        ref = Fiber(Element{0.0, Any}([0.0]))
        res = Fiber(Finch.ElementLevel{0.0, Any}(Any[0.0]))
        @test isstructequal(res, ref)
        res = Fiber(Finch.ElementLevel{0.0, Any}())
        @test isstructequal(res, ref)
    end
    @testset "Finch.ElementLevel constructors" begin
        ref = Fiber(Element{0.0, Float64}([0.0]))
        res = Fiber(Finch.ElementLevel(0.0, [0.0]))
        @test isstructequal(res, ref)
        res = Fiber(Finch.ElementLevel(0.0))
        @test isstructequal(res, ref)
    end
    @testset "Finch.ElementLevel{0.0} constructors" begin
        ref = Fiber(Element{0.0, Float64}([1.0]))
        res = Fiber(Finch.ElementLevel{0.0}([1.0]))
        @test isstructequal(res, ref)
        res = Fiber(Finch.ElementLevel{0.0, Float64}([1.0]))
        @test isstructequal(res, ref)
    end
    @testset "Finch.ElementLevel{0.0, Any} constructors" begin
        ref = Fiber(Element{0.0, Any}([1.0]))
        res = Fiber(Finch.ElementLevel{0.0, Any}(Any[1.0]))
        @test isstructequal(res, ref)
    end
    @testset "Finch.ElementLevel constructors" begin
        ref = Fiber(Element{0.0, Float64}([1.0]))
        res = Fiber(Finch.ElementLevel(0.0, [1.0]))
        @test isstructequal(res, ref)
    end
end
