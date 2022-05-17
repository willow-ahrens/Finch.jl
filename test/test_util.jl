using Finch.DisjointDicts
@testset "Utilities" begin
    x = DisjointDict((1,) => :a, (2, 3) => :b, (4, 5) => :c)
    @test x[1] == :a
    @test x[2] == x[3] == :b
    @test x[4] == x[5] == :c
    @test_throws KeyError x[6]
    x[3, 4] = :d
    @test x[1] == :a
    @test x[2] == x[3] == x[4] == x[5] == :d
    x = DisjointDict((1,) => [:a], (2, 3) => [:b], (4, 5) => [:c], (6, 7, 8, 9) => [:d])
    y = DisjointDict((1,6) => [:e], (3, 4, 5) => [:f], (10,) => [:g])
    mergewith!((a, b) -> sort(vcat(a, b)), x, y)
    @test x[1] == x[6] == x[7] == x[8] == x[9] == [:a, :d, :e]
    @test x[2] == x[3] == x[4] == x[5] == [:b, :c, :f]
    @test x[10] == [:g]
end