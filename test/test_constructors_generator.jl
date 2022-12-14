using Finch
using .Iterators

open("test_constructors.jl", "w") do file

    println(file, "@testset \"constructors\" begin")

    function test_outer_constructor(arr, ctrs, argss)

        println(file, "    @testset \"$(first(ctrs)) constructors\" begin")
        ref = dropdefaults!(Fiber(first(ctrs)(Element(zero(eltype(arr))))), arr)

        println(file, "        ref = Fiber($(repr(ref.lvl)))")

        for ctr in ctrs
            for args in argss
                println(file, "        res = Fiber($(ctr)($(join(map(repr, args(ref.lvl)), ", "))))")
                println(file, "        @test isstructequal(res, ref)")
            end
        end
        println(file, "    end")
    end

    for arr in [
        Vector{Bool}(),
        [false, false, false, false],
        [false, true, false, true, false, false],
        Vector{Float64}(),
        [0.0, 0.0, 0.0, 0.0],
        [0.0, 0.2, 0.0, 0.0, 0.3, 0.4],
    ]

        for ctrs = [
            [Dense, Dense{Int}],
            [Dense{Int8}],
        ]
            argss = []
            push!(argss, lvl -> (lvl.I, lvl.lvl,))
            length(arr) == 0 && push!(argss, lvl -> (lvl.lvl,))
            test_outer_constructor(arr, ctrs, argss)
        end
        for ctrs = [
            [SparseList, SparseList{Int}],
            [SparseList{Int8}],
            [SparseVBL, SparseVBL{Int}],
            [SparseVBL{Int8}],
        ]
            argss = []
            push!(argss, lvl -> map(name -> getproperty(lvl, name), propertynames(lvl)))
            all(iszero, arr) && push!(argss, lvl -> (lvl.I, lvl.lvl,))
            length(arr) == 0 && push!(argss, lvl -> (lvl.lvl,))
            test_outer_constructor(arr, ctrs, argss)
        end
    end

    println(file, "end")
end