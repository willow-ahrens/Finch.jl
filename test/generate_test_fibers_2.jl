using Finch
using .Iterators

lvls = [
    (ndims = 1, ctr = Dense),
    (ndims = 1, ctr = Dense{Int}),
    (ndims = 1, ctr = Dense{Int8}),
    (ndims = 1, ctr = SparseList),
    (ndims = 1, ctr = SparseList{Int}),
    (ndims = 1, ctr = SparseList{Int8}),
    (ndims = 1, ctr = SparseVBL),
    (ndims = 1, ctr = SparseVBL{Int}),
    (ndims = 1, ctr = SparseVBL{Int8}),
    flatten([[
        (ndims = n, ctr = SparseCoo{n}),
        (ndims = n, ctr = SparseCoo{n, NTuple{n,Int}}),
        (ndims = n, ctr = SparseCoo{n, NTuple{n, Int8}}),
        (ndims = n, ctr = SparseCoo{n, NTuple{n, Int}, Int}),
        (ndims = n, ctr = SparseCoo{n, NTuple{n, Int8}, Int8}),
        (ndims = n, ctr = SparseHash{n}),
        (ndims = n, ctr = SparseHash{n, NTuple{n, Int}}),
        (ndims = n, ctr = SparseHash{n, NTuple{n, Int8}}),
        (ndims = n, ctr = SparseHash{n, NTuple{n, Int}, Int}),
        (ndims = n, ctr = SparseHash{n, NTuple{n, Int8}, Int8}),
        (ndims = n, ctr = SparseHash{n, NTuple{n, Int}, Int, Dict{Tuple{Int, NTuple{n, Int}}, Int}}),
    ] for n = 1:3])...,
]

lvls = map(args -> merge(args...), product([
    (args = (lvl,) -> (lvl.lvl,),)
    (args = (lvl,) -> (lvl.I, lvl.lvl),)
    (args = (lvl,) -> map(name -> getproperty(lvl, name), propertynames(lvl)),)
], lvls))

cores = [
    (eltype = Bool, ndims = 0, ctr = Element{false}),
    (eltype = Bool, ndims = 0, ctr = Element{true}),
    (eltype = Bool, ndims = 0, ctr = Pattern),
    (eltype = Float64, ndims = 0, ctr = Element{0.0}),
    (eltype = Float64, ndims = 0, ctr = Element{1.0}),
    (eltype = Float64, ndims = 1, ctr = RepeatRLE{0.0}),
    (eltype = Float64, ndims = 1, ctr = RepeatRLE{0.0, Int}),
    (eltype = Float64, ndims = 1, ctr = RepeatRLE{0.0, Int8}),
    (eltype = Float64, ndims = 1, ctr = RepeatRLE{1.0}),
    (eltype = Float64, ndims = 1, ctr = RepeatRLE{1.0, Int}),
    (eltype = Float64, ndims = 1, ctr = RepeatRLE{1.0, Int, Int8}),
]

cores = map(args -> merge(args...), product([
    (args = (ref,) -> (),)
    (args = (ref,) -> map(name -> getproperty(ref, name), propertynames(ref)),)
], cores))

open("test_fibers_2_test.jl", "w") do file
    seen = Set()
    for arr in [
        Bool[],
        [false, true, false, true, false, false],
        [true  true  true  true;
        false false false false;
        false true  false false],
        Float64[], 
        [0.0, 0.2, 0.0, 0.0, 0.3, 0.4],
        [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        [0.1, 0.1, 0.2, 0.2, 0.2, 0.3],
        [1.0 0.0;
        0.0 0.1],
        [3.0 2.0 1.0;
        0.0 0.0 0.0],
        [0.0 0.0 0.0;
        0.0 0.0 1.0;
        0.0 0.0 0.0],
    ]
        mycores = filter(core -> core.eltype == eltype(arr), cores)
        fmts = collect(flatten([
            product(lvls, lvls, lvls, mycores),
            product(lvls, lvls, mycores),
            product(lvls, mycores),
            product(mycores)
        ]))
        fmts = filter(fmt -> sum(lvl -> lvl.ndims, fmt) == ndims(arr), fmts)
        fmts = filter(fmt -> any(lvl -> !(lvl in seen), fmt), fmts)
        for fmt in fmts
            try
                ref = dropdefaults!(Fiber(foldr((lvl, args) -> (lvl.ctr(args...),), fmt, init = ())...), arr)
                function printres!(ref, lvl, lvls...)
                    print(file, "    $(lvl.ctr)(")
                    args = lvl.args(ref)
                    for arg in args[1:end - 1]
                        print(file, "$(arg), ")
                    end
                    println(file)
                    printres!(args[end], lvls...)
                    print(file, ")")
                end
                function printres!(ref, lvl)
                    print(file, "    $(lvl.ctr)(")
                    for arg in lvl.args(ref)
                        println(file, "$(arg), ")
                    end
                    print(file, ")")
                end
                println(file, "res = Fiber(")
                printres!(ref.lvl, fmt...)
                println(file, ")")
                print(file, "ref = ")
                show(IOContext(file, :compact=>false), ref)
                println(file)
            catch
            end
        end
    end
end