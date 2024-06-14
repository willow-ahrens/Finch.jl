# Sparse Array Utilities

## Sparse Constructors

In addition to the `Tensor` constructor, Finch provides a number of convenience
constructors for common tensor types. For example, the `spzeros` and `sprand` functions
have `fspzeros` and `fsprand` counterparts that return Finch tensors. We can also construct
a sparse COO `Tensor` from a list of indices and values using the `fsparse` function.

```@docs
fsparse
fsparse!
fsprand
fspzeros
ffindnz
```

## Fill Values

Finch tensors support an arbitrary "background" value for sparse arrays. While most arrays use `0` as the background value, this is not always the case. For example, a sparse array of `Int` might use `typemin(Int)` as the background value. The `default` function returns the background value of a tensor. If you ever want to change the background value of an existing array, you can use the `set_fill_value!` function. The `countstored` function returns the number of stored elements in a tensor, and calling `pattern!` on a tensor returns tensor which is true whereever the original tensor stores a value. Note that countstored doesn't always return the number of non-zero elements in a tensor, as it counts the number of stored elements, and stored elements may include the background value. You can call `dropfills!` to remove explicitly stored background values from a tensor.

```jldoctest example1; setup = :(using Finch)
julia> A = fsparse([1, 1, 2, 3], [2, 4, 5, 6], [1.0, 2.0, 3.0])
3×6-Tensor
└─ SparseCOO{2} (0.0) [:,1:6]
   ├─ [1, 2]: 1.0
   ├─ [1, 4]: 2.0
   └─ [2, 5]: 3.0

julia> min.(A, -1)
3×6-Tensor
└─ Dense [:,1:6]
   ├─ [:, 1]: Dense [1:3]
   │  ├─ [1]: -1.0
   │  ├─ [2]: -1.0
   │  └─ [3]: -1.0
   ├─ [:, 2]: Dense [1:3]
   │  ├─ [1]: -1.0
   │  ├─ [2]: -1.0
   │  └─ [3]: -1.0
   ├─ ⋮
   ├─ [:, 5]: Dense [1:3]
   │  ├─ [1]: -1.0
   │  ├─ [2]: -1.0
   │  └─ [3]: -1.0
   └─ [:, 6]: Dense [1:3]
      ├─ [1]: -1.0
      ├─ [2]: -1.0
      └─ [3]: -1.0

julia> fill_value(A)
0.0

julia> B = set_fill_value!(A, -Inf)
3×6-Tensor
└─ SparseCOO{2} (-Inf) [:,1:6]
   ├─ [1, 2]: 1.0
   ├─ [1, 4]: 2.0
   └─ [2, 5]: 3.0

julia> min.(B, -1)
ERROR: UndefVarError: `SparseDict` not defined
Stacktrace:
  [1] construct_level_rep(::Finch.SparseData, ::Nothing)
    @ Finch ~/Projects/Finch.jl/src/interface/traits.jl:404
  [2] construct_level_rep(fbr::Finch.SparseData, proto::Nothing, protos::Nothing)
    @ Finch ~/Projects/Finch.jl/src/interface/traits.jl:404
  [3] rep_construct(fbr::Finch.SparseData, protos::Vector{Nothing})
    @ Finch ~/Projects/Finch.jl/src/interface/traits.jl:402
  [4] rep_construct(fbr::Finch.SparseData)
    @ Finch ~/Projects/Finch.jl/src/interface/traits.jl:396
  [5] format_queries(node::Finch.FinchLogic.LogicNode, defer::Bool, bindings::Dict{Any, Any})
    @ Finch ~/Projects/Finch.jl/src/scheduler/optimize.jl:338
  [6] #1758
    @ ~/Projects/Finch.jl/src/scheduler/optimize.jl:331 [inlined]
  [7] iterate
    @ ./generator.jl:47 [inlined]
  [8] collect_to!
    @ ./array.jl:892 [inlined]
  [9] collect_to_with_first!
    @ ./array.jl:870 [inlined]
 [10] _collect(c::SubArray{Finch.FinchLogic.LogicNode, 1, Vector{Finch.FinchLogic.LogicNode}, Tuple{UnitRange{Int64}}, true}, itr::Base.Generator{SubArray{Finch.FinchLogic.LogicNode, 1, Vector{Finch.FinchLogic.LogicNode}, Tuple{UnitRange{Int64}}, true}, Finch.var"#1758#1759"{Bool, Dict{Any, Any}}}, ::Base.EltypeUnknown, isz::Base.HasShape{1})
    @ Base ./array.jl:864
 [11] collect_similar(cont::SubArray{Finch.FinchLogic.LogicNode, 1, Vector{Finch.FinchLogic.LogicNode}, Tuple{UnitRange{Int64}}, true}, itr::Base.Generator{SubArray{Finch.FinchLogic.LogicNode, 1, Vector{Finch.FinchLogic.LogicNode}, Tuple{UnitRange{Int64}}, true}, Finch.var"#1758#1759"{Bool, Dict{Any, Any}}})
    @ Base ./array.jl:763
 [12] map(f::Function, A::SubArray{Finch.FinchLogic.LogicNode, 1, Vector{Finch.FinchLogic.LogicNode}, Tuple{UnitRange{Int64}}, true})
    @ Base ./abstractarray.jl:3285
 [13] format_queries(node::Finch.FinchLogic.LogicNode, defer::Bool, bindings::Dict{Any, Any})
    @ Finch ~/Projects/Finch.jl/src/scheduler/optimize.jl:330
 [14] format_queries
    @ ~/Projects/Finch.jl/src/scheduler/optimize.jl:329 [inlined]
 [15] (::Finch.LogicCompiler)(prgm::Finch.FinchLogic.LogicNode)
    @ Finch ~/Projects/Finch.jl/src/scheduler/LogicCompiler.jl:189
 [16] (::Finch.DefaultLogicOptimizer)(prgm::Finch.FinchLogic.LogicNode)
    @ Finch ~/Projects/Finch.jl/src/scheduler/optimize.jl:599
 [17] (::Finch.var"#1662#1663"{Finch.DefaultLogicOptimizer})(ctx_3::Finch.JuliaContext)
    @ Finch ~/Projects/Finch.jl/src/scheduler/LogicExecutor.jl:43
 [18] contain(f::Finch.var"#1662#1663"{Finch.DefaultLogicOptimizer}, ctx::Finch.JuliaContext; task::Nothing)
    @ Finch ~/Projects/Finch.jl/src/environment.jl:116
 [19] contain
    @ ~/Projects/Finch.jl/src/environment.jl:111 [inlined]
 [20] logic_executor_code(ctx::Finch.DefaultLogicOptimizer, prgm::Finch.FinchLogic.LogicNode)
    @ Finch ~/Projects/Finch.jl/src/scheduler/LogicExecutor.jl:40
 [21] (::Finch.var"#1666#1667"{Finch.LogicExecutor, Finch.FinchLogic.LogicNode})()
    @ Finch ~/Projects/Finch.jl/src/scheduler/LogicExecutor.jl:72
 [22] get!(default::Finch.var"#1666#1667"{Finch.LogicExecutor, Finch.FinchLogic.LogicNode}, h::Dict{Any, Any}, key::Finch.FinchLogic.LogicNode)
    @ Base ./dict.jl:479
 [23] (::Finch.LogicExecutor)(prgm::Finch.FinchLogic.LogicNode)
    @ Finch ~/Projects/Finch.jl/src/scheduler/LogicExecutor.jl:71
 [24] compute_parse(ctx::Finch.LogicExecutor, args::Tuple{Finch.LazyTensor{Float64, 2}})
    @ Finch ~/Projects/Finch.jl/src/interface/lazy.jl:502
 [25] compute(arg::Finch.LazyTensor{Float64, 2}; ctx::Finch.LogicExecutor, kwargs::@Kwargs{})
    @ Finch ~/Projects/Finch.jl/src/interface/lazy.jl:494
 [26] copy
    @ ~/Projects/Finch.jl/src/interface/eager.jl:21 [inlined]
 [27] materialize(bc::Base.Broadcast.Broadcasted{Finch.FinchStyle{2}, Nothing, typeof(min), Tuple{Tensor{SparseCOOLevel{2, Tuple{Int64, Int64}, Vector{Int64}, Tuple{Vector{Int64}, Vector{Int64}}, ElementLevel{-Inf, Float64, Int64, Vector{Float64}}}}, Int64}})
    @ Base.Broadcast ./broadcast.jl:903
 [28] top-level scope
    @ none:1

julia> countstored(A)
3

julia> pattern!(A)
3×6-Tensor
└─ SparseCOO{2} (false) [:,1:6]
   ├─ [1, 2]: true
   ├─ [1, 4]: true
   └─ [2, 5]: true

```

