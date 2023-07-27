"""
    declare!(tns, ctx, init)

Declare the read-only virtual tensor `tns` in the context `ctx` with a starting value of `init` and return it.
Afterwards the tensor is update-only.
"""
declare!(tns, ctx, init) = @assert something(virtual_default(tns, ctx)) == init

"""
    instantiate_reader(tns, ctx, protos...)
    
Return an object (usually a looplet nest) capable of reading the read-only
virtual tensor `tns`.  As soon as a read-only tensor enters scope, each
subsequent read access will be initialized with a separate call to
`instantiate_reader`. `protos` is the list of protocols in each case.
"""
instantiate_reader(tns, ctx, protos...) = throw(FormatLimitation("$(typeof(tns)) does not support reads with protocol $(protos)"))

"""
    instantiate_updater(tns, ctx, protos...)
    
Return an object (usually a looplet nest) capable of updating the update-only
virtual tensor `tns`.  As soon as an update only tensor enters scope, each
subsequent update access will be initialized with a separate call to
`instantiate_updater`.  `protos` is the list of protocols in each case.
"""
instantiate_updater(tns, ctx, protos...) = throw(FormatLimitation("$(typeof(tns)) does not support updates with protocol $(protos)"))

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

"""
    virtual default(arr)

Return the initializer for virtual array `arr`.
"""
function virtual_default end

"""
    virtual_eltype(arr)

Return the element type of the virtual tensor `arr`.
"""
function virtual_eltype end

function virtual_resize!(tns, ctx, dims...)
    for (dim, ref) in zip(dims, virtual_size(tns, ctx))
        if dim !== mkdim && ref !== mkdim #TODO this should be a function like checkdim or something haha
            push!(ctx.preamble, quote
                $(ctx(getstart(dim))) == $(ctx(getstart(ref))) || throw(DimensionMismatch("mismatched dimension start"))
                $(ctx(getstop(dim))) == $(ctx(getstop(ref))) || throw(DimensionMismatch("mismatched dimension stop"))
            end)
        end
    end
    tns
end

"""
    virtual_size(tns, ctx)

Return a tuple of the dimensions of `tns` in the context `ctx`. This is a
function similar in spirit to `Base.axes`.
"""
function virtual_size end