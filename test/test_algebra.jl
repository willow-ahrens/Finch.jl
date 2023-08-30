struct MyAlgebra <: Finch.AbstractAlgebra end
struct MyAlgebra2 <: Finch.AbstractAlgebra end

@testset "algebra" begin
    @info "Testing Custom Algebras"
    u = Fiber!(SparseList(Element(1)), [3, 1, 6, 1, 9, 1, 4, 1, 8, 1])
    v = Fiber!(SparseList(Element(1)), [1, 2, 3, 1, 1, 1, 1, 4, 1, 1])
    w = Fiber!(SparseList(Element(1)))

    @finch (w .= 1; for i=_; w[i] = gcd(u[i], v[i]) end)

    @test pattern!(w) == [1, 1, 1, 0, 1, 0, 1, 1, 1, 0]

    Finch.virtualize(ex, ::Type{MyAlgebra}, ctx) = MyAlgebra()

    Finch.virtualize(ex, ::Type{MyAlgebra2}, ctx) = MyAlgebra2()

    Finch.isassociative(::MyAlgebra, ::typeof(gcd)) = true
    Finch.iscommutative(::MyAlgebra, ::typeof(gcd)) = true
    Finch.isannihilator(::MyAlgebra, ::typeof(gcd), x) = x == 1

    @finch algebra = MyAlgebra() (w .= 1; for i=_; w[i] = gcd(u[i], v[i]) end)

    @test pattern!(w) == [0, 0, 1, 0, 0, 0, 0, 0, 0, 0]

    @finch algebra = MyAlgebra2() (w .= 1; for i=_; w[i] = gcd(u[i], v[i]) end)

    @test pattern!(w) == [1, 1, 1, 0, 1, 0, 1, 1, 1, 0]

    Finch.isassociative(::MyAlgebra2, ::typeof(gcd)) = true
    Finch.iscommutative(::MyAlgebra2, ::typeof(gcd)) = true
    Finch.isannihilator(::MyAlgebra2, ::typeof(gcd), x) = x == 1

    @finch algebra = MyAlgebra2() (w .= 1; for i=_; w[i] = gcd(u[i], v[i]) end)

    @test pattern!(w) == [1, 1, 1, 0, 1, 0, 1, 1, 1, 0]

    Finch.refresh()

    @finch algebra = MyAlgebra2() (w .= 1; for i=_; w[i] = gcd(u[i], v[i]) end)

    @test pattern!(w) == [0, 0, 1, 0, 0, 0, 0, 0, 0, 0]

end