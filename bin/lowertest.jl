using Thrush
using Pigeon

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
=#

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

println(lower(i"$A[] = $A[]"))
println(lower(i"∀ i $A[] = $A[]"))


