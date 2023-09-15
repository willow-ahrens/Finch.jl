abstract type AbstractAlgebra end
struct DefaultAlgebra<:AbstractAlgebra end

virtualize(ex, ::Type{DefaultAlgebra}, ctx) = DefaultAlgebra()

struct Chooser{D} end

(f::Chooser{D})(x) where {D} = x
function (f::Chooser{D})(x, y, tail...) where {D}
    if isequal(x, D)
        return f(y, tail...)
    else
        return x
    end
end
"""
    choose(z)(a, b)

`choose(z)` is a function which returns whichever of `a` or `b` is not
[isequal](https://docs.julialang.org/en/v1/base/base/#Base.isequal) to `z`. If
neither are `z`, then return `a`. Useful for getting the first nonfill value in
a sparse array.
```jldoctest setup=:(using Finch)
julia> a = Fiber!(SparseList(Element(0.0)), [0, 1.1, 0, 4.4, 0])
SparseList (0.0) [1:5]
├─[2]: 1.1
├─[4]: 4.4

julia> x = Scalar(0.0); @finch for i=_; x[] <<choose(0.0)>>= a[i] end;

julia> x[]
1.1
```
"""
choose(d) = Chooser{d}()

"""
    minby(a, b)

Return the min of `a` or `b`, comparing them by `a[1]` and `b[1]`, and breaking
ties to the left. Useful for implementing argmin operations:
```jldoctest setup=:(using Finch)
julia> a = [7.7, 3.3, 9.9, 3.3, 9.9]; x = Scalar(Inf => 0);

julia> @finch for i=_; x[] <<minby>>= a[i] => i end;

julia> x[]
3.3 => 2
```
"""
minby(a, b) = a[1] > b[1] ? b : a

"""
    maxby(a, b)

Return the max of `a` or `b`, comparing them by `a[1]` and `b[1]`, and breaking
ties to the left. Useful for implementing argmax operations:
```jldoctest setup=:(using Finch)
julia> a = [7.7, 3.3, 9.9, 3.3, 9.9]; x = Scalar(-Inf => 0);

julia> @finch for i=_; x[] <<maxby>>= a[i] => i end;

julia> x[]
9.9 => 3
```
"""
maxby(a, b) = a[1] < b[1] ? b : a

isassociative(alg) = (f) -> isassociative(alg, f)
isassociative(alg, f::FinchNode) = f.kind === literal && isassociative(alg, f.val)
"""
    isassociative(algebra, f)

Return true when `f(a..., f(b...), c...) = f(a..., b..., c...)` in `algebra`.
"""
isassociative(::Any, f) = false
isassociative(::AbstractAlgebra, ::typeof(or)) = true
isassociative(::AbstractAlgebra, ::typeof(and)) = true
isassociative(::AbstractAlgebra, ::typeof(|)) = true
isassociative(::AbstractAlgebra, ::typeof(&)) = true
isassociative(::AbstractAlgebra, ::typeof(coalesce)) = true
isassociative(::AbstractAlgebra, ::typeof(something)) = true
isassociative(::AbstractAlgebra, ::typeof(+)) = true
isassociative(::AbstractAlgebra, ::typeof(*)) = true
isassociative(::AbstractAlgebra, ::typeof(min)) = true
isassociative(::AbstractAlgebra, ::typeof(max)) = true
isassociative(::AbstractAlgebra, ::typeof(minby)) = true
isassociative(::AbstractAlgebra, ::typeof(maxby)) = true
isassociative(::AbstractAlgebra, ::Chooser) = true

iscommutative(alg) = (f) -> iscommutative(alg, f)
iscommutative(alg, f::FinchNode) = f.kind === literal && iscommutative(alg, f.val)
"""
    iscommutative(algebra, f)

Return true when for all permutations p, `f(a...) = f(a[p]...)` in `algebra`.
"""
iscommutative(::Any, f) = false
iscommutative(::AbstractAlgebra, ::typeof(or)) = true
iscommutative(::AbstractAlgebra, ::typeof(and)) = true
iscommutative(::AbstractAlgebra, ::typeof(|)) = true
iscommutative(::AbstractAlgebra, ::typeof(&)) = true
iscommutative(::AbstractAlgebra, ::typeof(+)) = true
iscommutative(::AbstractAlgebra, ::typeof(*)) = true
iscommutative(::AbstractAlgebra, ::typeof(min)) = true
iscommutative(::AbstractAlgebra, ::typeof(max)) = true

isabelian(alg) = (f) -> isabelian(alg, f)
isabelian(alg, f) = isassociative(alg, f) && iscommutative(alg, f)

