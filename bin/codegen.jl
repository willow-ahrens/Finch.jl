using Thrush

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

i = Index(:i)
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

println(lower(ex))


