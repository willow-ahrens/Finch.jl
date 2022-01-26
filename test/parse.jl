using Finch.IndexNotation
using Finch.IndexNotation: mesacall, mesaaccess, mesavalue, mesaname, mesaloop, mesawith, mesalabel, mesawalk

@testset "Parse" begin
    @test @I(:f(:B[i::walk, k] * :C[k, j]^3, 42)) ==
    mesacall(mesavalue(:f), mesacall(mesalabel(:*, mesavalue(*)), mesaaccess(mesavalue(:B), Read(), mesawalk(:i), mesaname(:k)), mesacall(mesalabel(:^, mesavalue(^)), mesaaccess(mesavalue(:C), Read(), mesaname(:k), mesaname(:j)), mesavalue(3))), mesavalue(42))

    @test Finch.virtualize(:ex, typeof(@I(:f(:B[i::walk, k] * :C[k, j]^3, 42))), Finch.LowerJuliaContext()) ==
    call(:f, call(*, access(:B, Read(), Walk(:i), Name(:k)), call(^, access(:C, Read(), Name(:k), Name(:j)), 3)), 42) 

    #call(:f, call(*, mesaaccess(:B, Read(), Name(:i), Name(:k)), call(^, mesaaccess(:C, Read(), Name(:k), Name(:j)), 3)), 42)
    #call(:f, call(*, access(:B, Read(), Name(:i), Name(:k)), call(^, access(:C, Read(), Name(:k), Name(:j)), 3)), 42)

    #@test @i(
    #    @loop i (
    #        @loop j :A[i, j] += :w[j]
    #    ) where (
    #        @loop j k :w[j] += :B[i, k] * :C[k, j]
    #    )
    #) ==
    #loop(Name(:i), with(loop(Name(:j), assign(access(:A, Update(), Name(:i), Name(:j)), +, access(:w, Read(), Name(:j)))), loop(Name(:j), Name(:k), assign(access(:w, Update(), Name(:j)), +, call(*, access(:B, Read(), Name(:i), Name(:k)), access(:C, Read(), Name(:k), Name(:j)))))))
end