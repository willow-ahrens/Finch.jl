struct MyAlgebra <: Finch.AbstractAlgebra end
struct MyAlgebra2 <: Finch.AbstractAlgebra end

@testset "algebra" begin
    @info "Testing Custom Algebras"
    u = @fiber(sl(e(1)), [3, 1, 6, 1, 9, 1, 4, 1, 8, 1])
    v = @fiber(sl(e(1)), [1, 2, 3, 1, 1, 1, 1, 4, 1, 1])
    w = @fiber(sl(e(1)))

    @finch (w .= 1; @loop i w[i] = gcd(u[i], v[i]))

    @test pattern!(w) == [1, 1, 1, 0, 1, 0, 1, 1, 1, 0]

    Finch.isassociative(::MyAlgebra, ::typeof(gcd)) = true
    Finch.iscommutative(::MyAlgebra, ::typeof(gcd)) = true
    Finch.isannihilator(::MyAlgebra, ::typeof(gcd), x) = x == 1

    @finch MyAlgebra() (w .= 1; @loop i w[i] = gcd(u[i], v[i]))

    @test pattern!(w) == [0, 0, 1, 0, 0, 0, 0, 0, 0, 0]

    @finch MyAlgebra2() (w .= 1; @loop i w[i] = gcd(u[i], v[i]))

    @test pattern!(w) == [1, 1, 1, 0, 1, 0, 1, 1, 1, 0]

    Finch.isassociative(::MyAlgebra2, ::typeof(gcd)) = true
    Finch.iscommutative(::MyAlgebra2, ::typeof(gcd)) = true
    Finch.isannihilator(::MyAlgebra2, ::typeof(gcd), x) = x == 1

    @finch MyAlgebra2() (w .= 1; @loop i w[i] = gcd(u[i], v[i]))

    @test pattern!(w) == [1, 1, 1, 0, 1, 0, 1, 1, 1, 0]

    Finch.refresh()

    @finch MyAlgebra2() (w .= 1; @loop i w[i] = gcd(u[i], v[i]))

    @test pattern!(w) == [0, 0, 1, 0, 0, 0, 0, 0, 0, 0]

end