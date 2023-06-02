```@meta
CurrentModule = Finch
```
# Debugging Functionality

It's easy to ask Finch to advance a few steps in its compiler pipeline. The basic functionality is documented via the following bit of code:
```
y = @fiber d(e(0.0))
A = @fiber d(sl(e(0.0)))
x = @fiber sl(e(0.0))



code = Finch.@finch_program_instance begin
   @loop j i y[i] += A[i, j] * x[j]
end

debug = Finch.stage_code(code)

while true
    global debug = step_code(debug, sdisplay=false) # Runs one step of compilation
    if iscompiled(debug.code) # Checks if we are done compiling.
        break
    end
end
        
ret = end_debug(debug) # extracts code from debugging context.
# Prints compiled code
```

The function `Finch.stage_code(code; algebra)` takes a `finch_program_instance` plus an optional algebra
and creates a debugging context for it. The function `step_code(debug; steps, sdisplay)` takes a debug 
context and advances some number of `steps`, displaying the results automatically if `sdisplay`.
Finally, `iscompiled` checks if the code in a debug context is completely compiled and `end_debug` extracts the code,
throwing an error if the code is not completely compiled.

Partially compiled code will be displayed almost like fully compiled code but with `@finch` nodes that are numbered according to
which will be compiled first. They also display where they will renter the compilation pipeline. 
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
    y_lvl.shape == A_lvl_2.shape || throw(DimensionMismatch("mismatched dimension limits ($(y_lvl.shape) != $(@finch((Number = 0, Which = ("/Users/teodorocollin/vsgitcode/Finch.jl/src/lower.jl", 174))A_lvl_2.shape::Int64)))"))
    @finch((Number = 1, Which = ("/Users/teodorocollin/vsgitcode/Finch.jl/src/lower.jl", 174))A_lvl.shape::Int64) == @finch((Number = 2, Which = ("/Users/teodorocollin/vsgitcode/Finch.jl/src/lower.jl", 174))x_lvl.shape::Int64) || throw(DimensionMismatch("mismatched dimension limits ($(@finch((Number = 3, Which = ("/Users/teodorocollin/vsgitcode/Finch.jl/src/lower.jl", 174))A_lvl.shape::Int64)) != $(@finch((Number = 4, Which = ("/Users/teodorocollin/vsgitcode/Finch.jl/src/lower.jl", 174))x_lvl.shape::Int64)))"))
    @finch begin(Number = 5, Which = ("/Users/teodorocollin/vsgitcode/Finch.jl/src/lower.jl", 174))
      begin
        @thaw(y)
        @∀ j = virtual(Finch.Extent) i = virtual(Finch.Extent)  (
          y[i] <<+>>= *(x[j], A[i, j])        )
        @freeze(y)
      end
    end
    qos = @finch((Number = 6, Which = ("/Users/teodorocollin/vsgitcode/Finch.jl/src/lower.jl", 174))1) * @finch((Number = 7, Which = ("/Users/teodorocollin/vsgitcode/Finch.jl/src/lower.jl", 174))y_lvl.shape::Int64)
    resize!(y_lvl_2.val, @finch((Number = 8, Which = ("/Users/teodorocollin/vsgitcode/Finch.jl/src/lower.jl", 174))qos))
    (y = @finch((Number = 9, Which = ("/Users/teodorocollin/vsgitcode/Finch.jl/src/tensors/fibers.jl", 27))VirtualFiber(d(e(0.0)))),)
end
```

## Dangers

This feature is experiment and could easily break. In particular, this feature assumes that the Finch compiler never produces 
code that it needs to use to produce the next bit of code without putting this analysis in the output. For example, we cannot
```
code = ctx(A)
info = analysis(code)
code1 = ctx(A, info)
begin
$code1
$code2
end
```
because analysis on code will give the wrong results if we don't finish it, 
but it would be okay to do something like this if we placed the analysis in the resulting code.

If in the future, Finch needs to do this, this feature will break. However, there is an internal mechanism to recover. The `AbstractLoweringControl` type
is supposed to manage when code is allowed to be paused via the `should_pause` function.  Modifying this function on `StepOnlyControl <: AbstractLoweringControl`
or creating a new control is a potential route to ensure incremental compilation does not occur when it is impossible i.e 
when dependencies in the compiler mean code cannot be partially compiled.
## Dangers and Advanced Features
Furthermore, the Finch compiler is inhernetly serial: statements in a sequence
rely on information found via compiling earlier statements. Thus, although this feature exports functions that can reorder the compilation,
we do not expect these to work consistently and we leave them basically undocumented.