isdistributive(alg) = (f, g) -> isdistributive(alg, f, g)
isdistributive(alg, f::FinchNode, x::FinchNode) = isliteral(f) && isliteral(x) && isdistributive(alg, f.val, x.val)
"""
    isdistributive(algebra, f, g)

Return true when `f(a, g(b, c)) = g(f(a, b), f(a, c))` in `algebra`.
"""
isdistributive(::Any, f, g) = false
isdistributive(::AbstractAlgebra, ::typeof(+), ::typeof(*)) = true

isidempotent(alg) = (f) -> isidempotent(alg, f)
isidempotent(alg, f::FinchNode) = f.kind === literal && isidempotent(alg, f.val)
"""
    isidempotent(algebra, f)

Return true when `f(a, b) = f(f(a, b), b)` in `algebra`.
"""
isidempotent(::Any, f) = false
isidempotent(::AbstractAlgebra, ::typeof(overwrite)) = true
isidempotent(::AbstractAlgebra, ::typeof(|)) = true
isidempotent(::AbstractAlgebra, ::typeof(&)) = true
isidempotent(::AbstractAlgebra, ::typeof(min)) = true
isidempotent(::AbstractAlgebra, ::typeof(max)) = true
isidempotent(::AbstractAlgebra, ::typeof(minby)) = true
isidempotent(::AbstractAlgebra, ::typeof(maxby)) = true
isidempotent(::AbstractAlgebra, ::Chooser) = true

"""
    isidentity(algebra, f, x)

Return true when `f(a..., x, b...) = f(a..., b...)` in `algebra`.
"""
isidentity(alg) = (f, x) -> isidentity(alg, f, x)
isidentity(alg, f::FinchNode, x::FinchNode) = isliteral(f) && isidentity_by_fn(alg, f.val, x)
isidentity_by_fn(alg, f, x::FinchNode) = isliteral(x) && isidentity(alg, f, x.val)
isidentity(::Any, f, x) = false
isidentity(::AbstractAlgebra, ::typeof(or), x) = x === false
isidentity(::AbstractAlgebra, ::typeof(and), x) = x === true
isidentity(::AbstractAlgebra, ::typeof(coalesce), x) = ismissing(x)
isidentity(::AbstractAlgebra, ::typeof(something), x) = !ismissing(x) && isnothing(x)
isidentity(::AbstractAlgebra, ::typeof(+), x) = !ismissing(x) && iszero(x)
isidentity(::AbstractAlgebra, ::typeof(*), x) = !ismissing(x) && isone(x)
isidentity(::AbstractAlgebra, ::typeof(|), x) = !ismissing(x) && iszero(x)
isidentity(::AbstractAlgebra, ::typeof(&), x) = !ismissing(x) && x == ~(zero(x))
isidentity(::AbstractAlgebra, ::typeof(min), x) = !ismissing(x) && isinf(x) && x > 0
isidentity(::AbstractAlgebra, ::typeof(max), x) = !ismissing(x) && isinf(x) && x < 0
function isidentity_by_fn(alg::AbstractAlgebra, ::typeof(minby), x::FinchNode)
    if @capture x call(tuple, ~a::isliteral, ~b)
        return isidentity(alg, min, a.val)
    elseif isliteral(x)
        return isidentity(alg, min, first(x.val))
    end
    return false
end
function isidentity_by_fn(alg::AbstractAlgebra, ::typeof(maxby), x::FinchNode)
    if @capture x call(tuple, ~a::isliteral, ~b)
        return isidentity(alg, max, a.val)
    elseif isliteral(x)
        return isidentity(alg, max, first(x.val))
    end
    return false
end
isidentity(::AbstractAlgebra, ::Chooser{D}, x) where {D} = isequal(x, D)
isidentity(::AbstractAlgebra, ::InitWriter{D}, x) where {D} = isequal(x, D)

