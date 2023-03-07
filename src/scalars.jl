mutable struct Scalar{D, Tv}# <: AbstractArray{Tv, 0}
    val::Tv
end

Scalar(D, args...) = Scalar{D}(args...)
Scalar{D}(args...) where {D} = Scalar{D, typeof(D)}(args...)
Scalar{D, Tv}() where {D, Tv} = Scalar{D, Tv}(D)

@inline Base.ndims(tns::Scalar) = 0
@inline Base.size(::Scalar) = ()
@inline Base.axes(::Scalar) = ()
@inline Base.eltype(::Scalar{D, Tv}) where {D, Tv} = Tv
@inline default(::Scalar{D}) where {D} = D

(tns::Scalar)() = tns.val
@inline Base.getindex(tns::Scalar) = tns.val

struct VirtualScalar
    ex
    Tv
    D
    name
    val
end

(ctx::Finch.LowerJulia)(tns::VirtualScalar) = :($Scalar{$(tns.D), $(tns.Tv)}($(tns.val)))
function virtualize(ex, ::Type{Scalar{D, Tv}}, ctx, tag) where {D, Tv}
    sym = ctx.freshen(tag)
    val = Symbol(tag, :_val) #TODO hmm this is risky
    push!(ctx.preamble, quote
        $sym = $ex
        $val = $sym.val
    end)
    VirtualScalar(sym, Tv, D, tag, val)
end

virtual_size(::VirtualScalar, ctx) = ()

virtual_default(tns::VirtualScalar) = tns.D
virtual_eltype(tns::VirtualScalar) = tns.Tv

FinchNotation.isliteral(::VirtualScalar) = false

function declare!(tns::VirtualScalar, ctx, init)
    push!(ctx.preamble, quote
        $(tns.val) = $(ctx(init))
    end)
    tns
end

function thaw!(tns::VirtualScalar, ctx)
    return tns
end

function freeze!(tns::VirtualScalar, ctx)
    return tns
end

function lowerjulia_access(ctx::LowerJulia, node, tns::VirtualScalar)
    @assert isempty(node.idxs)
    return tns.val
end

struct VirtualDirtyScalar
    ex
    Tv
    D
    name
    val
    dirty
end

virtual_size(::VirtualDirtyScalar, ctx) = ()

virtual_default(tns::VirtualDirtyScalar) = tns.D
virtual_eltype(tns::VirtualDirtyScalar) = tns.Tv

FinchNotation.isliteral(::VirtualDirtyScalar) = false

function lowerjulia_access(ctx::LowerJulia, node, tns::VirtualDirtyScalar)
    @assert isempty(node.idxs)
    push!(ctx.preamble, quote
        $(tns.dirty) = true
    end)
    return tns.val
end

ortho(var) = (stmt) -> !(var in getvars(stmt))

function base_rules(alg, ctx::LowerJulia, a, tns::Union{VirtualScalar, VirtualDirtyScalar}) 
    return [
        (@rule sequence(~s1..., declare(a, ~z::isliteral), ~s2::ortho(a)..., assign(access(a, ~m), ~f::isliteral, ~b::isliteral), ~s3...) =>
            sequence(s1..., s2..., declare(a, literal(f.val(z.val, b.val))), s3...)
        ),
        (@rule loop(~i, assign(access(~a, ~m), $(literal(+)), ~b::isliteral)) =>
            assign(access(a, m), f, call(*, b, extent(ctx.dims[i])))
        ),

        (@rule loop(~i, sequence(~s1::ortho(a)..., assign(access(~a, ~m), $(literal(+)), ~b::isliteral), ~s2::ortho(a)...)) =>
            sequence(assign(access(a, m), f, call(*, b, extent(ctx.dims[i]))), loop(i, sequence(s1..., s2...)))
        ),
        (@rule loop(~i, assign(access(~a, ~m), ~f::isidempotent(alg), ~b::isliteral)) =>
            assign(access(a, m), f, b)
        ),
        (@rule loop(~i, sequence(~s1::ortho(a)..., assign(access(~a, ~m), ~f::isidempotent(alg), ~b::isliteral), ~s2::ortho(a)...)) =>
            sequence(assign(access(a, m), f, b), loop(i, sequence(s1..., s2...)))
        ),
        (@rule sequence(~s1..., assign(access(a, ~m), ~f::isabelian(alg), ~b), ~s2::ortho(a)..., assign(access(a, ~m), ~f, ~c), ~s3...) =>
            sequence(s1..., assign(access(a, m), f, call(f, b, c)))
        ),

        (@rule sequence(~s1..., declare(a, ~z), ~s2::ortho(a)..., freeze(a), ~s3...) =>
            sequence(s1..., s2..., declare(a, z), freeze(a), s3...)
        ),
        (@rule sequence(~s1..., declare(a, ~z), freeze(a), ~s2::ortho(a)..., ~s3, ~s4...) =>
            if (s3 = Postwalk(@rule access(a, reader()) => z)(s3)) !== nothing
                sequence(s1..., declare(a, ~z), freeze(a), s2..., s3, s4...)
            end
        ),
        (@rule sequence(~s1..., thaw(a, ~z), ~s2::ortho(a)..., freeze(a), ~s3...) =>
            sequence(s1..., s2..., s3...)
        ),
        #=
        (@rule sequence(~s1..., declare(a, ~z), ~s2..., freeze(a), ~s3::ortho(a)...) =>
            sequence(s1..., s2..., s3...)
        ),
        =#
    ]
end