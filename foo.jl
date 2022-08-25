using Finch
println("B(sl)[i] = A(sv)[i]")
A = Finch.Fiber(
    SparseVBL(10, [1, 4], [3, 5, 9], [1, 2, 3, 6],
    Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))

B = Finch.Fiber(Dense(Element{0.0}()))
@finch @loop i B[i] = A[i]
display(B)

B = Finch.Fiber(SparseList(Element{0.0}()))
@finch @loop i B[i] = A[i]
display(B)
