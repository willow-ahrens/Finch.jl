module TensorMarketExt 

using Finch

isdefined(Base, :get_extension) ? (using TensorMarket) : (using ..TensorMarket)

function Finch.fttread(filename::AbstractString, infoonly = false, retcoord=false)
    infoonly && return ttread(filename, true)
    out = ttread(filename, false, retcoord)
    if out isa Tuple
        (I, V, shape, coords...) = out
        A = fsparse(I, V, shape)
        if retcoord
            (A, coords...)
        else
            A
        end
    else
        out
    end
end

function Finch.fttwrite(filename::AbstractString, A)
    ttwrite(filename, ffindnz(A)..., size(A))
end

function Finch.ftnsread(filename::AbstractString)
    fsparse(tnsread(filename)...)
end

function Finch.ftnswrite(filename::AbstractString, A)
    tnswrite(filename, ffindnz(A)...)
end

end