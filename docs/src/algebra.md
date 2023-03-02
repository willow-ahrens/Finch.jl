```@meta
CurrentModule = Finch
```

## Register User Functions

Finch uses generated functions to compile kernels. If any functions have been
defined after Finch was loaded, Finch needs to be notified about them. The most
correct approach is to create a trait datatype that subtypes
`Finch.AbstractAlgebra` and call `Finch.register` on that type. After you call
`register`, that subtype reflects the methods you know to be currently defined
at that world age. You can pass your algebra to Finch to run Finch in that world
age.

## Declare Algebraic Properties

Users can help Finch optimize expressions over new functions by declaring key
function properties in the algebra. Finch kernels can then be executed using the
algebra.

As an example, suppose we wanted to declare some properties for the greatest
common divisor function `gcd`. This function is associative and commutative, and
the greatest common divisor of 1 and anything else is 1, so 1 is an annihilator.

We can express this by subtyping `AbstractAlgebra` and defining properties as
follows:
```
struct MyAlgebra <: AbstractAlgebra end

Finch.isassociative(::MyAlgebra, ::typeof(gcd)) = true
Finch.iscommutative(::MyAlgebra, ::typeof(gcd)) = true
Finch.isannihilator(::MyAlgebra, ::typeof(gcd), x) = x == 1
```

When you're all done defining functions that dispatch on your algebra, call
`Finch.register` to register your new algebra in Finch.
```
Finch.register(MyAlgebra)
```

Then, we can call a kernel that uses our algebra!

```
u = @fiber sl(e(1)) #TODO add some data
v = @fiber sl(e(1)) #TODO add some data
w = @fiber sl(e(1))

@finch MyAlgebra() (w .= 1; @loop i w[i] = gcd(u[i], v[i]))
```

## Properties

The full list of properties recognized by Finch is as follows:

```@docs
isassociative
iscommutative
isdistributive
isidempotent
isidentity
isannihilator
isinverse
isinvolution
```

## Rewriting

One can also define custom rewrite rules by overloading the `getrules` function
on your algebra.  Unless you want to write the full rule set from scratch, be
sure to append your new rules to the old rules, which can be obtained by calling
`base_rules`. Rules can be specified directly on Finch IR using
[RewriteTools.jl](https://github.com/willow-ahrens/RewriteTools.jl)

```@docs
base_rules
getrules
```