isannihilator(alg) = (f, x) -> isannihilator(alg, f, x)
isannihilator(alg, f::FinchNode, x::FinchNode) = isliteral(f) && isannihilator_by_fn(alg, f.val, x)
isannihilator_by_fn(alg, f, x::FinchNode) = isliteral(x) && isannihilator(alg, f, x.val)
"""
    isannihilator(algebra, f, x)

Return true when `f(a..., x, b...) = x` in `algebra`.
"""
isannihilator(::Any, f, x) = false
isannihilator(::AbstractAlgebra, ::typeof(+), x) = ismissing(x) || isinf(x)
isannihilator(::AbstractAlgebra, ::typeof(*), x) = ismissing(x) || iszero(x)
isannihilator(::AbstractAlgebra, ::typeof(min), x) = ismissing(x) || isinf(x) && x < 0
isannihilator(::AbstractAlgebra, ::typeof(max), x) = ismissing(x) || isinf(x) && x > 0
isannihilator(::AbstractAlgebra, ::typeof(or), x) = ismissing(x) || x === true
isannihilator(::AbstractAlgebra, ::typeof(and), x) = ismissing(x) || x === false
isannihilator(::AbstractAlgebra, ::typeof(|), x) = !ismissing(x) && x == ~(zero(x))
isannihilator(::AbstractAlgebra, ::typeof(&), x) = !ismissing(x) && iszero(x)
function isannihilator_by_fn(alg::AbstractAlgebra, ::typeof(minby), x::FinchNode)
    if @capture x call(tuple, ~a::isliteral, ~b)
        return isannihilator(alg, min, a.val)
    elseif isliteral(x)
        return isannihilator(alg, min, first(x.val))
    end
    return false
end
function isannihilator_by_fn(alg::AbstractAlgebra, ::typeof(maxby), x::FinchNode)
    if @capture x call(tuple, ~a::isliteral, ~b)
        isannihilator(alg, max, a.val)
    elseif isliteral(x)
        isannihilator(alg, max, first(x.val))
    end
    return false
end

isinverse(alg) = (f, g) -> isinverse(alg, f, g)
isinverse(alg, f::FinchNode, g::FinchNode) = isliteral(f) && isliteral(g) && isinverse(alg, f.val, g.val)
"""
    isinverse(algebra, f, g)

Return true when `f(a, g(a))` is the identity under `f` in `algebra`.
"""
isinverse(::Any, f, g) = false
isinverse(::AbstractAlgebra, ::typeof(-), ::typeof(+)) = true
isinverse(::AbstractAlgebra, ::typeof(inv), ::typeof(*)) = true

isinvolution(alg) = (f) -> isinvolution(alg, f)
isinvolution(alg, f::FinchNode) = isliteral(f) && isinvolution(alg, f.val)
"""
    isinvolution(algebra, f)

Return true when `f(f(a)) = a` in `algebra`.
"""
isinvolution(::Any, f) = false
isinvolution(::AbstractAlgebra, ::typeof(-)) = true
isinvolution(::AbstractAlgebra, ::typeof(inv)) = true



collapsed(alg, idx, ext, lhs, f::FinchNode, rhs) = collapsed(alg, idx, ext, lhs, f.val, rhs)
"""
    collapsed(algebra, f, idx, ext, node)

Return collapsed expression with respect to f.
"""
collapsed(alg, idx, ext, lhs, f::Any, rhs) = isidempotent(alg, f) ? sieve(call(>, measure(ext), 0), assign(lhs, f, rhs)) : nothing # Hmm.. Why do we need sieve for  only idempotent?

collapsed(alg, idx, ext, lhs, f::typeof(-), rhs) = assign(lhs, f, call(*, measure(ext), rhs))
collapsed(alg, idx, ext, lhs, f::typeof(*), rhs) = assign(lhs, f, call(^, rhs, measure(ext)))
collapsed(alg, idx, ext::Extent, lhs, f::typeof(+), rhs) = assign(lhs, f, call(*, measure(ext), rhs))
collapsed(alg, idx, ext::ContinuousExtent, lhs, f::typeof(+), rhs) = begin 
    if (@capture rhs call(*, ~a1..., call(d, ~i1..., idx, ~i2...), ~a2...)) # Lebesgue
        if query(call(==, measure(ext), 0), LowerJulia())
            assign(lhs, f, literal(0))
        else
            assign(lhs, f, call(*, call(drop_eps, measure(ext)), a1..., a2..., call(d, i1..., i2...)))
        end
    else # Counting
        if query(call(==, measure(ext), 0), LowerJulia())
            assign(lhs, f, rhs)
        else
            sieve(call(==, measure(ext), 0), assign(lhs, f, rhs)) # Undefined if measure != 0 
        end
    end
end

getvars(arr::AbstractArray) = mapreduce(getvars, vcat, arr, init=[])
getvars(arr) = getroot(arr) === nothing ? [] : [getroot(arr)]
getroot(arr) = nothing
function getvars(node::FinchNode) 
    if node.kind == variable
        return [node]
    elseif node.kind == virtual
        return getvars(node.val)
    elseif istree(node)
        return mapreduce(getvars, vcat, arguments(node), init=[])
    else
        return []
    end
end


ortho(var, stmt) = !(var in getvars(stmt))

include("simplify_program.jl")
include("analyze_bounds.jl")
