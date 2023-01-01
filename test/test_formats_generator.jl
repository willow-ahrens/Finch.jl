using Finch
using .Iterators

open("test_formats.jl", "w") do file

    println(file, "@testset \"formats\" begin")

    function test_format(arr, fmt)
        ref = dropdefaults!(@eval($fmt), arr)

        println(file, "    arr = $arr")
        println(file, "    ref = $(ref)")
        println(file, "    res = dropdefaults!($fmt, arr)")
        println(file, "    @test isstructequal(res, ref)")
    end

    for base in [
        :(Pattern()),
        :(Element(false)),
        :(Element(true))
    ]
        for arr in [
            fill(false),
            fill(true)
        ]
            test_format(arr, :(Fiber($base)))
        end
        for inner in [
            :(Dense($base)),
            :(SparseList($base)),
            :(SparseListDiff($base)),
            :(SparseVBL($base)),
            :(SparseBytemap($base)),
            :(SparseHash{1}($base)),
            :(SparseCoo{1}($base))
        ]
            for arr in [
                fill(false, 5),
                fill(true, 5),
                [false, true, false, true]
            ]
                test_format(arr, :(Fiber($inner)))
            end

            for outer in [
                :(Dense($inner)),
                :(SparseList($inner)),
            ]

                for arr in [
                    fill(false, 5, 5),
                    fill(true, 5, 5),
                    [false true  false true ;
                    false false false false
                    true  true  true  true
                    false true  false true ]
                ]
                    test_format(arr, :(Fiber($outer)))
                end
            end
        end

        for outer in [
            :(SparseCoo{2}($base)),
            :(SparseHash{2}($base))
        ]
            for arr in [
                fill(false, 5, 5),
                fill(true, 5, 5),
                [false true  false true ;
                false false false false
                true  true  true  true
                false true  false true ]
            ]
                test_format(arr, :(Fiber($outer)))
            end
        end
    end

    println(file, "end")
end