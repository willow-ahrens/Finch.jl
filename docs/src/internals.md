```@meta
CurrentModule = Finch
```

## Finch Compilation

## Finch Notation

```@docs
FinchNode
cached
finch_leaf
```



### Program Instances

Finch relies heavily on Julia's
[metaprogramming capabilities](https://docs.julialang.org/en/v1/manual/metaprogramming/) (
[macros](https://docs.julialang.org/en/v1/manual/metaprogramming/#Macros) and
[generated functions](https://docs.julialang.org/en/v1/manual/metaprogramming/#Generated-functions)
in particular) to produce code. To review briefly, a macro allows us to inspect
the syntax of it's arguments and generate replacement syntax. A generated
function allows us to inspect the type of the function arguments and produce
code for a function body.

In normal Finch usage, we might call Finch as follows:

```jldoctest example1; setup = :(using Finch)
julia> C = Fiber!(SparseList(Element(0)));

julia> A = Fiber!(SparseList(Element(0)), [0, 2, 0, 0, 3]);

julia> B = Fiber!(Dense(Element(0)), [11, 12, 13, 14, 15]);

julia> @finch (C .= 0; for i=_; C[i] = A[i] * B[i] end);

julia> C
SparseList (0) [1:5]
├─[2]: 24
├─[5]: 45
```

The
[`@macroexpand`](https://docs.julialang.org/en/v1/base/base/#Base.macroexpand)
macro allows us to see the result of applying a macro. Let's examine what
happens when we use the `@finch` macro (we've stripped line numbers from the
result to clean it up):

```jldoctest example1
julia> (@macroexpand @finch (C .= 0; for i=_; C[i] = A[i] * B[i] end)) |> Finch.striplines |> Finch.regensym
quote
    _res_1 = (Finch.execute)((Finch.FinchNotation.block_instance)((Finch.FinchNotation.declare_instance)((Finch.FinchNotation.tag_instance)(variable_instance(:C), (Finch.FinchNotation.finch_leaf_instance)(C)), literal_instance(0)), begin
                    let i = index_instance(i)
                        (Finch.FinchNotation.loop_instance)(i, Finch.FinchNotation.Dimensionless(), (Finch.FinchNotation.assign_instance)((Finch.FinchNotation.access_instance)((Finch.FinchNotation.tag_instance)(variable_instance(:C), (Finch.FinchNotation.finch_leaf_instance)(C)), (Finch.FinchNotation.updater_instance)(), (Finch.FinchNotation.tag_instance)(variable_instance(:i), (Finch.FinchNotation.finch_leaf_instance)(i))), (Finch.FinchNotation.literal_instance)(Finch.FinchNotation.initwrite), (Finch.FinchNotation.call_instance)((Finch.FinchNotation.tag_instance)(variable_instance(:*), (Finch.FinchNotation.finch_leaf_instance)(*)), (Finch.FinchNotation.access_instance)((Finch.FinchNotation.tag_instance)(variable_instance(:A), (Finch.FinchNotation.finch_leaf_instance)(A)), (Finch.FinchNotation.reader_instance)(), (Finch.FinchNotation.tag_instance)(variable_instance(:i), (Finch.FinchNotation.finch_leaf_instance)(i))), (Finch.FinchNotation.access_instance)((Finch.FinchNotation.tag_instance)(variable_instance(:B), (Finch.FinchNotation.finch_leaf_instance)(B)), (Finch.FinchNotation.reader_instance)(), (Finch.FinchNotation.tag_instance)(variable_instance(:i), (Finch.FinchNotation.finch_leaf_instance)(i))))))
                    end
                end))
    begin
        C = Finch.get(_res_1, :C, C)
    end
    begin
        _res_1
    end
end

```

In the above output, `@finch` creates an AST of program instances, then calls
`Finch.execute` on it. A program instance is a struct that contains the program
to be executed along with its arguments. Although we can use the above
constructors (e.g. `loop_instance`) to make our own program instance, it is most
convenient to use the unexported macro `Finch.finch_program_instance`:

```jldoctest example1
julia> using Finch: @finch_program_instance

julia> prgm = Finch.@finch_program_instance (C .= 0; for i=_; C[i] = A[i] * B[i] end)
block_instance(declare_instance(tag_instance(:variable_instance(:C), Fiber(SparseList{Int64, Int64}(Element{0, Int64}([24, 45]), 5, [1, 3], [2, 5]))), literal_instance(0)), loop_instance(index_instance(i), Finch.FinchNotation.Dimensionless(), assign_instance(access_instance(tag_instance(:variable_instance(:C), Fiber(SparseList{Int64, Int64}(Element{0, Int64}([24, 45]), 5, [1, 3], [2, 5]))), updater_instance(), tag_instance(:variable_instance(:i), index_instance(i))), literal_instance(initwrite), call_instance(tag_instance(:variable_instance(:*), literal_instance(*)), access_instance(tag_instance(:variable_instance(:A), Fiber(SparseList{Int64, Int64}(Element{0, Int64}([2, 3]), 5, [1, 3], [2, 5]))), reader_instance(), tag_instance(:variable_instance(:i), index_instance(i))), access_instance(tag_instance(:variable_instance(:B), Fiber(Dense{Int64}(Element{0, Int64}([11, 12, 13, 14, 15]), 5))), reader_instance(), tag_instance(:variable_instance(:i), index_instance(i)))))))
```

As we can see, our program instance contains not only the AST to be executed,
but also the data to execute the program with. The type of the program instance
contains only the program portion; there may be many program instances with
different inputs, but the same program type. We can run our program using
`Finch.execute`, which returns a `NamedTuple` of outputs.

```jldoctest example1
julia> typeof(prgm)
Finch.FinchNotation.BlockInstance{Tuple{Finch.FinchNotation.DeclareInstance{Finch.FinchNotation.TagInstance{Finch.FinchNotation.VariableInstance{:C}, Fiber{SparseListLevel{Int64, Int64, ElementLevel{0, Int64}}}}, Finch.FinchNotation.LiteralInstance{0}}, Finch.FinchNotation.LoopInstance{Finch.FinchNotation.IndexInstance{:i}, Finch.FinchNotation.Dimensionless, Finch.FinchNotation.AssignInstance{Finch.FinchNotation.AccessInstance{Finch.FinchNotation.TagInstance{Finch.FinchNotation.VariableInstance{:C}, Fiber{SparseListLevel{Int64, Int64, ElementLevel{0, Int64}}}}, Finch.FinchNotation.UpdaterInstance, Tuple{Finch.FinchNotation.TagInstance{Finch.FinchNotation.VariableInstance{:i}, Finch.FinchNotation.IndexInstance{:i}}}}, Finch.FinchNotation.LiteralInstance{Finch.FinchNotation.initwrite}, Finch.FinchNotation.CallInstance{Finch.FinchNotation.TagInstance{Finch.FinchNotation.VariableInstance{:*}, Finch.FinchNotation.LiteralInstance{*}}, Tuple{Finch.FinchNotation.AccessInstance{Finch.FinchNotation.TagInstance{Finch.FinchNotation.VariableInstance{:A}, Fiber{SparseListLevel{Int64, Int64, ElementLevel{0, Int64}}}}, Finch.FinchNotation.ReaderInstance, Tuple{Finch.FinchNotation.TagInstance{Finch.FinchNotation.VariableInstance{:i}, Finch.FinchNotation.IndexInstance{:i}}}}, Finch.FinchNotation.AccessInstance{Finch.FinchNotation.TagInstance{Finch.FinchNotation.VariableInstance{:B}, Fiber{DenseLevel{Int64, ElementLevel{0, Int64}}}}, Finch.FinchNotation.ReaderInstance, Tuple{Finch.FinchNotation.TagInstance{Finch.FinchNotation.VariableInstance{:i}, Finch.FinchNotation.IndexInstance{:i}}}}}}}}}}

julia> C = Finch.execute(prgm).C
SparseList (0) [1:5]
├─[2]: 24
├─[5]: 45
```

This functionality is sufficient for building finch kernels programatically. For
example, if we wish to define a function `pointwise_sum()` that takes the
pointwise sum of a variable number of vector inputs, we might implement it as
follows:

```jldoctest example1
julia> function pointwise_sum(As...)
           B = Fiber!(Dense(Element(0)))
           isempty(As) && return B
           i = Finch.FinchNotation.index_instance(:i)
           A_vars = [Finch.FinchNotation.tag_instance(Finch.FinchNotation.variable_instance(Symbol(:A, n)), As[n]) for n in 1:length(As)]
           #create a list of variable instances with different names to hold the input tensors
           ex = @finch_program_instance 0
           for A_var in A_vars
               ex = @finch_program_instance $A_var[i] + $ex
           end
           prgm = @finch_program_instance (B .= 0; for i=_; B[i] = $ex end)
           return Finch.execute(prgm).B
       end
pointwise_sum (generic function with 1 method)

julia> pointwise_sum([1, 2], [3, 4])
Dense [1:2]
├─[1]: 4
├─[2]: 6

```

## Virtual Tensor Methods

```@docs
declare!
instantiate_reader
instantiate_updater
freeze!
trim!
thaw!
unfurl
```
## Virtualization

TODO more on the way...


## Fiber internals

Fiber levels are implemented using the following methods:

```@docs
default
declare_level!
assemble_level!
reassemble_level!
freeze_level!
level_ndims
level_size
level_axes
level_eltype
level_default
```


## Debugging Functionality

It's easy to ask Finch to advance a few steps in its compiler sequence. The basic functionality is documented via the following bit of code:
```
using Finch
using Finch: @finch_program_instance, begin_debug, step_code, iscompiled, end_debug

y = Fiber!(Dense(Element(0.0)))
A = Fiber!(Dense(SparseList(Element(0.0))))
x = Fiber!(SparseList(Element(0.0)))

code = Finch.@finch_program_instance begin
   for j=_, i=_; y[i] += A[i, j] * x[j] end
end

debug = begin_debug(code)

while true
    global debug = step_code(debug) # Runs one step of compilation
    if iscompiled(debug.code) # Checks if we are done compiling.
        break
    end
end
        
ret = end_debug(debug) # extracts code from debugging context.
# Prints compiled code
```

The function `begin_debug(code; algebra)` takes a `finch_program_instance` plus an optional algebra
and creates a debugging context for it, called a `PartialCode`. The function `step_code(debug; steps, sdisplay)` takes a debugging 
context and advances some number of `steps`, displaying the results automatically if `sdisplay`.
Finally, `iscompiled` checks if the code in a debug context is completely compiled and `end_debug` extracts the code,
throwing an error if the code is not completely compiled.


```@docs
begin_debug
step_code
iscompiled
end_debug
PartialCode
```

Partially compiled code will be displayed almost like fully compiled code but with `@finch` nodes that are numbered according to
which will be compiled first. They also display where they will renter the compilation sequence. 
An early step in the above program might look like:
```
quote
    y_lvl = ex.body.body.lhs.tns.tns.lvl
    y_lvl_2 = y_lvl.lvl
    A_lvl = (ex.body.body.rhs.args[1]).tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_3 = A_lvl_2.lvl
    x_lvl = (ex.body.body.rhs.args[2]).tns.tns.lvl
    x_lvl_2 = x_lvl.lvl
    y_lvl.shape == A_lvl_2.shape || throw(DimensionMismatch("mismatched dimension limits ($(y_lvl.shape) != $(@finch((Number = 0, Which = ("lower.jl", 174))A_lvl_2.shape::Int64)))"))
    @finch((Number = 1, Which = ("lower.jl", 174))A_lvl.shape::Int64) == @finch((Number = 2, Which = ("lower.jl", 174))x_lvl.shape::Int64) || throw(DimensionMismatch("mismatched dimension limits ($(@finch((Number = 3, Which = ("lower.jl", 174))A_lvl.shape::Int64)) != $(@finch((Number = 4, Which = ("lower.jl", 174))x_lvl.shape::Int64)))"))
    @finch begin(Number = 5, Which = ("lower.jl", 174))
      begin
        @thaw(y)
        @∀ j = virtual(Finch.Extent) i = virtual(Finch.Extent)  (
          y[i] <<+>>= *(x[j], A[i, j])        )
        @freeze(y)
      end
    end
    qos = @finch((Number = 6, Which = ("lower.jl", 174))1) * @finch((Number = 7, Which = ("lower.jl", 174))y_lvl.shape::Int64)
    resize!(y_lvl_2.val, @finch((Number = 8, Which = ("lower.jl", 174))qos))
    (y = @finch((Number = 9, Which = ("fibers.jl", 27))VirtualFiber(Dense(Element(0.0)))),)
end
```

### Dangers

This feature is experimental and could easily break. In particular, this feature assumes that the Finch compiler never produces 
code that is needed to produce the next bit of code without putting the required analysis in the program that is being compiled. For example, we cannot currently pause
```
code = ctx(A1)
info = analysis(code)
code1 = ctx(A2, info)
begin
$code1
$code2
end
```
because analysis on the first bit of code will give the wrong results if we don't finish it, 
but it would be okay to do something like this if we placed the analysis in the resulting code, 
as part of the runtime.


If in the future, Finch needs to do this, this feature will break. However, there is an internal mechanism to recover. The `AbstractLoweringControl` type
is supposed to manage when code is allowed to be paused via the `should_pause` function.  Modifying this function on `StepOnlyControl <: AbstractLoweringControl`
or creating a new control is a potential route to ensure incremental compilation does not occur when it is impossible i.e 
when dependencies in the compiler mean code cannot be partially compiled.

```@docs
Resumable
should_resume
should_pause
evolve_control
init_meta
```



### Advanced Dangers: Non-Serial Compilation
Furthermore, the Finch compiler is inhernetly serial: statements in a block
rely on information found via compiling earlier statements. Thus, although this feature exports functions that can reorder the compilation,
we do not expect these to work consistently and we leave them basically undocumented.

```@docs
step_all_code
repeat_step_code
step_some_code
```