```@docs
set_fill_value!
pattern!
countstored
dropfills
dropfills!
```

### How to tell whether an entry is "fill"

In the sparse world, a semantic distinction is sometimes made between
"explicitly stored" values and "implicit" or "fill" values (usually zero).
However, the formats in the Finch compiler represent a diverse set of structures
beyond sparsity, and it is often unclear whether any of the values in the tensor
are "explicit" (consider a mask matrix, which can be represented with a constant
number of bits). Thus, Finch makes no semantic distinction between values which
are stored explicitly or not. If users wish to make this distinction, they should
instead store a tensor of tuples of the form `(value, is_fill)`. For example,

```jldoctest example3; setup = :(using Finch)
julia> A = fsparse([1, 1, 2, 3], [2, 4, 5, 6], [(1.0, false), (0.0, true), (3.0, false)]; fill_value=(0.0, true))
3×6-Tensor
└─ SparseCOO{2} ((0.0, true)) [:,1:6]
   ├─ [1, 2]: (1.0, false)
   ├─ [1, 4]: (0.0, true)
   └─ [2, 5]: (3.0, false)

julia> B = Tensor(Dense(SparseList(Element((0.0, true)))), A)
3×6-Tensor
└─ Dense [:,1:6]
   ├─ [:, 1]: SparseList ((0.0, true)) [1:3]
   ├─ [:, 2]: SparseList ((0.0, true)) [1:3]
   │  └─ [1]: (1.0, false)
   ├─ ⋮
   ├─ [:, 5]: SparseList ((0.0, true)) [1:3]
   │  └─ [2]: (3.0, false)
   └─ [:, 6]: SparseList ((0.0, true)) [1:3]

julia> sum(map(last, B))
ERROR: UndefVarError: `SparseDict` not defined
Stacktrace:
  [1] construct_level_rep(::Finch.SparseData, ::Nothing)
    @ Finch ~/Projects/Finch.jl/src/interface/traits.jl:404
  [2] construct_level_rep(::Finch.DenseData, ::Nothing, ::Nothing, ::Vararg{Nothing})
    @ Finch ~/Projects/Finch.jl/src/interface/traits.jl:408
  [3] rep_construct(fbr::Finch.DenseData, protos::Vector{Nothing})
    @ Finch ~/Projects/Finch.jl/src/interface/traits.jl:402
  [4] rep_construct(fbr::Finch.DenseData)
    @ Finch ~/Projects/Finch.jl/src/interface/traits.jl:396
  [5] format_queries(node::Finch.FinchLogic.LogicNode, defer::Bool, bindings::Dict{Any, Any})
    @ Finch ~/Projects/Finch.jl/src/scheduler/optimize.jl:338
  [6] #1758
    @ ~/Projects/Finch.jl/src/scheduler/optimize.jl:331 [inlined]
  [7] iterate
    @ ./generator.jl:47 [inlined]
  [8] collect_to!
    @ ./array.jl:892 [inlined]
  [9] collect_to_with_first!
    @ ./array.jl:870 [inlined]
 [10] _collect(c::SubArray{Finch.FinchLogic.LogicNode, 1, Vector{Finch.FinchLogic.LogicNode}, Tuple{UnitRange{Int64}}, true}, itr::Base.Generator{SubArray{Finch.FinchLogic.LogicNode, 1, Vector{Finch.FinchLogic.LogicNode}, Tuple{UnitRange{Int64}}, true}, Finch.var"#1758#1759"{Bool, Dict{Any, Any}}}, ::Base.EltypeUnknown, isz::Base.HasShape{1})
    @ Base ./array.jl:864
 [11] collect_similar(cont::SubArray{Finch.FinchLogic.LogicNode, 1, Vector{Finch.FinchLogic.LogicNode}, Tuple{UnitRange{Int64}}, true}, itr::Base.Generator{SubArray{Finch.FinchLogic.LogicNode, 1, Vector{Finch.FinchLogic.LogicNode}, Tuple{UnitRange{Int64}}, true}, Finch.var"#1758#1759"{Bool, Dict{Any, Any}}})
    @ Base ./array.jl:763
 [12] map(f::Function, A::SubArray{Finch.FinchLogic.LogicNode, 1, Vector{Finch.FinchLogic.LogicNode}, Tuple{UnitRange{Int64}}, true})
    @ Base ./abstractarray.jl:3285
 [13] format_queries(node::Finch.FinchLogic.LogicNode, defer::Bool, bindings::Dict{Any, Any})
    @ Finch ~/Projects/Finch.jl/src/scheduler/optimize.jl:330
 [14] format_queries
    @ ~/Projects/Finch.jl/src/scheduler/optimize.jl:329 [inlined]
 [15] (::Finch.LogicCompiler)(prgm::Finch.FinchLogic.LogicNode)
    @ Finch ~/Projects/Finch.jl/src/scheduler/LogicCompiler.jl:189
 [16] (::Finch.DefaultLogicOptimizer)(prgm::Finch.FinchLogic.LogicNode)
    @ Finch ~/Projects/Finch.jl/src/scheduler/optimize.jl:599
 [17] (::Finch.var"#1662#1663"{Finch.DefaultLogicOptimizer})(ctx_3::Finch.JuliaContext)
    @ Finch ~/Projects/Finch.jl/src/scheduler/LogicExecutor.jl:43
 [18] contain(f::Finch.var"#1662#1663"{Finch.DefaultLogicOptimizer}, ctx::Finch.JuliaContext; task::Nothing)
    @ Finch ~/Projects/Finch.jl/src/environment.jl:116
 [19] contain
    @ ~/Projects/Finch.jl/src/environment.jl:111 [inlined]
 [20] logic_executor_code(ctx::Finch.DefaultLogicOptimizer, prgm::Finch.FinchLogic.LogicNode)
    @ Finch ~/Projects/Finch.jl/src/scheduler/LogicExecutor.jl:40
 [21] (::Finch.var"#1666#1667"{Finch.LogicExecutor, Finch.FinchLogic.LogicNode})()
    @ Finch ~/Projects/Finch.jl/src/scheduler/LogicExecutor.jl:72
 [22] get!(default::Finch.var"#1666#1667"{Finch.LogicExecutor, Finch.FinchLogic.LogicNode}, h::Dict{Any, Any}, key::Finch.FinchLogic.LogicNode)
    @ Base ./dict.jl:479
 [23] (::Finch.LogicExecutor)(prgm::Finch.FinchLogic.LogicNode)
    @ Finch ~/Projects/Finch.jl/src/scheduler/LogicExecutor.jl:71
 [24] compute_parse(ctx::Finch.LogicExecutor, args::Tuple{Finch.LazyTensor{Bool, 2}})
    @ Finch ~/Projects/Finch.jl/src/interface/lazy.jl:502
 [25] compute(arg::Finch.LazyTensor{Bool, 2}; ctx::Finch.LogicExecutor, kwargs::@Kwargs{})
    @ Finch ~/Projects/Finch.jl/src/interface/lazy.jl:494
 [26] copy(bc::Base.Broadcast.Broadcasted{Finch.FinchStyle{2}, Nothing, typeof(last), Tuple{Tensor{DenseLevel{Int64, SparseListLevel{Int64, Vector{Int64}, Vector{Int64}, ElementLevel{(0.0, true), Tuple{Float64, Bool}, Int64, Vector{Tuple{Float64, Bool}}}}}}}})
    @ Finch ~/Projects/Finch.jl/src/interface/eager.jl:21
 [27] materialize
    @ ./broadcast.jl:903 [inlined]
 [28] map(::Function, ::Tensor{DenseLevel{Int64, SparseListLevel{Int64, Vector{Int64}, Vector{Int64}, ElementLevel{(0.0, true), Tuple{Float64, Bool}, Int64, Vector{Tuple{Float64, Bool}}}}}})
    @ Finch ~/Projects/Finch.jl/src/interface/eager.jl:37
 [29] top-level scope
    @ none:1

julia> sum(map(first, B))
ERROR: UndefVarError: `SparseDict` not defined
Stacktrace:
  [1] construct_level_rep(::Finch.SparseData, ::Nothing)
    @ Finch ~/Projects/Finch.jl/src/interface/traits.jl:404
  [2] construct_level_rep(::Finch.DenseData, ::Nothing, ::Nothing, ::Vararg{Nothing})
    @ Finch ~/Projects/Finch.jl/src/interface/traits.jl:408
  [3] rep_construct(fbr::Finch.DenseData, protos::Vector{Nothing})
    @ Finch ~/Projects/Finch.jl/src/interface/traits.jl:402
  [4] rep_construct(fbr::Finch.DenseData)
    @ Finch ~/Projects/Finch.jl/src/interface/traits.jl:396
  [5] format_queries(node::Finch.FinchLogic.LogicNode, defer::Bool, bindings::Dict{Any, Any})
    @ Finch ~/Projects/Finch.jl/src/scheduler/optimize.jl:338
  [6] #1758
    @ ~/Projects/Finch.jl/src/scheduler/optimize.jl:331 [inlined]
  [7] iterate
    @ ./generator.jl:47 [inlined]
  [8] collect_to!
    @ ./array.jl:892 [inlined]
  [9] collect_to_with_first!
    @ ./array.jl:870 [inlined]
 [10] _collect(c::SubArray{Finch.FinchLogic.LogicNode, 1, Vector{Finch.FinchLogic.LogicNode}, Tuple{UnitRange{Int64}}, true}, itr::Base.Generator{SubArray{Finch.FinchLogic.LogicNode, 1, Vector{Finch.FinchLogic.LogicNode}, Tuple{UnitRange{Int64}}, true}, Finch.var"#1758#1759"{Bool, Dict{Any, Any}}}, ::Base.EltypeUnknown, isz::Base.HasShape{1})
    @ Base ./array.jl:864
 [11] collect_similar(cont::SubArray{Finch.FinchLogic.LogicNode, 1, Vector{Finch.FinchLogic.LogicNode}, Tuple{UnitRange{Int64}}, true}, itr::Base.Generator{SubArray{Finch.FinchLogic.LogicNode, 1, Vector{Finch.FinchLogic.LogicNode}, Tuple{UnitRange{Int64}}, true}, Finch.var"#1758#1759"{Bool, Dict{Any, Any}}})
    @ Base ./array.jl:763
 [12] map(f::Function, A::SubArray{Finch.FinchLogic.LogicNode, 1, Vector{Finch.FinchLogic.LogicNode}, Tuple{UnitRange{Int64}}, true})
    @ Base ./abstractarray.jl:3285
 [13] format_queries(node::Finch.FinchLogic.LogicNode, defer::Bool, bindings::Dict{Any, Any})
    @ Finch ~/Projects/Finch.jl/src/scheduler/optimize.jl:330
 [14] format_queries
    @ ~/Projects/Finch.jl/src/scheduler/optimize.jl:329 [inlined]
 [15] (::Finch.LogicCompiler)(prgm::Finch.FinchLogic.LogicNode)
    @ Finch ~/Projects/Finch.jl/src/scheduler/LogicCompiler.jl:189
 [16] (::Finch.DefaultLogicOptimizer)(prgm::Finch.FinchLogic.LogicNode)
    @ Finch ~/Projects/Finch.jl/src/scheduler/optimize.jl:599
 [17] (::Finch.var"#1662#1663"{Finch.DefaultLogicOptimizer})(ctx_3::Finch.JuliaContext)
    @ Finch ~/Projects/Finch.jl/src/scheduler/LogicExecutor.jl:43
 [18] contain(f::Finch.var"#1662#1663"{Finch.DefaultLogicOptimizer}, ctx::Finch.JuliaContext; task::Nothing)
    @ Finch ~/Projects/Finch.jl/src/environment.jl:116
 [19] contain
    @ ~/Projects/Finch.jl/src/environment.jl:111 [inlined]
 [20] logic_executor_code(ctx::Finch.DefaultLogicOptimizer, prgm::Finch.FinchLogic.LogicNode)
    @ Finch ~/Projects/Finch.jl/src/scheduler/LogicExecutor.jl:40
 [21] (::Finch.var"#1666#1667"{Finch.LogicExecutor, Finch.FinchLogic.LogicNode})()
    @ Finch ~/Projects/Finch.jl/src/scheduler/LogicExecutor.jl:72
 [22] get!(default::Finch.var"#1666#1667"{Finch.LogicExecutor, Finch.FinchLogic.LogicNode}, h::Dict{Any, Any}, key::Finch.FinchLogic.LogicNode)
    @ Base ./dict.jl:479
 [23] (::Finch.LogicExecutor)(prgm::Finch.FinchLogic.LogicNode)
    @ Finch ~/Projects/Finch.jl/src/scheduler/LogicExecutor.jl:71
 [24] compute_parse(ctx::Finch.LogicExecutor, args::Tuple{Finch.LazyTensor{Float64, 2}})
    @ Finch ~/Projects/Finch.jl/src/interface/lazy.jl:502
 [25] compute(arg::Finch.LazyTensor{Float64, 2}; ctx::Finch.LogicExecutor, kwargs::@Kwargs{})
    @ Finch ~/Projects/Finch.jl/src/interface/lazy.jl:494
 [26] copy(bc::Base.Broadcast.Broadcasted{Finch.FinchStyle{2}, Nothing, typeof(first), Tuple{Tensor{DenseLevel{Int64, SparseListLevel{Int64, Vector{Int64}, Vector{Int64}, ElementLevel{(0.0, true), Tuple{Float64, Bool}, Int64, Vector{Tuple{Float64, Bool}}}}}}}})
    @ Finch ~/Projects/Finch.jl/src/interface/eager.jl:21
 [27] materialize
    @ ./broadcast.jl:903 [inlined]
 [28] map(::Function, ::Tensor{DenseLevel{Int64, SparseListLevel{Int64, Vector{Int64}, Vector{Int64}, ElementLevel{(0.0, true), Tuple{Float64, Bool}, Int64, Vector{Tuple{Float64, Bool}}}}}})
    @ Finch ~/Projects/Finch.jl/src/interface/eager.jl:37
 [29] top-level scope
    @ none:1

```