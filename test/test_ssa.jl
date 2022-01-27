using Finch: Name
@testset "SSA" begin
    A = Name(:A)
    C = Name(:C)
    D = Name(:D)
    A_2 = Name(:A_2)
    C_2 = Name(:C_2)
    ex = Finch.TransformSSA(Finch.Freshen())(Finch.@i(
        @loop i (
            @loop j (
                @loop j (
                        A[i, j] += A[i] * C[i, j]
                    ) where (
                        (
                            A[i] += C[j]
                        ) where (
                            C[j] += D[j]
                        )
                    )
            )
        )
    ))

    display(ex)
    println()

    @test ex == Finch.@i(
        @loop i (
            @loop j (
                @loop j_2 (
                        A_2[i, j_2] += A_2[i] * C_2[i, j_2]
                    ) where (
                        (
                            A[i] += C[j_2]
                        ) where (
                            C[j_2] += D[j_2]
                        )
                    )
            )
        )
    )

    @test ex == Finch.TransformSSA(Finch.Freshen())(ex) #fixpoint
end