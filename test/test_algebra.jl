struct MyAlgebra <: Finch.AbstractAlgebra end

Finch.isassociative(::MyAlgebra, ::typeof(gcd)) = true
Finch.iscommutative(::MyAlgebra, ::typeof(gcd)) = true
Finch.isannihilator(::MyAlgebra, ::typeof(gcd), x) = x == 1
Finch.register(MyAlgebra)

u = Finch.Fiber(
    SparseList(10, [1, 6], [1, 3, 5, 7, 9],
    Element{1}([3, 6, 9, 4, 8])), Environment())
v = Finch.Fiber(
    SparseList(10, [1, 4], [2, 5, 8],
    Element{1}([2, 3, 4])), Environment())
w = Finch.Fiber(SparseList(Element(1)))

@finch MyAlgebra() @loop i w[i] = gcd(u[i], v[i])

@test w.lvl.pos[1:2] == [1, 2]
@test w.lvl.idx[1:1] == [5]
@test w.lvl.lvl.val[1:1] == [3]

@finch @loop i w[i] = gcd(u[i], v[i])

@test w.lvl.pos[1:2] == [1, 8]
@test w.lvl.idx[1:7] == [1, 2, 3, 5, 7, 8, 9]
@test w.lvl.lvl.val[1:7] == [1, 1, 1, 3, 1, 1, 1]

    