@testset "conversions" begin
    for base in [
        Pattern,
        Element{false},
    ]
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
        for inner in [
            () -> Dense(base()),
            () -> SparseList(base()),
            () -> SparseVBL(base()),
            () -> SparseBytemap(base()),
            () -> SparseHash{1}(base()),
            () -> SparseCoo{1}(base()),
        ]
            for arr in [
                fill(false, 5),
                fill(true, 5),
                [false, true, true, false, false, true]
            ]
                ref = @fiber sl(e(false))
                res = @fiber sl(e(false))
                dropzeros!(ref, arr)
                tmp = Fiber(inner())
                @finch @loop i tmp[i] = ref[i]
                @finch @loop i res[i] = tmp[i]
                @test isstructequal(ref, res)
            end

            for outer in [
                () -> Dense(inner()),
                () -> SparseList(inner()),
                () -> SparseCoo{2}(base()),
                () -> SparseHash{2}(base())
            ]

                for arr in [
                    fill(false, 5, 5),
                    fill(true, 5, 5),
                    [false true  false true ;
                    false false false false
                    true  true  true  true
                    false true  false true ]
                ]
                    ref = @fiber sc{2}(e(false))
                    res = @fiber sc{2}(e(false))
                    dropzeros!(ref, arr)
                    tmp = Fiber(outer())
                    @finch @loop i j tmp[i, j] = ref[i, j]
                    @finch @loop i j res[i, j] = tmp[i, j]
                    @test isstructequal(ref, res)
                end
            end
        end
    end

    println(file, "end")
end