using Base.Broadcast: Broadcasted

"""
    SparseData(lvl)
    
Represents a tensor `A` where `A[:, ..., :, i]` is sometimes entirely default(lvl)
and is sometimes represented by `lvl`.
"""
struct SparseData
    lvl
end
Finch.finch_leaf(x::SparseData) = virtual(x)

Base.ndims(fbr::SparseData) = 1 + ndims(fbr.lvl)
default(fbr::SparseData) = default(fbr.lvl)
Base.eltype(fbr::SparseData) = eltype(fbr.lvl)

"""
    RepeatData(lvl)
    
Represents a tensor `A` where `A[:, ..., :, i]` is sometimes entirely default(lvl)
and is sometimes represented by repeated runs of `lvl`.
"""
struct RepeatData
    lvl
end
Finch.finch_leaf(x::RepeatData) = virtual(x)

Base.ndims(fbr::RepeatData) = 1 + ndims(fbr.lvl)
default(fbr::RepeatData) = default(fbr.lvl)
Base.eltype(fbr::RepeatData) = eltype(fbr.lvl)

"""
    DenseData(lvl)
    
Represents a tensor `A` where each `A[:, ..., :, i]` is represented by `lvl`.
"""
struct DenseData
    lvl
end
Finch.finch_leaf(x::DenseData) = virtual(x)
default(fbr::DenseData) = default(fbr.lvl)

Base.ndims(fbr::DenseData) = 1 + ndims(fbr.lvl)
Base.eltype(fbr::DenseData) = eltype(fbr.lvl)

"""
    ExtrudeData(lvl)
    
Represents a tensor `A` where `A[:, ..., :, 1]` is the only slice, and is represented by `lvl`.
"""
struct ExtrudeData
    lvl
end
Finch.finch_leaf(x::ExtrudeData) = virtual(x)
default(fbr::ExtrudeData) = default(fbr.lvl)
Base.ndims(fbr::ExtrudeData) = 1 + ndims(fbr.lvl)
Base.eltype(fbr::ExtrudeData) = eltype(fbr.lvl)

"""
    HollowData(lvl)
    
Represents a tensor which is represented by `lvl` but is sometimes entirely `default(lvl)`.
"""
struct HollowData
    lvl
end
Finch.finch_leaf(x::HollowData) = virtual(x)
default(fbr::HollowData) = default(fbr.lvl)

Base.ndims(fbr::HollowData) = ndims(fbr.lvl)
Base.eltype(fbr::HollowData) = eltype(fbr.lvl)

"""
    ElementData(default, eltype)
    
Represents a scalar element of type `eltype` and default `default`.
"""
struct ElementData
    default
    eltype
end
Finch.finch_leaf(x::ElementData) = virtual(x)
default(fbr::ElementData) = fbr.default

Base.ndims(fbr::ElementData) = 0
Base.eltype(fbr::ElementData) = fbr.eltype

"""
    data_rep(tns)

Return a trait object representing everything that can be learned about the data
based on the storage format (type) of the tensor
"""
data_rep(tns) = (DenseData^(ndims(tns)))(ElementData(default(tns), eltype(tns)))

data_rep(T::Type{<:Number}) = ElementData(zero(T), T)

"""
    data_rep(tns)

Normalize a trait object to collapse subfiber information into the parent tensor.
"""
collapse_rep(fbr) = fbr

collapse_rep(fbr::HollowData) = collapse_rep(fbr, collapse_rep(fbr.lvl))
collapse_rep(::HollowData, lvl::HollowData) = collapse_rep(lvl)
collapse_rep(::HollowData, lvl) = HollowData(collapse_rep(lvl))

collapse_rep(fbr::DenseData) = collapse_rep(fbr, collapse_rep(fbr.lvl))
collapse_rep(::DenseData, lvl::HollowData) = collapse_rep(SparseData(lvl.lvl))
collapse_rep(::DenseData, lvl) = DenseData(collapse_rep(lvl))

collapse_rep(fbr::ExtrudeData) = collapse_rep(fbr, collapse_rep(fbr.lvl))
collapse_rep(::ExtrudeData, lvl::HollowData) = HollowData(collapse_rep(ExtrudeData(lvl.lvl)))
collapse_rep(::ExtrudeData, lvl) = ExtrudeData(collapse_rep(lvl))

