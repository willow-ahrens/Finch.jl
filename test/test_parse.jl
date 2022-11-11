
@testset "Parse" begin
    @test @finch_program_instance(:f(:B[i::walk, k] * :C[k, j]^3, 42)) ==
        call_instance(
            value_instance(:f),
            call_instance(
                label_instance(:*, value_instance(*)),
                access_instance(
                    value_instance(:B),
                    reader(),
                    protocol_instance(index_instance(:i), walk),
                    index_instance(:k)),
                call_instance(
                    label_instance(:^, value_instance(^)),
                    access_instance(
                        value_instance(:C),
                        reader(),
                        index_instance(:k),
                        index_instance(:j)),
                    value_instance(3))),
            value_instance(42))

    @test Finch.virtualize(:ex, typeof(@finch_program_instance(:f(:B[i::walk, k] * :C[k, j]^3, 42))), Finch.LowerJulia()) ==
        call(literal(:f), 
            call(*,
                access(literal(:B), reader(), protocol(index(:i), walk), index(:k)),
                call(^,
                    access(literal(:C), reader(), index(:k), index(:j)),
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
        loop(index(:i),
            assign(
                access(:A, updater(+, false), index(:i)),
                call(*,
                    access(:B, reader(), index(:i)),
                    index(:i))))

    @test @finch_program_instance(@loop i :A[i] += :B[i] * i) ==
        loop_instance(
            index_instance(:i),
            assign_instance(
                access_instance(
                    value_instance(:A),
                    updater_instance(),
                    index_instance(:i)),
                label_instance(:+, value_instance(+)),
                call_instance(
                    label_instance(:*, value_instance(*)),
                    access_instance(
                        value_instance(:B),
                        reader_instance(),
                        index_instance(:i)),
                    index_instance(:i))))

    @test @finch_program(@loop i :A[i] <<(+)>>= :B[i] * i) ==
        loop(index(:i),
            assign(
                access(:A, updater(+, false), index(:i)),
                call(*,
                    access(:B, reader(), index(:i)),
                    index(:i))))

    @test @finch_program_instance(@loop i :A[i] <<(+)>>= :B[i] * i) ==
        loop_instance(
            index_instance(:i),
            assign_instance(
                access_instance(
                    value_instance(:A),
                    updater_instance(),
                    index_instance(:i)),
                label_instance(:+, value_instance(+)),
                call_instance(
                    label_instance(:*, value_instance(*)),
                    access_instance(
                        value_instance(:B),
                        reader_instance(),
                        index_instance(:i)),
                    index_instance(:i))))

    @test @finch_program(:A[i] += i < j < k) ==
        assign(
            access(:A, updater(+, false), index(:i)),
            call(Finch.IndexNotation.and,
                call(<, index(:i), index(:j)),
                call(<, index(:j), index(:k))))

    @test @finch_program(:A[i] = i == j && k < l) ==
        assign(
            access(:A, updater(false), index(:i)),
            nothing,
            call(Finch.IndexNotation.and,
                call(==, index(:i), index(:j)),
                call(<, index(:k), index(:l))))

end