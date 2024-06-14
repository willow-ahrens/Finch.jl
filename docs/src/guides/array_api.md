```@meta
CurrentModule = Finch
```

# High-Level Array API

Finch tensors also support many of the basic array operations one might expect,
including indexing, slicing, and elementwise maps, broadcast, and reduce.
For example:

```jldoctest example1; setup = :(using Finch)
julia> A = fsparse([1, 1, 2, 3], [2, 4, 5, 6], [1.0, 2.0, 3.0])
3×6-Tensor
└─ SparseCOO{2} (0.0) [:,1:6]
   ├─ [1, 2]: 1.0
   ├─ [1, 4]: 2.0
   └─ [2, 5]: 3.0

julia> A + 0
3×6-Tensor
└─ Dense [:,1:6]
   ├─ [:, 1]: Dense [1:3]
   │  ├─ [1]: 0.0
   │  ├─ [2]: 0.0
   │  └─ [3]: 0.0
   ├─ [:, 2]: Dense [1:3]
   │  ├─ [1]: 1.0
   │  ├─ [2]: 0.0
   │  └─ [3]: 0.0
   ├─ ⋮
   ├─ [:, 5]: Dense [1:3]
   │  ├─ [1]: 0.0
   │  ├─ [2]: 3.0
   │  └─ [3]: 0.0
   └─ [:, 6]: Dense [1:3]
      ├─ [1]: 0.0
      ├─ [2]: 0.0
      └─ [3]: 0.0

julia> A + 1
3×6-Tensor
└─ Dense [:,1:6]
   ├─ [:, 1]: Dense [1:3]
   │  ├─ [1]: 1.0
   │  ├─ [2]: 1.0
   │  └─ [3]: 1.0
   ├─ [:, 2]: Dense [1:3]
   │  ├─ [1]: 2.0
   │  ├─ [2]: 1.0
   │  └─ [3]: 1.0
   ├─ ⋮
   ├─ [:, 5]: Dense [1:3]
   │  ├─ [1]: 1.0
   │  ├─ [2]: 4.0
   │  └─ [3]: 1.0
   └─ [:, 6]: Dense [1:3]
      ├─ [1]: 1.0
      ├─ [2]: 1.0
      └─ [3]: 1.0

julia> B = A .* 2
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
 [27] materialize(bc::Base.Broadcast.Broadcasted{Finch.FinchStyle{2}, Nothing, typeof(*), Tuple{Tensor{SparseCOOLevel{2, Tuple{Int64, Int64}, Vector{Int64}, Tuple{Vector{Int64}, Vector{Int64}}, ElementLevel{0.0, Float64, Int64, Vector{Float64}}}}, Int64}})
    @ Base.Broadcast ./broadcast.jl:903
 [28] top-level scope
    @ none:1

julia> B[1:2, 1:2]
ERROR: UndefVarError: `B` not defined
Stacktrace:
 [1] top-level scope
   @ none:1

julia> map(x -> x^2, B)
ERROR: UndefVarError: `B` not defined
Stacktrace:
 [1] top-level scope
   @ none:1
```

# Array Fusion

Finch supports array fusion, which allows you to compose multiple array operations
into a single kernel. This can be a significant performance optimization, as it
allows the compiler to optimize the entire operation at once. The two functions
the user needs to know about are `lazy` and `compute`. You can use `lazy` to
mark an array as an input to a fused operation, and call `compute` to execute
the entire operation at once. For example:

```jldoctest example1
julia> C = lazy(A);

julia> D = lazy(B);
ERROR: UndefVarError: `B` not defined
Stacktrace:
 [1] top-level scope
   @ none:1

julia> E = (C .+ D)/2;
ERROR: UndefVarError: `D` not defined
Stacktrace:
 [1] top-level scope
   @ none:1

julia> compute(E)
ERROR: UndefVarError: `E` not defined
Stacktrace:
 [1] top-level scope
   @ none:1

```

In the above example, `E` is a fused operation that adds `C` and `D` together
and then divides the result by 2. The `compute` function examines the entire
operation and decides how to execute it in the most efficient way possible.
In this case, it would likely generate a single kernel that adds the elements of `A` and `B`
together and divides each result by 2, without materializing an intermediate.

```@docs
lazy
compute
```

# Einsum

Finch also supports a highly general `@einsum` macro which supports any reduction over any simple pointwise array expression.

```@docs
@einsum
```