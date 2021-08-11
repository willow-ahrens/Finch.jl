module Thrush

export SparseLevel
export SparseFiber
export DenseLevel
export DenseFiber
export ScalarLevel

#represents consecutive groups of nonzero fibers
struct SparseLevel{Tv, Ti, N} <: AbstractVector{Any} #should have fiber eltype
    Q::Ti
    I::Ti
    pos::Vector{Ti}
    idx::Vector{Ti}
    child
end

dimension(lvl::SparseLevel) = (lvl.I, dimension(lvl.child)...)
Base.size(lvl::SparseLevel) = lvl.Q

struct SparseFiber{Tv, Ti, N} <: AbstractArray{Tv, N}
    q::Ti
    lvl::SparseLevel{Tv, Ti, N}
end

function Base.getindex(lvl::SparseLevel{Ti}, q) where {Ti}
    return SparseFiber(q, lvl)
end

Base.size(fbr::SparseFiber) = dimension(fbr.lvl)

function Base.getindex(fbr::SparseFiber{Tv, Ti}, i, tail...) where {Tv, Ti}
    r = searchsorted(@view(fbr.lvl.idx[fbr.lvl.pos[fbr.q]:fbr.lvl.pos[fbr.q + 1] - 1]), i)
    length(r) == 0 ? zero(Tv) : fbr.lvl.child[fbr.lvl.pos[fbr.q] + first(r) - 1][tail...]
end

#represents consecutive modes of nonzero fibers
struct DenseLevel{Tv, Ti, N} <: AbstractVector{Any} #should have fiber eltype
    Q::Ti
    I::Ti
    child
end

dimension(lvl::DenseLevel) = (lvl.I, dimension(lvl.child)...)
Base.size(lvl::DenseLevel) = lvl.Q

struct DenseFiber{Tv, Ti, N} <: AbstractArray{Tv, N}
    q::Ti
    lvl::DenseLevel{Tv, Ti, N}
end

function Base.getindex(lvl::DenseLevel{Ti}, q) where {Ti}
    return DenseFiber(q, lvl)
end

Base.size(fbr::DenseFiber) = dimension(fbr.lvl)

function Base.getindex(fbr::DenseFiber{Ti}, i, tail...) where {Ti}
    fbr.lvl.child[(fbr.q - 1) * fbr.lvl.I + i][tail...]
end

#represents scalars
struct ScalarLevel{Tv, V <: AbstractVector{Tv}} <: AbstractVector{Tv}
    val::V
end

dimension(lvl::ScalarLevel) = ()
Base.size(lvl::ScalarLevel) = size(lvl.val)

function Base.getindex(lvl::ScalarLevel{Ti}, q) where {Ti}
    return lvl.val[q]
end

function lower(ex::Forall)
    idx = ex.idx
    lvls = get_tensors_with_idx(ex, idx)
    for tns in tensors(ex)
        replace(ex, tns=>)
    end
    iterators = map(get_iterator, tns)
    return quote
        $setup_iterators
        i = 0
        #The blocks here are two-part blocks, one for the spikes and one for the cleanup afterwards.
        $(unfold(i, iterators))
    end
end

function unfold(i, expression)
    style = unfold_style(expression)
    unfold(i, expression, style)
end

function unfold(i, blockstyle)
    block_ind = 0
    while $(!any(isempty(iterators)))
        i′ = $(min(map(get_block_end, )))
        $(
            process the block from i to i′ = min(block_ends)
            process_block(expression with blocks inserted)
        )
        if hascoord(itr1, coord) && hascoord(itr2, coord)
            do_filled
        elseif hascoord(itr1 && !itr2)
            do_filled
        elseif hascoord(itr1 && !itr2)
            do_filled
        end
        end
        if hascoord(itr2)
        end
    end
end

function unfold(i, expression, combinatorstyle)
    combinators = get_combinators(expression)
    for combo in product(combinators)
        switch = :(true)
        for (condition, block, iterator) in combo
            switch = :($switch && $condition)
            replace!(expression, iterator => block)
        end
        unfold(i, expression)
    end
    advance_blocks
end

function unfold(i, expression, loopcleanupstyle)
    combinators = get_splits(expression)
    while any 4
    while any 3
    while any 2
    while any 1
end

struct Spike
    default
    parent
end

lower_style(b::Spike) = SpikeStyle()

truncate(b::Spike, i′) = Combinator(:(i′ == block_end(b.parent)), Spike(b.default, b.parent), Run(b.default))

struct Run
    default
end

lower_style(b::Run) = SingleStyle()

truncate(b::Run, i′) = b

#okay, so the next step is coiteration

struct Call{F, Args}
    f::F
    args::Args
end

struct Forall{I, Ops}
    i::I
    ops::Ops
end

function lower(ex::Forall{I, Ops}, pos, iter)
    i = ex.i
    ex = map(ex) do tns
        if tns isa Level && tns.i == ex.i
            push!(iters, tns.itr)
            return tns.child
        end
    end
end