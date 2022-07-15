@testset "Print" begin
    A = fiber([(i + j) % 3 for i = 1:5, j = 1:10])

    formats = [
        "list" => HollowList,
        "byte" => HollowByte,
        "hash1" => HollowHash{1},
        "coo1" => HollowCoo{1},
        "solid" => Solid
    ]

    for (rown, rowf) in formats
        B = copyto!(Fiber(rowf(Solid(Element{0.0}()))), A)
        @test diff("print_$(rown)_solid.txt", sprint(show, B))
        @test diff("print_$(rown)_solid_small.txt", sprint(show, B, context=:compact=>false))
        @test diff("display_$(rown)_solid.txt", sprint(show, MIME"text/plain"(), B))
        @test diff("summary_$(rown)_solid.txt", summary(B))
    end

    for (coln, colf) in formats
        B = copyto!(Fiber(Solid(colf(Element{0.0}()))), A)
        @test diff("print_solid_$coln.txt", sprint(show, B))
        @test diff("print_solid_$(coln)_small.txt", sprint(show, B, context=:compact=>false))
        @test diff("display_solid_$(coln).txt", sprint(show, MIME"text/plain"(), B))
        @test diff("summary_solid_$(coln).txt", summary(B))
    end

    formats = [
        "hash2" => HollowHash{2},
        "coo2" =>HollowCoo{2},
        ]

    for (rowcoln, rowcolf) in formats
        B = copyto!(Fiber(rowcolf(Element{0.0}())), A)
        @test diff("print_$rowcoln.txt", sprint(show, B))
        @test diff("print_$(rowcoln)_small.txt", sprint(show, B, context=:compact=>false))
        @test diff("display_$(rowcoln).txt", sprint(show, MIME"text/plain"(), B))
        @test diff("summary_$(rowcoln).txt", summary(B))
    end
end