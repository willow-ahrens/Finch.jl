using Finch: index
@testset "SSA" begin
    A = index(:A)
    C = index(:C)
    D = index(:D)
    A_2 = index(:A_2)
    C_2 = index(:C_2)
    ex = Finch.TransformSSA(Finch.Freshen())(Finch.@f(
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

    @test ex == Finch.@f(
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