collapse_rep(fbr::SparseData) = collapse_rep(fbr, collapse_rep(fbr.lvl))
collapse_rep(::SparseData, lvl::HollowData) = collapse_rep(SparseData(lvl.lvl))
collapse_rep(::SparseData, lvl) = SparseData(collapse_rep(lvl))

collapse_rep(fbr::RepeatData) = collapse_rep(fbr, collapse_rep(fbr.lvl))
collapse_rep(::RepeatData, lvl::HollowData) = collapse_rep(RepeatData(lvl.lvl))
collapse_rep(::RepeatData, lvl) = RepeatData(collapse_rep(lvl))

"""
    map_rep(f, args...)

Return a storage trait object representing the result of mapping `f` over
storage traits `args`. Assumes representation is collapsed.
"""
function map_rep(f, args...)
    map_rep_def(f, map(arg -> pad_data_rep(arg, maximum(ndims, args)), args))
end

pad_data_rep(rep, n) = ndims(rep) < n ? pad_data_rep(ExtrudeData(rep), n) : rep

"""
    extrude_rep(tns, dims)
Expand the representation of `tns` to the dimensions `dims`, which must have length(ndims(tns)) and be in ascending order.
"""
extrude_rep(tns, dims) = extrude_rep_def(tns, reverse(dims)...)
extrude_rep_def(tns) = tns
extrude_rep_def(tns::HollowData, dims...) = HollowData(extrude_rep_def(tns.lvl, dims...))
extrude_rep_def(tns::SparseData, dim, dims...) = SparseData(pad_data_rep(extrude_rep_def(tns.lvl, dims...), dim - 1))
extrude_rep_def(tns::RepeatData, dim, dims...) = RepeatData(pad_data_rep(extrude_rep_def(tns.lvl, dims...), dim - 1))
extrude_rep_def(tns::DenseData, dim, dims...) = DenseData(pad_data_rep(extrude_rep_def(tns.lvl, dims...), dim - 1))
extrude_rep_def(tns::ExtrudeData, dim, dims...) = ExtrudeData(pad_data_rep(extrude_rep_def(tns.lvl, dims...), dim - 1))

struct MapRepExtrudeStyle end
struct MapRepSparseStyle end
struct MapRepDenseStyle end
struct MapRepRepeatStyle end
struct MapRepElementStyle end

combine_style(a::MapRepSparseStyle, b::MapRepExtrudeStyle) = a
combine_style(a::MapRepSparseStyle, b::MapRepSparseStyle) = a
combine_style(a::MapRepSparseStyle, b::MapRepDenseStyle) = a
combine_style(a::MapRepSparseStyle, b::MapRepRepeatStyle) = a
combine_style(a::MapRepSparseStyle, b::MapRepElementStyle) = a

combine_style(a::MapRepDenseStyle, b::MapRepExtrudeStyle) = a
combine_style(a::MapRepDenseStyle, b::MapRepDenseStyle) = a
combine_style(a::MapRepDenseStyle, b::MapRepRepeatStyle) = a
combine_style(a::MapRepDenseStyle, b::MapRepElementStyle) = a

combine_style(a::MapRepRepeatStyle, b::MapRepExtrudeStyle) = a
combine_style(a::MapRepRepeatStyle, b::MapRepRepeatStyle) = a
combine_style(a::MapRepRepeatStyle, b::MapRepElementStyle) = a

combine_style(a::MapRepElementStyle, b::MapRepElementStyle) = a

map_rep_style(r::ExtrudeData) = MapRepExtrudeStyle()
map_rep_style(r::SparseData) = MapRepSparseStyle()
map_rep_style(r::DenseData) = MapRepDenseStyle()
map_rep_style(r::RepeatData) = MapRepRepeatStyle()
map_rep_style(r::ElementData) = MapRepElementStyle()

map_rep_def(f, args) = map_rep_def(mapreduce(map_rep_style, result_style, args), f, args)

map_rep_child(r::ExtrudeData) = r.lvl
map_rep_child(r::SparseData) = r.lvl
map_rep_child(r::DenseData) = r.lvl
map_rep_child(r::RepeatData) = r.lvl

map_rep_def(::MapRepDenseStyle, f, args) = DenseData(map_rep_def(f, map(map_rep_child, args)))
map_rep_def(::MapRepExtrudeStyle, f, args) = ExtrudeData(map_rep_def(f, map(map_rep_child, args)))

