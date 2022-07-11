@testset "Print" begin
    A = fiber([(i + j) % 3 for i = 1:5, j = 1:10])

    ntests = 0

    function test_show(A, ctx...)
        ntests += 1
        test_name = "print_$ntests"
        io = IOBuffer()
        show(IOContext(io, ctx...), A)
        output = String(take!(io))
        @test diff(test_name, output)
    end

    formats = [HollowList, HollowByte, HollowHash{1}, HollowCoo{1}, Solid]

    for rowf in formats
        B = copyto!(Fiber(rowf(Solid(Element{0.0}()))), A)
        test_show(B)
        test_show(B, :compact=>true)
        test_show(B, :compact=>false)
    end

    for colf in formats
        B = copyto!(Fiber(Solid(colf(Element{0.0}()))), A)
        test_show(B)
        test_show(B, :compact=>true)
        test_show(B, :compact=>false)
    end

    formats = [HollowHash{2}, HollowCoo{2}]

    for rowcolf in formats
        B = copyto!(Fiber(rowcolf(Element{0.0}())), A)
        test_show(B)
        test_show(B, :compact=>true)
        test_show(B, :compact=>false)
    end
    
end