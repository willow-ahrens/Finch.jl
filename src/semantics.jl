"""
    declare!(tns, ctx, init)

Declare the read-only virtual tensor `tns` in the context `ctx` with a starting value of `init` and return it.
Afterwards the tensor is update-only.
"""
declare!(tns, ctx, init) = @assert something(virtual_default(tns)) == init

"""
    get_reader(tns, ctx, protos...)
    
Return an object (usually a looplet nest) capable of reading the read-only
virtual tensor `tns`.  As soon as a read-only tensor enters scope, each
subsequent read access will be initialized with a separate call to
`get_reader`. `protos` is the list of protocols in each case.
"""
get_reader(tns, ctx, protos...) = tns #throw(FormatLimitation("$(typeof(tns)) does not support reads with protocol $(protos)"))

"""
    get_updater(tns, ctx, protos...)
    
Return an object (usually a looplet nest) capable of updating the update-only
virtual tensor `tns`.  As soon as an update only tensor enters scope, each
subsequent update access will be initialized with a separate call to
`get_updater`.  `protos` is the list of protocols in each case.
"""
get_updater(tns, ctx, protos...) = tns #throw(FormatLimitation("$(typeof(tns)) does not support updates with protocol $(protos)"))

"""
    freeze!(tns, ctx)

Freeze the update-only virtual tensor `tns` in the context `ctx` and return it.
Afterwards, the tensor is read-only.
"""
function freeze! end

"""
    thaw!(tns, ctx)

Thaw the read-only virtual tensor `tns` in the context `ctx` and return it. Afterwards,
the tensor is update-only.
"""
thaw!(tns, ctx) = throw(FormatLimitation("cannot modify $(typeof(tns)) in place (forgot to declare with .= ?)"))

"""
    trim!(tns, ctx)

Before returning a tensor from the finch program, trim any excess overallocated memory.
"""
trim!(tns, ctx) = tns

"""
    getresults(prgm)

Return an iterator over the properly modified tensors in a finch program
"""
function getresults(node::FinchNode)
    if node.kind === sequence
        return mapreduce(getresults, vcat, node.bodies, init=[])
    elseif node.kind === declare || node.kind === thaw
        return [node.tns]
    else
        return []
    end
end

"""
    getunbound(stmt)

Return an iterator over the indices in a Finch program that have yet to be bound.
```julia
julia> getunbound(@finch_program @loop i :a[i, j] += 2)
[j]
julia> getunbound(@finch_program i + j * 2 * i)
[i, j]
```
"""
getunbound(ex) = istree(ex) ? mapreduce(getunbound, union, arguments(ex), init=[]) : []

function getunbound(ex::FinchNode)
    if ex.kind === index
        return [ex]
    elseif ex.kind === loop
        return setdiff(union(getunbound(ex.body), getunbound(ex.ext)), getunbound(ex.idx))
    elseif istree(ex)
        return mapreduce(Finch.getunbound, union, arguments(ex), init=[])
    else
        return []
    end
end


"""
    default(arr)

Return the initializer for `arr`. For SparseArrays, this is 0. Often, the
`default` value becomes the `fill` or `background` value of a tensor.
"""
function default end

function virtual_default(x::FinchNode)
    if x.kind === virtual
        virtual_default(x.val)
    else
        error("unimplemented")
    end
end

function virtual_eltype(x::FinchNode)
    if x.kind === virtual
        virtual_eltype(x.val)
    else
        error("unimplemented")
    end
end

virtual_elaxis(tns, ctx, dims...) = nodim

function virtual_resize!(tns, ctx, dims...)
    for (dim, ref) in zip(dims, virtual_size(tns, ctx))
        if dim !== nodim && ref !== nodim #TODO this should be a function like checkdim or something haha
            push!(ctx.preamble, quote
                $(ctx(getstart(dim))) == $(ctx(getstart(ref))) || throw(DimensionMismatch("mismatched dimension start"))
                $(ctx(getstop(dim))) == $(ctx(getstop(ref))) || throw(DimensionMismatch("mismatched dimension stop"))
            end)
        end
    end
    (tns, nodim)
end

"""
    virtual_size(tns, ctx)

Return a tuple of the dimensions of `tns` in the context `ctx` with access
mode `mode`. This is a function similar in spirit to `Base.axes`.
"""
function virtual_size end

virtual_size(tns, ctx, eldim) = virtual_size(tns, ctx)
function virtual_size(tns::FinchNode, ctx, eldim = nodim)
    if tns.kind === variable
        return virtual_size(ctx.bindings[tns], ctx, eldim)
    else
        return error("unimplemented")
    end
end

function virtual_elaxis(tns::FinchNode, ctx, dims...)
    if tns.kind === variable
        return virtual_elaxis(ctx.bindings[tns], ctx, dims...)
    else
        return error("unimplemented")
    end
end

function virtual_resize!(tns::FinchNode, ctx, dims...)
    if tns.kind === variable
        return (ctx.bindings[tns], eldim) = virtual_resize!(ctx.bindings[tns], ctx, dims...)
    else
        error("unimplemented")
    end
end