function map_rep_def(::MapRepSparseStyle, f, args)
    lvl = map_rep_def(f, map(map_rep_child, args))
    if all(arg -> isa(arg, SparseData), args)
        return SparseData(lvl)
    end
    for (n, arg) in enumerate(args)
        if arg isa SparseData
            args_2 = map(arg -> value(gensym(), eltype(arg)), collect(args))
            args_2[n] = literal(default(arg))
            if finch_leaf(simplify(call(f, args_2...), LowerJulia())) == literal(default(lvl))
                return SparseData(lvl)
            end
        end
    end
    return DenseData(lvl)
end

function map_rep_def(::MapRepRepeatStyle, f, args)
    lvl = map_rep_def(f, map(map_rep_child, args))
    if all(arg -> isa(arg, RepeatData), args)
        return RepeatData(lvl)
    end
    for (n, arg) in enumerate(args)
        if arg isa RepeatData
            args_2 = map(arg -> value(gensym(), eltype(arg)), collect(args))
            args_2[n] = literal(default(arg))
            if finch_leaf(simplify(call(f, args_2...), LowerJulia())) == literal(default(lvl))
                return RepeatData(lvl)
            end
        end
    end
    return DenseData(lvl)
end

function map_rep_def(::MapRepElementStyle, f, args)
    return ElementData(f(map(default, args)...), combine_eltypes(f, (args...,)))
end

"""
    aggregate_rep(op, init, tns, dims)

Return a trait object representing the result of reducing a tensor represented
by `tns` on `dims` by `op` starting at `init`.
"""
function aggregate_rep(op, init, tns, dims)
    aggregate_rep_def(op, init, tns, reverse(map(n -> n in dims, 1:ndims(tns)))...)
end

#TODO I think HollowData here is wrong
aggregate_rep_def(op, z, fbr::HollowData, drops...) = HollowData(aggregate_rep_def(op, z, fbr.lvl, drops...))
function aggregate_rep_def(op, z, lvl::HollowData, drop, drops...)
    if op(z, default(lvl)) == z
        HollowData(aggregate_rep_def(op, z, lvl.lvl, drops...))
    else
        HollowData(aggregate_rep_def(op, z, lvl.lvl, drops...))
    end
end

function aggregate_rep_def(op, z, lvl::SparseData, drop, drops...)
    if drop
        aggregate_rep_def(op, z, lvl.lvl, drops...)
    else
        if op(z, default(lvl)) == z
            SparseData(aggregate_rep_def(op, z, lvl.lvl, drops...))
        else
            DenseData(aggregate_rep_def(op, z, lvl.lvl, drops...))
        end
    end
end

function aggregate_rep_def(op, z, lvl::RepeatData, drop, drops...)
    if drop
        aggregate_rep_def(op, z, lvl.lvl, drops...)
    else
        RepeatData(aggregate_rep_def(op, z, lvl.lvl, drops...))
    end
end

function aggregate_rep_def(op, z, lvl::DenseData, drop, drops...)
    if drop
        aggregate_rep_def(op, z, lvl.lvl, drops...)
    else
        DenseData(aggregate_rep_def(op, z, lvl.lvl, drops...))
    end
end


function aggregate_rep_def(op, z, lvl::ExtrudeData, drop, drops...)
    if drop
        aggregate_rep_def(op, z, lvl.lvl, drops...)
    else
        ExtrudeData(aggregate_rep_def(op, z, lvl.lvl, drops...))
    end
end

aggregate_rep_def(op, z, lvl::ElementData) = ElementData(z, fixpoint_type(op, z, lvl))

"""
    permutedims_rep(tns, perm)

Return a trait object representing the result of permuting a tensor represented
by `tns` to the permutation `perm`.
"""
function permutedims_rep(tns, perm)
    j = 1
    n = 1
    dst_dims = []
    src_dims = []
    diags = []
    for i = 1:length(perm)
        push!(dst_dims, n)
        while j <= length(perm) && perm[j] <= i
            if perm[j] < i
                n += 1
                push!(diags, (perm[j], n))
            end
            j += 1
            push!(src_dims, n)
        end
        n += 1
    end
    src = extrude_rep(tns, src_dims)
    for mask_dims in diags
        mask = extrude_rep(DenseData(SparseData(ElementData(false, Bool))), mask_dims)
        src = map_rep(filterop(default(src)), pad_data_rep(mask, ndims(src)), src)
    end
    aggregate_rep(initwrite(default(tns)), default(tns), src, setdiff(src_dims, dst_dims))
end

