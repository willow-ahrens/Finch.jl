export SparseLevel
export SparseFiber
export DenseLevel
export DenseFiber
export ScalarLevel

struct VirtualSparseFiber
    q
    lvl
end

function virtual_getindex(lvl::VirtualSparseLevel, q)
    return VirtualSparseFiber(q, lvl)
end

#Base.size(fbr::SparseFiber) = dimension(fbr.lvl)

function lower_access(fbr::VirtualSparseFiber, i)
    :(getindex($fbr, $i))
end

lower_loop_rewriters(fbr::Virtual{T<:SparseFiber}, ctx) = [
    (@rule access(~a, ~i, ~~j) => if a isa VirtualSparseFiber && i in ctx.bindings
        return Scalar(:(getindex($fbr, $i)))
    end),
]
#function Base.getindex(fbr::SparseFiber{Tv, Ti}, i, tail...) where {Tv, Ti}
#    r = searchsorted(@view(fbr.lvl.idx[fbr.lvl.pos[fbr.q]:fbr.lvl.pos[fbr.q + 1] - 1]), i)
#    length(r) == 0 ? zero(Tv) : fbr.lvl.child[fbr.lvl.pos[fbr.q] + first(r) - 1][tail...]
#end

#represents a collection of DenseFibers
struct VirtualDenseLevel
    expr
    Ti
    child
end

#dimension(lvl::DenseLevel) = (lvl.I, dimension(lvl.child)...)
#Base.size(lvl::DenseLevel) = lvl.Q

struct VirtualDenseFiber
    q
    lvl
end

lower_loop_rewriters(fbr::VirtualDenseFiber, ctx) = [
    (@rule access(~a, ~i, ~~j) => if a isa VirtualDenseFiber && i in ctx.bindings
        q′ = gensym(Symbol(name(a), :_q))
        push!(ctx.preamble, :($q′ = $q * $(fbr.lvl.expr).I + $(~i)))
        return access(virtual_getindex(fbr.lvl.child, q), ~~j)
    end),
]

#function Base.getindex(lvl::DenseLevel{Ti}, q) where {Ti}
#    return DenseFiber(q, lvl)
#end

#Base.size(fbr::DenseFiber) = dimension(fbr.lvl)


#function Base.getindex(fbr::DenseFiber{Ti}, i, tail...) where {Ti}
#    fbr.lvl.child[(fbr.q - 1) * fbr.lvl.I + i][tail...]
#end

#represents scalars
struct VirtualScalarLevel
    expr
    Tv
end

#dimension(lvl::ScalarLevel) = ()
#Base.size(lvl::ScalarLevel) = size(lvl.val)

#function Base.getindex(lvl::ScalarLevel{Ti}, q) where {Ti}
#    return lvl.val[q]
#end

struct VirtualScalarFiber
    q
    lvl
end

function virtual_getindex(lvl::VirtualScalarLevel, q)
    return VirtualScalarFiber(q, lvl)
end

function lower_access(fbr::VirtualScalarFiber)
    return :($(fbr.lvl.expr).val[$(fbr.q)])
end

function lower_assign(fbr::VirtualScalarFiber, ::Nothing, ex)
    :($(fbr.lvl.expr).val[$(fbr.q)] = $ex)
end
function lower_assign(fbr::VirtualScalarFiber, op, ex)
    :($(fbr.lvl.expr).val[$(fbr.q)] = $op($(fbr.lvl.expr).val[$(fbr.q)], $ex))
end