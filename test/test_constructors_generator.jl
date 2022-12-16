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
            [SparseList, SparseList{Int}, SparseList{Int, Int}],
            [SparseList{Int8}, SparseList{Int8, Int}],
            [SparseList{Int8, Int8},],
            [SparseVBL, SparseVBL{Int}, SparseVBL{Int, Int}],
            [SparseVBL{Int8}, SparseVBL{Int8, Int}],
            [SparseVBL{Int8, Int8},],
            [SparseBytemap, SparseBytemap{Int}, SparseBytemap{Int, Int}],
            [SparseBytemap{Int8}, SparseBytemap{Int8, Int}],
            [SparseBytemap{Int8, Int8},],
        ]
            argss = []
            push!(argss, lvl -> map(name -> getproperty(lvl, name), propertynames(lvl)))
            all(iszero, arr) && push!(argss, lvl -> (lvl.I, lvl.lvl,))
            length(arr) == 0 && push!(argss, lvl -> (lvl.lvl,))
            test_outer_constructor(arr, ctrs, argss)
        end
    end


    for arr in [
        Bool[],
        Bool[;;],
        Bool[;;;],
        [false, false, false, false],
        [false false false; false false false],
        [false false false; false false false;;; false false false; false false false ],
        [false, true, false, false],
        [false false false; true false false],
        [false false false; false true false;;; false false false; false false true ],
        Float64[],
        Float64[;;],
        Float64[;;;],
        [0.0, 0.0, 0.0, 0.0],
        [0.0 0.0 0.0; 0.0 0.0 0.0],
        [0.0 0.0 0.0; 0.0 0.0 0.0;;; 0.0 0.0 0.0; 0.0 0.0 0.0 ],
        [0.0, 2.0, 0.0, 0.0],
        [0.0 0.0 0.0; 3.0 0.0 0.0],
        [0.0 0.0 0.0; 0.0 4.0 0.0;;; 0.0 0.0 0.0; 0.0 0.0 5.0 ],
    ]

        N = ndims(arr)
        for ctrs = [
            [SparseCoo{N}, SparseCoo{N, NTuple{N, Int}}],
            [SparseCoo{N, NTuple{N, Int8}}],
        ]
            argss = []
            push!(argss, lvl -> map(name -> getproperty(lvl, name), propertynames(lvl)))
            all(iszero, arr) && push!(argss, lvl -> (lvl.I, lvl.lvl,))
            length(arr) == 0 && push!(argss, lvl -> (lvl.lvl,))
            test_outer_constructor(arr, ctrs, argss)
        end

        for ctrs = [
            [SparseHash{N}, SparseHash{N, NTuple{N, Int}}, SparseHash{N, NTuple{N, Int}, Int}, SparseHash{N, NTuple{N, Int}, Int, Dict{Tuple{Int, NTuple{N, Int}}, Int}}],
            [SparseHash{N, NTuple{N, Int8}}, SparseHash{N, NTuple{N, Int8}, Int}, SparseHash{N, NTuple{N, Int8}, Int, Dict{Tuple{Int, NTuple{N, Int8}}, Int}}],
            [SparseHash{N, NTuple{N, Int8}, Int8}, SparseHash{N, NTuple{N, Int8}, Int8, Dict{Tuple{Int8, NTuple{N, Int8}}, Int8}}],
            [SparseHash{N, NTuple{N, Int8}, Int8, Dict{Tuple{Int8, NTuple{N, Int8}}, Int8}}],
        ]
            argss = []
            push!(argss, lvl -> map(name -> getproperty(lvl, name), propertynames(lvl)))
            all(iszero, arr) && push!(argss, lvl -> (lvl.I, lvl.lvl,))
            all(iszero, arr) && push!(argss, lvl -> (lvl.I, lvl.tbl, lvl.lvl,))
            length(arr) == 0 && push!(argss, lvl -> (lvl.lvl,))
            test_outer_constructor(arr, ctrs, argss)
        end
    end

    for arr in [
        Bool[],
        Bool[;;],
        Bool[;;;],
        [false, false, false, false],
        [false false false; false false false],
        [false false false; false false false;;; false false false; false false false ],
        [false, true, false, false],
        [false false false; true false false],
        [false false false; false true false;;; false false false; false false true ],
        Float64[],
        Float64[;;],
        Float64[;;;],
        [0.0, 0.0, 0.0, 0.0],
        [0.0 0.0 0.0; 0.0 0.0 0.0],
        [0.0 0.0 0.0; 0.0 0.0 0.0;;; 0.0 0.0 0.0; 0.0 0.0 0.0 ],
        [0.0, 2.0, 0.0, 0.0],
        [0.0 0.0 0.0; 3.0 0.0 0.0],
        [0.0 0.0 0.0; 0.0 4.0 0.0;;; 0.0 0.0 0.0; 0.0 0.0 5.0 ],
    ]

    println(file, "end")
end