"""
    rep_construct(tns, protos...)

Construct a tensor suitable to hold data with a representation described by
`tns`. Assumes representation is collapsed.
"""
function rep_construct end
rep_construct(fbr) = rep_construct(fbr, [nothing for _ in 1:ndims(fbr)])
rep_construct(fbr::HollowData, protos) = rep_construct_hollow(fbr.lvl, protos)
rep_construct_hollow(fbr::DenseData, protos) = Tensor(construct_level_rep(SparseData(fbr.lvl), protos...))
rep_construct_hollow(fbr::ExtrudeData, protos) = Tensor(construct_level_rep(SparseData(fbr.lvl), protos...))
rep_construct_hollow(fbr::RepeatData, protos) = Tensor(construct_level_rep(fbr, protos...))
rep_construct_hollow(fbr::SparseData, protos) = Tensor(construct_level_rep(fbr, protos...))
rep_construct(fbr, protos) = Tensor(construct_level_rep(fbr, protos...))

construct_level_rep(fbr::SparseData, proto::Union{Nothing, typeof(walk), typeof(extrude)}, protos...) = SparseDict(construct_level_rep(fbr.lvl, protos...))
construct_level_rep(fbr::SparseData, proto::Union{typeof(laminate)}, protos...) = SparseDict(construct_level_rep(fbr.lvl, protos...))
construct_level_rep(fbr::RepeatData, proto::Union{Nothing, typeof(walk), typeof(extrude)}, protos...) = SparseRLE(construct_level_rep(fbr.lvl, protos...))
construct_level_rep(fbr::RepeatData, proto::Union{typeof(laminate)}, protos...) = SparseDict(construct_level_rep(fbr.lvl, protos...))
construct_level_rep(fbr::DenseData, proto, protos...) = Dense(construct_level_rep(fbr.lvl, protos...))
construct_level_rep(fbr::ExtrudeData, proto, protos...) = Dense(construct_level_rep(fbr.lvl, protos...), 1)
construct_level_rep(fbr::ElementData) = Element{fbr.default, fbr.eltype}()

"""
    fiber_ctr(tns, protos...)

Return an expression that would construct a tensor suitable to hold data with a
representation described by `tns`. Assumes representation is collapsed.
"""
function fiber_ctr end
fiber_ctr(fbr) = fiber_ctr(fbr, [nothing for _ in 1:ndims(fbr)])
fiber_ctr(fbr::HollowData, protos) = fiber_ctr_hollow(fbr.lvl, protos)
fiber_ctr_hollow(fbr::DenseData, protos) = :(Tensor($(level_ctr(SparseData(fbr.lvl), protos...))))
fiber_ctr_hollow(fbr::ExtrudeData, protos) = :(Tensor($(level_ctr(SparseData(fbr.lvl), protos...))))
fiber_ctr_hollow(fbr::SparseData, protos) = :(Tensor($(level_ctr(fbr, protos...))))
fiber_ctr_hollow(fbr::RepeatData, protos) = :(Tensor($(level_ctr(fbr, protos...))))
fiber_ctr(fbr, protos) = :(Tensor($(level_ctr(fbr, protos...))))

level_ctr(fbr::SparseData, proto::Union{Nothing, typeof(walk), typeof(extrude)}, protos...) = :(SparseDict($(level_ctr(fbr.lvl, protos...))))
level_ctr(fbr::SparseData, proto::Union{typeof(laminate)}, protos...) = :(SparseDict($(level_ctr(fbr.lvl, protos...))))
level_ctr(fbr::RepeatData, proto::Union{Nothing, typeof(walk), typeof(extrude)}, protos...) = :(SparseRLE($(level_ctr(fbr.lvl, protos...))))
level_ctr(fbr::RepeatData, proto::Union{typeof(laminate)}, protos...) = :(SparseDict($(level_ctr(fbr.lvl, protos...))))
level_ctr(fbr::DenseData, proto, protos...) = :(Dense($(level_ctr(fbr.lvl, protos...))))
level_ctr(fbr::ExtrudeData, proto, protos...) = :(Dense($(level_ctr(fbr.lvl, protos...)), 1))
level_ctr(fbr::RepeatData, proto::Union{Nothing, typeof(walk), typeof(extrude)}) = :(Repeat{$(fbr.default), $(fbr.eltype)}())
level_ctr(fbr::RepeatData, proto::Union{typeof(laminate)}) = level_ctr(DenseData(ElementData(fbr.default, fbr.eltype)), proto)
level_ctr(fbr::ElementData) = :(Element{$(fbr.default), $(fbr.eltype)}())