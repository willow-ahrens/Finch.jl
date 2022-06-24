using Finch.IndexNotation
using Finch.IndexNotation: call_instance, assign_instance, access_instance, value_instance, name_instance, loop_instance, with_instance, label_instance, protocol_instance

@testset "Parse" begin
    @test @index_program_instance(:f(:B[i::walk, k] * :C[k, j]^3, 42)) ==
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

    @test Finch.virtualize(:ex, typeof(@index_program_instance(:f(:B[i::walk, k] * :C[k, j]^3, 42))), Finch.LowerJulia()) ==
        call(:f, 
            call(*,
                access(:B, Read(), Protocol(Name(:i), walk), Name(:k)),
                call(^,
                    access(:C, Read(), Name(:k), Name(:j)),
                    3)),
            42) 

    @test Finch.virtualize(:ex, typeof(@index_program_instance((:A[] = 1; :B[] = 2))), Finch.LowerJulia()) ==
        multi(
            assign(
                access(:A, Read()), 1),
                assign(
                    access(:B, Read()),
                    2))

    @test @index_program(@loop i :A[i] += :B[i] * i) ==
        loop(Name(:i),
            assign(
                access(:A,Update(), Name(:i)),
                +,
                call(*,
                    access(:B, Read(), Name(:i)),
                    Name(:i))))

    @test @index_program_instance(@loop i :A[i] += :B[i] * i) ==
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

    @test @index_program(@loop i :A[i] <<(+)>>= :B[i] * i) ==
        loop(Name(:i),
            assign(
                access(:A,Update(), Name(:i)),
                +,
                call(*,
                    access(:B, Read(), Name(:i)),
                    Name(:i))))

    @test @index_program_instance(@loop i :A[i] <<(+)>>= :B[i] * i) ==
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

    @test @index_program(:A[i] += i < j < k) ==
        assign(
            access(:A, Update(), Name(:i)),
            +,
            call(Finch.IndexNotation.and,
                call(<, Name(:i), Name(:j)),
                call(<, Name(:j), Name(:k))))

    @test @index_program(:A[i] = i == j && k < l) ==
        assign(
            access(:A, Write(), Name(:i)),
            nothing,
            call(Finch.IndexNotation.and,
                call(==, Name(:i), Name(:j)),
                call(<, Name(:k), Name(:l))))

end