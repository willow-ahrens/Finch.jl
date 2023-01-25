using Finch
using .Iterators

open("test_constructors.jl", "w") do file

    println(file, "@testset \"constructors\" begin")

    function test_outer_constructor(arr, ctrs, argss)

        println(file, "    @testset \"$(first(ctrs)) constructors\" begin")
        ref = dropdefaults!(Fiber(first(ctrs)(Element(zero(eltype(arr))))), arr)

        println(file, "        ref = Fiber($(repr(ref.lvl)), Environment())")

        for ctr in ctrs
            println(file, "        res = Fiber($(ctr)($(join(map(repr, argss[1](ref.lvl)), ", "))), Environment())")
            println(file, "        @test isstructequal(res, ref)")
            for args in argss[2:end]
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
        [0.0, 2.0, 2.0, 0.0, 3.0, 3.0],
        begin
            x = zeros(1111)
            x[2] = 20.0
            x[3]=30.0
            x[555]=5550.0
            x[666]=6660.0
            x
        end,
    ]

        if length(arr) < 100
            for ctrs = [
                [Dense, Dense{Int}],
                [Dense{Int16}],
            ]
                argss = []
                push!(argss, lvl -> (lvl.I, lvl.lvl,))
                length(arr) == 0 && push!(argss, lvl -> (lvl.lvl,))
                test_outer_constructor(arr, ctrs, argss)
            end
        end

        for ctrs = [
            [SparseList, SparseList{Int}, SparseList{Int, Int}],
            [SparseList{Int16}, SparseList{Int16, Int}],
            [SparseList{Int16, Int16},],
            [SparseVBL, SparseVBL{Int}, SparseVBL{Int, Int}],
            [SparseVBL{Int16}, SparseVBL{Int16, Int}],
            [SparseVBL{Int16, Int16},],
            #[SparseBytemap, SparseBytemap{Int}, SparseBytemap{Int, Int}],
            #[SparseBytemap{Int16}, SparseBytemap{Int16, Int}],
            #[SparseBytemap{Int16, Int16},],
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
            [SparseCoo{N, NTuple{N, Int16}}],
        ]
            argss = []
            push!(argss, lvl -> map(name -> getproperty(lvl, name), propertynames(lvl)))
            all(iszero, arr) && push!(argss, lvl -> (lvl.I, lvl.lvl,))
            length(arr) == 0 && push!(argss, lvl -> (lvl.lvl,))
            test_outer_constructor(arr, ctrs, argss)
        end

        for ctrs = [
            [SparseHash{N}, SparseHash{N, NTuple{N, Int}}, SparseHash{N, NTuple{N, Int}, Int}, SparseHash{N, NTuple{N, Int}, Int, Dict{Tuple{Int, NTuple{N, Int}}, Int}}],
            [SparseHash{N, NTuple{N, Int16}}, SparseHash{N, NTuple{N, Int16}, Int}, SparseHash{N, NTuple{N, Int16}, Int, Dict{Tuple{Int, NTuple{N, Int16}}, Int}}],
            [SparseHash{N, NTuple{N, Int16}, Int16}, SparseHash{N, NTuple{N, Int16}, Int16, Dict{Tuple{Int16, NTuple{N, Int16}}, Int16}}],
            [SparseHash{N, NTuple{N, Int16}, Int16, Dict{Tuple{Int16, NTuple{N, Int16}}, Int16}}],
        ]
            argss = []
            push!(argss, lvl -> map(name -> getproperty(lvl, name), propertynames(lvl)))
            all(iszero, arr) && push!(argss, lvl -> (lvl.I, lvl.lvl,))
            all(iszero, arr) && push!(argss, lvl -> (lvl.I, lvl.tbl, lvl.lvl,))
            length(arr) == 0 && push!(argss, lvl -> (lvl.lvl,))
            test_outer_constructor(arr, ctrs, argss)
        end
    end

    function test_inner_constructor(arr, ctrs, argss, prefix...)

        println(file, "    @testset \"$(first(ctrs)) constructors\" begin")
        ref = dropdefaults!(Fiber(first(ctrs)(prefix...)), arr)

        println(file, "        ref = Fiber($(repr(ref.lvl)), Environment())")

        for ctr in ctrs
            println(file, "        res = Fiber($(ctr)($(join(map(repr, argss[1](ref.lvl)), ", "))), Environment())")
            println(file, "        @test isstructequal(res, ref)")
            for args in argss[2:end]
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
        [0.0, 2.0, 2.0, 0.0, 3.0, 3.0],
    ]

        D = zero(eltype(arr))
        for ctrs = [
            #[RepeatRLE{D}, RepeatRLE{D, Int}, RepeatRLE{D, Int, Int}, RepeatRLE{D, Int, Int, typeof(D)}],
            #[RepeatRLE{D, Int16}, RepeatRLE{D, Int16, Int}, RepeatRLE{D, Int16, Int, typeof(D)}],
            #[RepeatRLE{D, Int16, Int16}, RepeatRLE{D, Int16, Int16, typeof(D)}],
            #[RepeatRLE{D, Int16, Int16, Any}],
        ]
            argss = []
            push!(argss, lvl -> map(name -> getproperty(lvl, name), propertynames(lvl)))
            all(iszero, arr) && push!(argss, lvl -> (lvl.I, ))
            length(arr) == 0 && push!(argss, lvl -> ())
            test_inner_constructor(arr, ctrs, argss)
        end

        for ctrs = [
            #[RepeatRLE],
        ]
            argss = []
            push!(argss, lvl -> (D, map(name -> getproperty(lvl, name), propertynames(lvl))...))
            all(iszero, arr) && push!(argss, lvl -> (D, lvl.I, ))
            length(arr) == 0 && push!(argss, lvl -> (D,))
            test_inner_constructor(arr, ctrs, argss, D)
        end
    end

    for arr in [
        fill(false),
        fill(true),
        fill(0.0),
        fill(1.0),
    ]

        D = zero(eltype(arr))
        ctrss = [
            [Element{D}, Element{D, typeof(D)}],
            [Element{D, Any}],
        ]
        eltype(arr) == Bool && push!(ctrss, [[Pattern,],])
        for ctrs in ctrss
            argss = []
            push!(argss, lvl -> map(name -> getproperty(lvl, name), propertynames(lvl)))
            all(iszero, arr) && push!(argss, lvl -> ())
            test_inner_constructor(arr, ctrs, argss)
        end

        D = zero(eltype(arr))
        for ctrs in [
            [Element],
        ]
            argss = []
            push!(argss, lvl -> (D, map(name -> getproperty(lvl, name), propertynames(lvl))...))
            all(iszero, arr) && push!(argss, lvl -> (D, ))
            test_inner_constructor(arr, ctrs, argss, D)
        end
    end

    println(file, "end")
end