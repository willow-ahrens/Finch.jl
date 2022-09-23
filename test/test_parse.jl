
@testset "Parse" begin
    @test @finch_program_instance(:f(:B[i::walk, k] * :C[k, j]^3, 42)) ==
        call_instance(
            value_instance(:f),
            call_instance(
                label_instance(:*, value_instance(*)),
                access_instance(
                    value_instance(:B),
                    Read(),
                    protocol_instance(name_instance(:i), walk),
                    name_instance(:k)),
                call_instance(
                    label_instance(:^, value_instance(^)),
                    access_instance(
                        value_instance(:C),
                        Read(),
                        name_instance(:k),
                        name_instance(:j)),
                    value_instance(3))),
            value_instance(42))

    @test Finch.virtualize(:ex, typeof(@finch_program_instance(:f(:B[i::walk, k] * :C[k, j]^3, 42))), Finch.LowerJulia()) ==
        call(Literal(:f), 
            call(*,
                access(Literal(:B), Read(), Protocol(Name(:i), walk), Name(:k)),
                call(^,
                    access(Literal(:C), Read(), Name(:k), Name(:j)),
                    3)),
            42) 

    @test Finch.virtualize(:ex, typeof(@finch_program_instance((:A[] = 1; :B[] = 2))), Finch.LowerJulia()) ==
        multi(
            assign(
                access(Literal(:A), Read()), 1),
                assign(
                    access(Literal(:B), Read()),
                    2))

    @test @finch_program(@loop i :A[i] += :B[i] * i) ==
        loop(Name(:i),
            assign(
                access(:A, Update(), Name(:i)),
                +,
                call(*,
                    access(:B, Read(), Name(:i)),
                    Name(:i))))

    @test @finch_program_instance(@loop i :A[i] += :B[i] * i) ==
        loop_instance(
            name_instance(:i),
            assign_instance(
                access_instance(
                    value_instance(:A),
                    Update(),
                    name_instance(:i)),
                label_instance(:+, value_instance(+)),
                call_instance(
                    label_instance(:*, value_instance(*)),
                    access_instance(
                        value_instance(:B),
                        Read(),
                        name_instance(:i)),
                    name_instance(:i))))

    @test @finch_program(@loop i :A[i] <<(+)>>= :B[i] * i) ==
        loop(Name(:i),
            assign(
                access(:A, Update(), Name(:i)),
                +,
                call(*,
                    access(:B, Read(), Name(:i)),
                    Name(:i))))

    @test @finch_program_instance(@loop i :A[i] <<(+)>>= :B[i] * i) ==
        loop_instance(
            name_instance(:i),
            assign_instance(
                access_instance(
                    value_instance(:A),
                    Update(),
                    name_instance(:i)),
                label_instance(:+, value_instance(+)),
                call_instance(
                    label_instance(:*, value_instance(*)),
                    access_instance(
                        value_instance(:B),
                        Read(),
                        name_instance(:i)),
                    name_instance(:i))))

    @test @finch_program(:A[i] += i < j < k) ==
        assign(
            access(:A, Update(), Name(:i)),
            +,
            call(Finch.IndexNotation.and,
                call(<, Name(:i), Name(:j)),
                call(<, Name(:j), Name(:k))))

    @test @finch_program(:A[i] = i == j && k < l) ==
        assign(
            access(:A, Write(), Name(:i)),
            nothing,
            call(Finch.IndexNotation.and,
                call(==, Name(:i), Name(:j)),
                call(<, Name(:k), Name(:l))))

end