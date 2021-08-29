using Thrush
using Pigeon
using SparseArrays

#=
A = Tensor(:A, VirtualSparseFiber(
    Ti = Int,
    ex = "A.level",
    name = "A1",
    default = 0,
    child = VirtualSparseFiber(
        Ti = Int,
        ex = "A.level.level"
        name = "A2",
        default = 0,
        child = VirtualScalarFiber(
            ex = "A.level.level.level"
            name = "A3",
        )
    )
)
j = Index(:j)

ex = 
    Forall(i,
        Forall(j,
            Assign(
                Access(
                    A,
                    i,
                    j
                ),
                Call(:+,
                    Access(
                        A,
                        i,
                        j
                    ),
                    Literal(1)
                )
            )
        )
    )

i = Index(:i)

A = Thrush.VirtualScalarFiber(1,
    Thrush.VirtualScalarLevel(
        :(data),
        Float64
    )
)

B = Thrush.VirtualDenseFiber(1,
    Thrush.VirtualDenseLevel(
        :(data),
        Int64,
        Thrush.VirtualScalarLevel(
            :(data),
            Float64
        )
    )
)

=#

A = sprand(10, 20, 0.5)

bottom = ScalarLevel(A.nzval)
middle = SparseLevel{Float64, Int, 1}(20, 10, A.colptr, A.rowval, bottom)
top = DenseLevel{Float64, Int, 2}(1, 20, middle)

A = Thrush.Virtual{typeof(ScalarFiber(1, bottom))}(:A)
B = Thrush.Virtual{typeof(ScalarFiber(15, bottom))}(:B)

println(lower(i"$A[] = $A[]"))
println(lower(i"∀ i $A[] = $A[]"))
println(lower(i"∀ i $A[] = $B[]"))