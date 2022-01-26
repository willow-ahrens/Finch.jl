"""
dimensionalization assumes foralls have unique indices.
"""

function dimensionalize!(root, ctx)
    Postwalk(node -> (collect_dimensions!(node, ctx); node))(root)
end

collect_dimensions!(node, ctx) = nothing

function collect_dimensions!(node::Access, ctx)
    dims = getdims(ctx)
    if !istree(node.tns)
        for (idx, lowered_axis, n) in zip(getname.(node.idxs), lower_axes(node.tns, ctx), getsites(node.tns))
            site = (getname(node.tns), n)
            if !haskey(dims, site)
                push!(dims.labels, site)
                dims.lowered_axes[site] = lowered_axis
            end
            site_axis = dims[site]
            if !haskey(dims, idx)
                push!(dims.labels, idx)
                dims.lowered_axes[union!(dims.labels, site, idx)] = site_axis
            elseif !in_same_set(dims.labels, idx, site)
                idx_axis = dims[idx]
                dims.lowered_axes[union!(dims.labels, site, idx)] =
                    site_axis === nothing ? idx_axis :
                    idx_axis === nothing ? site_axis :
                    lower_axis_merge(ctx, idx_axis, site_axis)
            end
        end
    end
end

struct Dimensions
    labels
    lowered_axes
end

getdims(dims::Dimensions) = dims

Dimensions() = Dimensions(DisjointSets{Any}(), Dict())

#there is a wacky julia bug that is fixed on 70cc57cb36. It causes find_root! to sometimes
#return the right index into dims.labels.revmap, but reinterprets the access as the wrong type.
#not sure which commit actually fixed this, but I need to move on with my life.
Base.getindex(dims::Dimensions, idx) = dims.lowered_axes[find_root!(dims.labels, idx)]
Base.setindex!(dims::Dimensions, ext, idx) = dims.lowered_axes[find_root!(dims.labels, idx)] = ext
Base.haskey(dims::Dimensions, idx) = idx in dims.labels
function isdimensionalized(dims::Dimensions, node::Access)
    if !istree(node.tns)
        for (n, idx) in zip(getsites(node.tns), getname.(node.idxs))
            site = (getname(node.tns), n)
            (haskey(dims, idx) && haskey(dims, site) && in_same_set(dims.labels, idx, site)) || return false
        end
    end
    return true
end

function getdims end
function lower_axes end
function lower_axis_merge end