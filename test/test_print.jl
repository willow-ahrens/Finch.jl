@testset "Print" begin
    A = fiber([(i + j) % 3 for i = 1:5, j = 1:10])

    formats = [
        "list" => SparseList,
        "byte" => SparseBytemap,
        "hash1" => SparseHash{1},
        "coo1" => SparseCoo{1},
        "dense" => Dense
    ]

    for (rown, rowf) in formats
        B = copyto!(Fiber(rowf(Dense(Element{0.0}()))), A)
        @test diff("print_$(rown)_dense.txt", sprint(show, B))
        @test diff("print_$(rown)_dense_small.txt", sprint(show, B, context=:compact=>false))
        @test diff("display_$(rown)_dense.txt", sprint(show, MIME"text/plain"(), B))
        @test diff("summary_$(rown)_dense.txt", summary(B))
    end

    for (coln, colf) in formats
        B = copyto!(Fiber(Dense(colf(Element{0.0}()))), A)
        @test diff("print_dense_$coln.txt", sprint(show, B))
        @test diff("print_dense_$(coln)_small.txt", sprint(show, B, context=:compact=>false))
        @test diff("display_dense_$(coln).txt", sprint(show, MIME"text/plain"(), B))
        @test diff("summary_dense_$(coln).txt", summary(B))
    end

    formats = [
        "hash2" => SparseHash{2},
        "coo2" =>SparseCoo{2},
        ]

    for (rowcoln, rowcolf) in formats
        B = copyto!(Fiber(rowcolf(Element{0.0}())), A)
        @test diff("print_$rowcoln.txt", sprint(show, B))
        @test diff("print_$(rowcoln)_small.txt", sprint(show, B, context=:compact=>false))
        @test diff("display_$(rowcoln).txt", sprint(show, MIME"text/plain"(), B))
        @test diff("summary_$(rowcoln).txt", summary(B))
    end
end