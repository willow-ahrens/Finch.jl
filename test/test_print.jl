@testset "Print" begin
    A = fiber([(i + j) % 3 for i = 1:5, j = 1:10])

    ntests = 0

    formats = [HollowList, HollowByte, HollowHash{1}, HollowCoo{1}, Solid]


    for rowf in formats
        B = copyto!(Fiber(rowf(Solid(Element{0.0}()))), A)
        @test diff("print_$(ntests += 1)", sprint(show, B))
        @test diff("print_$(ntests += 1)", sprint(show, B, context=:compact=>false))
        @test diff("print_$(ntests += 1)", sprint(show, MIME"text/plain"(), B))
    end

    for colf in formats
        B = copyto!(Fiber(Solid(colf(Element{0.0}()))), A)
        @test diff("print_$(ntests += 1)", sprint(show, B))
        @test diff("print_$(ntests += 1)", sprint(show, B, context=:compact=>false))
        @test diff("print_$(ntests += 1)", sprint(show, MIME"text/plain"(), B))
    end

    formats = [HollowHash{2}, HollowCoo{2}]

    for rowcolf in formats
        B = copyto!(Fiber(rowcolf(Element{0.0}())), A)
        @test diff("print_$(ntests += 1)", sprint(show, B))
        @test diff("print_$(ntests += 1)", sprint(show, B, context=:compact=>false))
        @test diff("print_$(ntests += 1)", sprint(show, MIME"text/plain"(), B))
    end
    
end