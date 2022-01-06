using Finch: mesacall, mesaaccess, mesavalue, mesaname, mesaloop, mesawith, mesalabel, virtualize
@testset "Parse" begin
    @test @I(:f(:B[i, k] * :C[k, j]^3, 42)) ==
    mesacall(mesavalue(:f), mesacall(mesalabel(:*, mesavalue(*)), mesaaccess(mesavalue(:B), Pigeon.Read(), mesaname(:i), mesaname(:k)), mesacall(mesalabel(:^, mesavalue(^)), mesaaccess(mesavalue(:C), Pigeon.Read(), mesaname(:k), mesaname(:j)), mesavalue(3))), mesavalue(42))

    @test virtualize(:ex, typeof(@I(:f(:B[i, k] * :C[k, j]^3, 42))), Finch.LowerJuliaContext()) ==
    call(:f, call(*, access(:B, Pigeon.Read(), Name(:i), Name(:k)), call(^, access(:C, Pigeon.Read(), Name(:k), Name(:j)), 3)), 42) 
    call(:f, call(*, mesaaccess(:B, Pigeon.Read(), Name(:i), Name(:k)), call(^, mesaaccess(:C, Pigeon.Read(), Name(:k), Name(:j)), 3)), 42)
    call(:f, call(*, access(:B, Pigeon.Read(), Name(:i), Name(:k)), call(^, access(:C, Pigeon.Read(), Name(:k), Name(:j)), 3)), 42)

    #@test @i(
    #    @loop i (
    #        @loop j :A[i, j] += :w[j]
    #    ) where (
    #        @loop j k :w[j] += :B[i, k] * :C[k, j]
    #    )
    #) ==
    #loop(Name(:i), with(loop(Name(:j), assign(access(:A, Pigeon.Update(), Name(:i), Name(:j)), +, access(:w, Pigeon.Read(), Name(:j)))), loop(Name(:j), Name(:k), assign(access(:w, Pigeon.Update(), Name(:j)), +, call(*, access(:B, Pigeon.Read(), Name(:i), Name(:k)), access(:C, Pigeon.Read(), Name(:k), Name(:j)))))))
end