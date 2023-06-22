## Finch Notation

Finch programs are written in Julia, but they are not Julia programs.
Instead, they are an abstraction description of a tensor computation.

Finch programs are sequences of tensor operations, joined by control flow.
The tensor operations may be either
    1. Assignment statements, which assign a tensor expression to a tensor variable, or






Every tensor in a Finch program is referenced by a root variable. Array wrappers
like `OffsetArray` can wrap arrays to modify their behavior. Array wrappers may
also wrap arrays referenced by root variables, using the `RootArray` type. In
the following program, `x` and `y` are root variables, and the access to `x` is wrapped by
an `OffsetArray` and a `PermissiveArray`.

```julia
x = rand(3, 3)
y = rand(3, 3)
@finch begin
    x .= 0
    for i = :, j = :;
        x[~(i - 1), j] = y[i, j] * 2
    end
end
```




Every tensor must be in one of two modes: read-only mode or update-only mode. The following functions may be called on virtual tensors throughout their life cycle.

```@docs
declare!
instantiate_reader
instantiate_updater
freeze!
trim!
thaw!
```