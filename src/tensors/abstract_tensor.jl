abstract type AbstractTensor end
abstract type AbstractVirtualTensor end

"""
    declare!(tns, ctx, init)

Declare the read-only virtual tensor `tns` in the context `ctx` with a starting value of `init` and return it.
Afterwards the tensor is update-only.
"""
declare!(tns, ctx, init) = @assert virtual_default(tns, ctx) == init

"""
    instantiate(tns, ctx, mode, protos)
    
Return an object (usually a looplet nest) capable of unfurling the 
virtual tensor `tns`. Before executing a statement, each
subsequent in-scope access will be initialized with a separate call to
`instantiate`. `protos` is the list of protocols in each case.

The fallback for `instantiate` will iteratively move the last element of
`protos` into the arguments of a function. This allows fibers to specialize on
the last arguments of protos rather than the first, as Finch is column major.
"""
function instantiate(tns, ctx, mode, subprotos, protos...)
    if isempty(subprotos)
        throw(FinchProtocolError("$(typeof(tns)) does not support reads with protocol $(protos)"))
    else
        instantiate(tns, ctx, mode, subprotos[1:end-1], subprotos[end], protos...)
    end
end

"""
    freeze!(tns, ctx)

Freeze the update-only virtual tensor `tns` in the context `ctx` and return it.
This may involve trimming any excess overallocated memory.  Afterwards, the
tensor is read-only.
"""
function freeze! end

"""
    thaw!(tns, ctx)

Thaw the read-only virtual tensor `tns` in the context `ctx` and return it. Afterwards,
the tensor is update-only.
"""
thaw!(tns, ctx) = throw(FinchProtocolError("cannot modify $(typeof(tns)) in place (forgot to declare with .= ?)"))

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
        if dim !== dimless && ref !== dimless #TODO this should be a function like checkdim or something haha
            push!(ctx.code.preamble, quote
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

"""
    virtual_resize!(tns, ctx, dims...)

Resize `tns` in the context `ctx`. This is a
function similar in spirit to `Base.resize!`.
"""
function virtual_resize! end

"""
    moveto(arr, device)

If the array is not on the given device, it creates a new version of this array on that device
and copies the data in to it, according to the `device` trait.
"""
function moveto end

"""
    virtual_moveto(arr, device)

If the virtual array is not on the given device, copy the array to that device. This
function may modify underlying data arrays, but cannot change the virtual itself. This
function is used to move data to the device before a kernel is launched.
"""
function virtual_moveto end