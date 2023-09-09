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
                () -> SparseRLE(base()),
            ]
                for (idx, arr) in enumerate([
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
                   ])
                    ref = Fiber!(SparseList(Element(false)))
                    ref = dropdefaults!(ref, arr)
                    tmp = Fiber!(inner())
                    @testset "convert $(summary(tmp)) $(idx)" begin
                        @finch (tmp .= 0; for i=_; tmp[i] = ref[i] end)
                        check = Scalar(true)
                        @finch for i=_; check[] &= tmp[i] == ref[i] end
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
                        ref = Fiber!(SparseList(SparseList(Element(false))))
                        res = Fiber!(SparseList(SparseList(Element(false))))
                        ref = dropdefaults!(ref, arr)
                        tmp = Fiber!(outer())
                        @testset "convert $arr_key $(summary(tmp))"  begin
                            @finch (tmp .= 0; for j=_, i=_; tmp[i, j] = ref[i, j] end)
                            check = Scalar(true)
                            @finch for j=_, i=_; check[] &= tmp[i, j] == ref[i, j] end
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
            () -> SparseRLE(base()),
        ]
            for arr in [
                fill(false, 5),
                fill(true, 5),
                [false, true, true, false, false, true]
            ]
                ref = Fiber!(SparseList(Element(false)))
                res = Fiber!(SparseList(Element(false)))
                ref = dropdefaults!(ref, arr)
                tmp = Fiber!(inner())
                @testset "convert $(summary(tmp))" begin
                    @finch (tmp .= 0; for i=_; tmp[i] = ref[i] end)
                    @finch (res .= 0; for i=_; res[i] = tmp[i] end)
                    @test Structure(ref) == Structure(res)
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
                    ref = Fiber!(SparseList(SparseList(Element(false))))
                    res = Fiber!(SparseList(SparseList(Element(false))))
                    ref = dropdefaults!(ref, arr)
                    tmp = Fiber!(outer())
                    @testset "convert $arr_key $(summary(tmp))"  begin
                        @finch (tmp .= 0; for j=_, i=_; tmp[i, j] = ref[i, j] end)
                        @finch (res .= 0; for j=_, i=_; res[i, j] = tmp[i, j] end)
                        @test Structure(ref) == Structure(res)
                    end
                end
            end
        end

        for inner in [
            () -> SparseTriangle{1}(base()),
            () -> SparseRLE(base()),
        ]
            for arr in [
                fill(false, 5),
                fill(true, 5),
                [false, true, true, false, false, true]
            ]
                ref = Fiber!(SparseList(Element(false)))
                res = Fiber!(SparseList(Element(false)))
                tmp = Fiber!(inner())
                @testset "convert $(summary(tmp))" begin
                    @finch (ref .= 0; for i=_; ref[i] = arr[i] end)
                    @finch (tmp .= 0; for i=_; tmp[i] = ref[i] end)
                    @finch (res .= 0; for i=_; res[i] = tmp[i] end)
                    @test Structure(ref) == Structure(res)
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
                    ref = Fiber!(SparseList(SparseList(Element(false))))
                    res = Fiber!(SparseList(SparseList(Element(false))))
                    tmp = Fiber!(outer())
                    @testset "convert $arr_key $(summary(tmp))"  begin
                        @finch (ref .= 0; for j=_, i=_; ref[i, j] = arr[i, j] end)
                        @finch (tmp .= 0; for j=_, i=_; tmp[i, j] = ref[i, j] end)
                        @finch (res .= 0; for j=_, i=_; res[i, j] = tmp[i, j] end)
                        @test Structure(ref) == Structure(res)
                    end
                end
            end
        end


        for outer in [
            () -> SparseCOO{2}(base()),
            () -> SparseHash{2}(base()),
            () -> SparseRLE(SparseRLE(base())),
        ]

            for (arr_key, arr) in [
                ("5x5_falses", fill(false, 5, 5)),
                ("5x5_trues", fill(true, 5, 5)),
                ("4x4_bool_mix", [false true  false true ;
                false false false false
                true  true  true  true
                false true  false true ])
            ]
                ref = Fiber!(SparseList(SparseList(Element(false))))
                res = Fiber!(SparseList(SparseList(Element(false))))
                ref = dropdefaults!(ref, arr)
                tmp = Fiber!(outer())
                @testset "convert $arr_key $(summary(tmp))"  begin
                    @finch (tmp .= 0; for j=_, i=_; tmp[i, j] = ref[i, j] end)
                    @finch (res .= 0; for j=_, i=_; res[i, j] = tmp[i, j] end)
                    @test Structure(ref) == Structure(res)
                end
            end
        end

        for outer in [
            () -> SparseTriangle{2}(base()),
            () -> SparseRLE(SparseRLE(base())),
        ]

            for (arr_key, arr) in [
                ("5x5_falses", fill(false, 5, 5)),
                ("5x5_trues", fill(true, 5, 5)),
                ("4x4_bool_mix", [false true  false true ;
                false false false false
                true  true  true  true
                false true  false true ])
            ]
                ref = Fiber!(SparseList(SparseList(Element(false))))
                res = Fiber!(SparseList(SparseList(Element(false))))
                ref = dropdefaults!(ref, arr)
                tmp = Fiber!(outer())
                @testset "convert $arr_key $(summary(tmp))"  begin
                    @finch (tmp .= 0; for j=_, i=_; tmp[i, j] = ref[i, j] end)
                    @finch (res .= 0; for j=_, i=_; res[i, j] = tmp[i, j] end)
                    check = Scalar(true)
                    @finch for j=_, i=_; if j >= i check[] &= tmp[i, j] == ref[i, j] end end
                    @test check[]
                end
            end
        end
    end
end
