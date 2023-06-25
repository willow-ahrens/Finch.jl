# Author: Willow Ahrens and Jaeyeon Won
# Date: 2023
# Description: A type for representing the infinitesimal number.
#

"""
    Limit{T}(x, s)

The Limit type represents the infinitestimal number. Limit type can be used to 
represent endpoints of closed and open intervals.  The val field is the value 
of the endpoint.  The sign field is used to represent the openness/closedness 
of the interval endpoint. The sign field is 0 for closed intervals, non-zeros 
for infinitestimal number (epsilon number).

```jl-doctest
julia> limit(1.0)
1.0+0

julia> plus_eps(1.0)
1.0+ϵ

julia> minus_eps(1.0)
1.0-ϵ

julia> plus_eps(1.0) + minus_eps(1.0)
2.0+0.0

julia> plus_eps(1.0) * 2
2.0+2.0ϵ

julia> plus_eps(1.0) * minus_eps(1.0)
1.0-1.0ϵ

julia> plus_eps(-1.0) * minus_eps(1.0)
-1.0+2.0ϵ

julia> 1.0 < plus_eps(1.0)
true

julia> 1.0 < minus_eps(1.0)
false
"""
struct Limit{T}
    val
    sign::Float32
end

limit(x::T, s) where {T} = Limit{T}(x, s)
const Eps = limit(0,1)
plus_eps(x) = limit(x, 1)   # x+eps()
minus_eps(x) = limit(x, -1) # x-eps()
limit(x) = limit(x, 0.0)

function Base.show(io::IO, x::Limit)
    if x.sign > 0
        print(io, "plus_eps(", x.val, ")")
    elseif x.sign < 0
        print(io, "minus_eps(", x.val, ")")
    elseif x.sign == 0
        print(io, "limit(", x.val, ")")
    else
        error(io, "unimplemented")
    end
end

function Base.show(io::IO, mime::MIME"text/plain", x::Limit)
    if x.sign > 0
        print(io, x.val, "+", x.sign, "ϵ")
    elseif x.sign < 0
        print(io, x.val, "-", abs(x.sign), "ϵ")
    elseif x.sign == 0
        print(io, x.val, "+0.0")
    else
        error(io, "unimplemented")
    end
end

#Core definitions for limit type
Base.:(+)(x::Limit, y::Limit) = limit(x.val + y.val, x.sign + y.sign)
Base.:(*)(x::Limit, y::Limit) = limit(x.val * y.val, x.val * y.sign + y.val * x.sign) 
Base.:(-)(x::Limit, y::Limit) = limit(x.val - y.val, x.sign - y.sign)
Base.:(<)(x::Limit, y::Limit) = x.val < y.val || (x.val == y.val && x.sign < y.sign)
Base.:(<=)(x::Limit, y::Limit) = x.val < y.val || (x.val == y.val && x.sign <= y.sign)
Base.:(==)(x::Limit, y::Limit) = x.val == y.val && x.sign == y.sign
Base.isless(x::Limit, y::Limit) = x < y

#Crazy julia multiple dispatch stuff don't worry about it
limit_types = [Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128, BigInt, Float32, Float64]
for S in limit_types
    @eval begin
        @inline Base.promote_rule(::Type{Limit{T}}, ::Type{$S}) where {T} = Limit{promote_type(T, $S)}
        Base.convert(::Type{Limit{T}}, i::$S) where {T} = limit(convert(T, i))
        Limit(i::$S) = Limit{$S}(i, 0.0)
        (::Type{$S})(i::Limit{T}) where {T} = convert($S, i.val)
        Base.convert(::Type{$S}, i::Limit) = convert($S, i.val)
        Base.:(+)(x::Limit, y::$S) = x + limit(y)
        Base.:(+)(x::$S, y::Limit) = limit(x) + y
        Base.:(*)(x::Limit, y::$S) = x * limit(y)
        Base.:(*)(x::$S, y::Limit) = limit(x) * y
        Base.:(-)(x::Limit, y::$S) = x - limit(y)
        Base.:(-)(x::$S, y::Limit) = limit(x) - y
        Base.:(<)(x::Limit, y::$S) = x < limit(y)
        Base.:(<)(x::$S, y::Limit) = limit(x) < y
        Base.:(<=)(x::Limit, y::$S) = x <= limit(y)
        Base.:(<=)(x::$S, y::Limit) = limit(x) <= y
        Base.:(==)(x::Limit, y::$S) = x == limit(y)
        Base.:(==)(x::$S, y::Limit) = limit(x) == y
        Base.isless(x::Limit, y::$S) = x < limit(y)
        Base.isless(x::$S, y::Limit) = limit(x) < y
    end
end

Base.promote_rule(::Type{Limit{T}}, ::Type{Limit{S}}) where {T, S} = promote_type(T, S)
Base.convert(::Type{Limit{T}}, i::Limit) where {T} = Limit{T}(convert(T, i.val), i.sign)
Base.hash(x::Limit, h::UInt) = hash(typeof(x), hash(x.val, hash(x.sign, h)))

