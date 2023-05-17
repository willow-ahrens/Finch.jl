@testset "conversions" begin
    @info "Testing Fiber Conversions"
    for base in [
        #Pattern,
        Element{false},
    ]
        #=
        for arr in [
            fill(false),
            fill(true)
        ]
            ref = Scalar(false)
            res = Scalar(false)
            @finch ref[] = arr[]
            tmp = Fiber(base())
            @finch tmp[] = ref[]
            @finch res[] = tmp[]
            @test ref[] == res[]
        end
        =#

        if true #base != Pattern
            for inner in [
                () -> Dense(base()),
                () -> RepeatRLE{false}(),
            ]
                for arr in [
                    fill(false, 5),
                    fill(true, 5),
                    [false, true, true, false, false, true],
                    begin
                        x = fill(false, 1111)
                        x[2] = true 
                        x[3]= true
                        x[555:999] .= true
                        x[1001] = true
                        x
                    end,
                ]
                    ref = @fiber sl(e(false))
                    res = @fiber sl(e(false))
                    ref = dropdefaults!(ref, arr)
                    tmp = Fiber!(inner())
                    @testset "convert $(summary(tmp))" begin
                        @finch (tmp .= 0; @loop i tmp[i] = ref[i])
                        check = Scalar(true)
                        @finch @loop i check[] &= tmp[i] == ref[i]
                        @test check[]
                    end
                end
                for outer in [
                    () -> Dense(inner()),
                    () -> SparseList(inner()),
                ]

                    for (arr_key, arr) in [
                        ("5x5_falses", fill(false, 5, 5)),
                        ("5x5_trues", fill(true, 5, 5)),
                        ("4x4_bool_mix", [false true  false true ;
                        false false false false
                        true  true  true  true
                        false true  false true ])
                    ]
                        ref = @fiber sl(sl(e(false)))
                        res = @fiber sl(sl(e(false)))
                        ref = dropdefaults!(ref, arr)
                        tmp = Fiber!(outer())
                        @testset "convert $arr_key $(summary(tmp))"  begin
                            @finch (tmp .= 0; @loop j i tmp[i, j] = ref[i, j])
                            check = Scalar(true)
                            @finch @loop j i check[] &= tmp[i, j] == ref[i, j]
                            @test check[]
                        end
                    end
                end
            end
        end

        for inner in [
            () -> SparseList(base()),
            () -> SparseVBL(base()),
            () -> SparseByteMap(base()),
            () -> SparseHash{1}(base()),
            () -> SparseCOO{1}(base()),
        ]
            for arr in [
                fill(false, 5),
                fill(true, 5),
                [false, true, true, false, false, true]
            ]
                ref = @fiber sl(e(false))
                res = @fiber sl(e(false))
                ref = dropdefaults!(ref, arr)
                tmp = Fiber!(inner())
                @testset "convert $(summary(tmp))" begin
                    @finch (tmp .= 0; @loop i tmp[i] = ref[i])
                    @finch (res .= 0; @loop i res[i] = tmp[i])
                    @test isstructequal(ref, res)
                end
            end

            for outer in [
                () -> Dense(inner()),
                () -> SparseList(inner()),
            ]

                for (arr_key, arr) in [
                    ("5x5_falses", fill(false, 5, 5)),
                    ("5x5_trues", fill(true, 5, 5)),
                    ("4x4_bool_mix", [false true  false true ;
                    false false false false
                    true  true  true  true
                    false true  false true ])
                ]
                    ref = @fiber sl(sl(e(false)))
                    res = @fiber sl(sl(e(false)))
                    ref = dropdefaults!(ref, arr)
                    tmp = Fiber!(outer())
                    @testset "convert $arr_key $(summary(tmp))"  begin
                        @finch (tmp .= 0; @loop j i tmp[i, j] = ref[i, j])
                        @finch (res .= 0; @loop j i res[i, j] = tmp[i, j])
                        @test isstructequal(ref, res)
                    end
                end
            end
        end

        for inner in [
            () -> SparseTriangle{1}(base()),
        ]
            for arr in [
                fill(false, 5),
                fill(true, 5),
                [false, true, true, false, false, true]
            ]
                ref = @fiber sl(e(false))
                res = @fiber sl(e(false))
                tmp = Fiber!(inner())
                @testset "convert $(summary(tmp))" begin
                    @finch (ref .= 0; @loop i ref[i] = arr[i])
                    @finch (tmp .= 0; @loop i tmp[i] = ref[i])
                    @finch (res .= 0; @loop i res[i] = tmp[i])
                    @test isstructequal(ref, res)
                end
            end

            for outer in [
                () -> Dense(inner()),
                () -> SparseList(inner()),
            ]

                for (arr_key, arr) in [
                    ("5x5_falses", fill(false, 5, 5)),
                    ("5x5_trues", fill(true, 5, 5)),
                    ("4x4_bool_mix", [false true  false true ;
                    false false false false
                    true  true  true  true
                    false true  false true ])
                ]
                    ref = @fiber sl(sl(e(false)))
                    res = @fiber sl(sl(e(false)))
                    tmp = Fiber!(outer())
                    @testset "convert $arr_key $(summary(tmp))"  begin
                        @finch (ref .= 0; @loop j i ref[i, j] = arr[i, j])
                        @finch (tmp .= 0; @loop j i tmp[i, j] = ref[i, j])
                        @finch (res .= 0; @loop j i res[i, j] = tmp[i, j])
                        @test isstructequal(ref, res)
                    end
                end
            end
        end


        for outer in [
            () -> SparseCOO{2}(base()),
            () -> SparseHash{2}(base())
        ]

            for (arr_key, arr) in [
                ("5x5_falses", fill(false, 5, 5)),
                ("5x5_trues", fill(true, 5, 5)),
                ("4x4_bool_mix", [false true  false true ;
                false false false false
                true  true  true  true
                false true  false true ])
            ]
                ref = @fiber sl(sl(e(false)))
                res = @fiber sl(sl(e(false)))
                ref = dropdefaults!(ref, arr)
                tmp = Fiber!(outer())
                @testset "convert $arr_key $(summary(tmp))"  begin
                    @finch (tmp .= 0; @loop j i tmp[i, j] = ref[i, j])
                    @finch (res .= 0; @loop j i res[i, j] = tmp[i, j])
                    @test isstructequal(ref, res)
                end
            end
        end

        for outer in [
            () -> SparseTriangle{2}(base())
        ]

            for (arr_key, arr) in [
                ("5x5_falses", fill(false, 5, 5)),
                ("5x5_trues", fill(true, 5, 5)),
                ("4x4_bool_mix", [false true  false true ;
                false false false false
                true  true  true  true
                false true  false true ])
            ]
                ref = @fiber sl(sl(e(false)))
                res = @fiber sl(sl(e(false)))
                ref = dropdefaults!(ref, arr)
                tmp = Fiber!(outer())
                @testset "convert $arr_key $(summary(tmp))"  begin
                    @finch (tmp .= 0; @loop j i tmp[i, j] = ref[i, j])
                    @finch (res .= 0; @loop j i res[i, j] = tmp[i, j])
                    check = Scalar(true)
                    @finch @loop j i if j >= i check[] &= tmp[i, j] == ref[i, j] end
                    @test check[]
                end
            end
        end
    end
end