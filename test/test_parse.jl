
@testset "Parse" begin
    @test @finch_program_instance(:f(:B[i::walk, k] * :C[k, j]^3, 42)) ==
        call_instance(
            value_instance(:f),
            call_instance(
                label_instance(:*, value_instance(*)),
                access_instance(
                    value_instance(:B),
                    reader(),
                    protocol_instance(name_instance(:i), walk),
                    name_instance(:k)),
                call_instance(
                    label_instance(:^, value_instance(^)),
                    access_instance(
                        value_instance(:C),
                        reader(),
                        name_instance(:k),
                        name_instance(:j)),
                    value_instance(3))),
            value_instance(42))

    @test Finch.virtualize(:ex, typeof(@finch_program_instance(:f(:B[i::walk, k] * :C[k, j]^3, 42))), Finch.LowerJulia()) ==
        call(literal(:f), 
            call(*,
                access(literal(:B), reader(), protocol(name(:i), walk), name(:k)),
                call(^,
                    access(literal(:C), reader(), name(:k), name(:j)),
                    3)),
            42) 

    @test Finch.virtualize(:ex, typeof(@finch_program_instance((:A[] = 1; :B[] = 2))), Finch.LowerJulia()) ==
        multi(
            assign(
                access(literal(:A), reader()), 1),
                assign(
                    access(literal(:B), reader()),
                    2))

    @test @finch_program(@loop i :A[i] += :B[i] * i) ==
        loop(name(:i),
            assign(
                access(:A, updater(+, false), name(:i)),
                call(*,
                    access(:B, reader(), name(:i)),
                    name(:i))))

    @test @finch_program_instance(@loop i :A[i] += :B[i] * i) ==
        loop_instance(
            name_instance(:i),
            assign_instance(
                access_instance(
                    value_instance(:A),
                    updater_instance(),
                    name_instance(:i)),
                label_instance(:+, value_instance(+)),
                call_instance(
                    label_instance(:*, value_instance(*)),
                    access_instance(
                        value_instance(:B),
                        reader_instance(),
                        name_instance(:i)),
                    name_instance(:i))))

    @test @finch_program(@loop i :A[i] <<(+)>>= :B[i] * i) ==
        loop(name(:i),
            assign(
                access(:A, updater(+, false), name(:i)),
                call(*,
                    access(:B, reader(), name(:i)),
                    name(:i))))

    @test @finch_program_instance(@loop i :A[i] <<(+)>>= :B[i] * i) ==
        loop_instance(
            name_instance(:i),
            assign_instance(
                access_instance(
                    value_instance(:A),
                    updater_instance(),
                    name_instance(:i)),
                label_instance(:+, value_instance(+)),
                call_instance(
                    label_instance(:*, value_instance(*)),
                    access_instance(
                        value_instance(:B),
                        reader_instance(),
                        name_instance(:i)),
                    name_instance(:i))))

    @test @finch_program(:A[i] += i < j < k) ==
        assign(
            access(:A, updater(+, false), name(:i)),
            call(Finch.IndexNotation.and,
                call(<, name(:i), name(:j)),
                call(<, name(:j), name(:k))))

    @test @finch_program(:A[i] = i == j && k < l) ==
        assign(
            access(:A, updater(false), name(:i)),
            nothing,
            call(Finch.IndexNotation.and,
                call(==, name(:i), name(:j)),
                call(<, name(:k), name(:l))))

end