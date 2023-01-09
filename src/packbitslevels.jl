struct PackBitsLevel{D, Ti, Th, Tv}
    I::Ti
    
    hpos::Vector{Ti}
    headers::Vector{Th}
    
    pos::Vector{Ti}
    values::Vector{Tv}
end
const PackBits = PackBitsLevel

PackBitsLevel(D, args...) = PackBitsLevel{D}(args...)
# PackBitsLevel{D}() where {D} = PackBitsLevel{D}(0)
PackBitsLevel{D}(I::Ti) where {D, Ti} = PackBitsLevel{D, Ti, UInt8}(I)
PackBitsLevel{D, Ti}() where {D, Ti} = PackBitsLevel{D, Ti, UInt8}(zero(Ti))
PackBitsLevel{D, Ti, Th}(I::Ti) where {D, Ti, Th} = PackBitsLevel{D, Ti, Th, typeof(D)}(I)
PackBitsLevel{D, Ti, Th, Tv}(I::Ti) where {D, Ti, Th, Tv} = PackBitsLevel{D, Ti, Th, Tv}(I, Ti[1, fill(0, 16)...], Vector{Th}(undef, 16), Ti[1, fill(0, 16)...],Vector{Tv}(undef, 16))
# PackBitsLevel{D, Tv}(I::Ti, pos::Vector{Ti}, bytes::Vector{UInt8}) where {D, Ti, Tv} = RepeatRLELevel{D, Ti, UInt8, Tv}(I, pos, bytes)

PackBitsLevel{Tv}() where {Tv} =  PackBitsLevel{0, Int64, UInt8, Tv}(0)

"""
`f_code(pb)` = [PackBitsLevel](@ref).
"""
f_code(::Val{:pb}) = PackBits
summary_f_code(::PackBitsLevel{D,Ti,Th,Tv}) where {D, Ti, Th, Tv} = "pb($(Tv))"
similar_level(::PackBitsLevel{D,Ti,Th,Tv}) where {D, Ti,Th, Tv} = PackBits{D, Ti,Th,Tv}()


function Base.show(io::IO, lvl::PackBitsLevel{Ti, Th, Tv}) where {Ti, Th, Tv}
    if get(io, :compact, false)
        print(io, "PackBits(")
    else
        print(io, "PackBits{$Ti, $Th, $Tv}(")
    end
    show(IOContext(io, :typeinfo=>Ti), lvl.I)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        # hpos::Vector{Ti}
        # headers::Vector{Th}
        
        # pos::Vector{Ti}
        # values::Vector{Tv}
    
        show(IOContext(io, :typeinfo=>Vector{Ti}), lvl.hpos)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Th}), lvl.headers)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Ti}), lvl.pos)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Tv}), lvl.values)
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:PackBitsLevel})
    p = envposition(fbr.env)
    crds = []
    # for r in fbr.lvl.pos[p]:fbr.lvl.pos[p + 1] - 1
    #     i = fbr.lvl.idx[r]
    #     l = fbr.lvl.ofs[r + 1] - fbr.lvl.ofs[r]
    #     append!(crds, (i - l + 1):i)
    # end

    depth = envdepth(fbr.env)

    print_coord(io, crd) = (print(io, "["); show(io, crd); print(io, "]"))
    get_coord(crd) = crd

    print(io, "│ " ^ depth); print(io, "PackBits ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]")
    display_fiber_data(io, mime, fbr, 1, crds, print_coord, get_coord)
end


@inline Base.ndims(fbr::Fiber{<:PackBitsLevel}) = 1
@inline Base.size(fbr::Fiber{<:PackBitsLevel}) = (fbr.lvl.I,)
@inline Base.axes(fbr::Fiber{<:PackBitsLevel}) = (1:fbr.lvl.I,)
@inline Base.eltype(fbr::Fiber{<:PackBitsLevel{D, Ti, Th, Tv}}) where {D, Ti, Th, Tv} = Tv
@inline default(fbr::Fiber{<:PackBitsLevel{D, Ti, Th, Tv}}) where {D, Ti, Th, Tv} = D

(fbr::Fiber{<:PackBitsLevel})() = fbr
function (fbr::Fiber{<:PackBitsLevel})(i, tail...)
    # lvl = fbr.lvl
    # p = envposition(fbr.env)
    # r = searchsortedfirst(@view(lvl.idx[lvl.pos[p]:lvl.pos[p + 1] - 1]), i)
    # q = lvl.pos[p] + r - 1
    # return lvl.val[q]
    error("Not implemented yet")
end

mutable struct VirtualPackBitsLevel
    ex
    D
    Ti
    Th
    Tv
    I
    pos_alloc
    headers_alloc
    values_alloc
end
function virtualize(ex, ::Type{PackBitsLevel{D, Ti, Th, Tv}}, ctx, tag=:lvl) where {D, Ti, Th, Tv}
    sym = ctx.freshen(tag)
    I = value(:($sym.I), Int)
    headers_alloc = ctx.freshen(sym, :_headers_alloc)
    pos_alloc = ctx.freshen(sym, :_pos_alloc)
    values_alloc = ctx.freshen(sym, :_values_alloc)
    push!(ctx.preamble, quote
        $sym = $ex
        $headers_alloc = length($sym.headers)
        $pos_alloc = length($sym.pos)
        $values_alloc = length($sym.values)
    end)
    VirtualPackBitsLevel(sym, D, Ti, Th, Tv, I, pos_alloc, headers_alloc, values_alloc)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualPackBitsLevel)
    quote
        $PackBitsLevel{$(lvl.D), $(lvl.Ti), $(lvl.Th), $(lvl.Tv)}(
            $(ctx(lvl.I)),
            $(lvl.ex).hpos,
            $(lvl.ex).headers,
            $(lvl.ex).pos,
            $(lvl.ex).values,
        )
    end
end

summary_f_code(lvl::VirtualPackBitsLevel) = "pb($(lvl.Tv))"

getsites(fbr::VirtualFiber{VirtualPackBitsLevel}) =
    [envdepth(fbr.env) + 1, ]

function getsize(fbr::VirtualFiber{VirtualPackBitsLevel}, ctx, mode)
    ext = Extent(literal(1), fbr.lvl.I)
    if mode.kind !== reader
        ext = suggest(ext)
    end
    (ext,)
end

function setsize!(fbr::VirtualFiber{VirtualPackBitsLevel}, ctx, mode, dim)
    fbr.lvl.I = getstop(dim)
    fbr
end

@inline default(fbr::VirtualFiber{<:VirtualPackBitsLevel}) = fbr.lvl.D
Base.eltype(fbr::VirtualFiber{VirtualPackBitsLevel}) = fbr.lvl.Tv

function initialize_level!(fbr::VirtualFiber{VirtualPackBitsLevel}, ctx::LowerJulia, mode)
    lvl = fbr.lvl
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = length($(lvl.ex).pos)
        $(lvl.ex).hpos[1] = 1       
        $(lvl.ex).pos[1] = 1
        $(lvl.headers_alloc) = length($(lvl.ex).headers)
        $(lvl.values_alloc) = length($(lvl.ex).values)
    end)
    return lvl
end

interval_assembly_depth(::VirtualPackBitsLevel) = Inf

#This function is quite simple, since PackBitsLevel don't support reassembly?
#(Maybe? TODO: check this)
function assemble!(fbr::VirtualFiber{VirtualPackBitsLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), getstop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        if $(lvl.pos_alloc) < ($p_stop + 1)
            $(lvl.pos_alloc) = $Finch.regrow!($(lvl.ex).pos, $(lvl.pos_alloc), $p_stop + 1)
            $(lvl.hpos_alloc) = $Finch.regrow!($(lvl.ex).hpos, $(lvl.hpos_alloc), $p_stop + 1)    
        end
    end)
end

function finalize_level!(fbr::VirtualFiber{VirtualPackBitsLevel}, ctx::LowerJulia, mode)
    return fbr.lvl
end

function trim_level!(lvl::VirtualPackBitsLevel, ctx::LowerJulia, pos)
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = $(ctx(pos)) + 1
        resize!($(lvl.ex).pos, $(lvl.pos_alloc))
        resize!($(lvl.ex).hpos, $(lvl.pos_alloc))

        $(lvl.headers_alloc) = $(lvl.ex).hpos[$(lvl.pos_alloc)] - 1
        $(lvl.values_alloc) = $(lvl.ex).pos[$(lvl.pos_alloc)] - 1
        resize!($(lvl.ex).headers, $(lvl.headers_alloc))
        resize!($(lvl.ex).values, $(lvl.values_alloc))
    end)
    return lvl
end


function unfurl(fbr::VirtualFiber{VirtualPackBitsLevel}, ctx, mode, ::Nothing, idx, idxs...)
    if idx.kind === protocol
        @assert idx.mode.kind === literal
        unfurl(fbr, ctx, mode, idx.mode.val, idx.idx, idxs...)
    elseif mode.kind === reader
        unfurl(fbr, ctx, mode, walk, idx, idxs...)
    else
        unfurl(fbr, ctx, mode, extrude, idx, idxs...)
    end
end

#     int32_t j_crd = 0;
# int32_t jmtx_mnistrle_0_pos = mtx_covtyperlep_02_pos[i_crd];
# int32_t pmtx_mnistrle_02_end = mtx_covtyperlep_02_pos[(i_crd + 1)];


# while (jmtx_mnistrle_0_pos < pmtx_mnistrle_02_end) {
#   if (((*((header_type*) &(vals[(jmtx_mnistrle_0_pos)])) >> 15) & 1) == 1) {
#     header_type mtx_covtyperlep_02_run = *((header_type*) &(vals[(jmtx_mnistrle_0_pos)])) & 0x7FFF;
#     int32_t mtx_covtyperlep_0_fill_value = ((int32_t*)(&(vals[(jmtx_mnistrle_0_pos + headerSize)])))[0];
#     jmtx_mnistrle_0_pos += sizeof(int32_t) + headerSize;

#     if (mtx_covtyperlep_0_fill_value){
#       int32_t acc0 = 0;
#       const int32_t bound = j_crd + mtx_covtyperlep_02_run;
#       for (; j_crd < bound; j_crd++) {
#         acc0 += vec_rand_vals[j_crd];
#       }
#       tjout_val += acc0 * mtx_covtyperlep_0_fill_value;
#     }
#   }
#   else {
#     header_type mtx_covtyperlep_02_found_cnt = *((header_type*) &(vals[(jmtx_mnistrle_0_pos)]));
#     jmtx_mnistrle_0_pos+= headerSize;
#     const int32_t bound = j_crd + mtx_covtyperlep_02_found_cnt;
#     for (;j_crd < bound; j_crd++) {
#       tjout_val += vec_rand_vals[j_crd] * ((int32_t*)(&(vals[jmtx_mnistrle_0_pos])))[0];
#       jmtx_mnistrle_0_pos += 4;
#     }
#   }
# }


function unfurl(fbr::VirtualFiber{VirtualPackBitsLevel}, ctx, mode, ::Walk, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    
    my_pos = ctx.freshen(tag, :_pos)
    my_end = ctx.freshen(tag, :_end)

    my_hpos = ctx.freshen(tag, :_hpos)
    my_hend = ctx.freshen(tag, :_hend)

    my_i = ctx.freshen(tag, :_i)
    my_next_i = ctx.freshen(tag, :_next_i)
    my_header = ctx.freshen(tag, :_header_value)


    @assert isempty(idxs)

    is_run = (h) -> :($h >> $(sizeof(lvl.Th)*8 - 1) == 1)
    header_is_run = () -> is_run(:($my_header))
    high_bit_mask = () -> :(~($(lvl.Th)(0x1) << $(sizeof(lvl.Th)*8 - 1)))
    # read_val = (arr, index, Tv) -> :(unsafe_load(Ptr{Tv}(pointer($(arr),$(index)))))
    incr_coord = (i) -> quote
        if $(is_run(:($(lvl.ex).headers[$my_hpos])))
            $i += $(lvl.ex).headers[$my_hpos] & $(high_bit_mask())
        else
            $i += $(lvl.ex).headers[$my_hpos]
        end
    end

    body = Thunk(
        preamble = (quote
            $my_pos = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_end = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            $my_hpos = $(lvl.ex).hpos[$(ctx(envposition(fbr.env)))]
            $my_hend = $(lvl.ex).hpos[$(ctx(envposition(fbr.env))) + 1]

            $my_i = 1
            $my_next_i = 1
            $(incr_coord(:($my_next_i)))
        end),
        body = Stepper(
            seek = (ctx, ext) -> quote
                while $my_pos + 1 < $my_end && $my_next_i < $(ctx(getstart(ext)))
                    # println("RUNNING SEEK!")
                    $my_header = $(lvl.ex).headers[$my_hpos]
                    if $(header_is_run())
                        $my_pos += 1
                        $my_i = $my_next_i
                        $my_next_i += $(lvl.ex).headers[$my_hpos] & $(high_bit_mask())
                    else
                        $my_pos += $(high_bit_mask()) & $my_header
                        $my_i = $my_next_i
                        $my_next_i += $(lvl.ex).headers[$my_hpos]
                    end
                    $my_hpos += 1
                end
            end,
            body = Thunk(
                preamble = quote
                    $my_header = $(lvl.ex).headers[$my_hpos]
                end,
                body = Switch([
                    value(header_is_run()) => Step(
                        # stride = (ctx, idx, ext) -> value(:($my_i + $my_header & $(high_bit_mask()))),
                        stride = (ctx, idx, ext) -> value(my_next_i),
                        chunk = Run(body = Simplify(value(:($(lvl.ex).values[$my_pos]), lvl.Tv))),
                        next = (ctx, idx, ext) -> quote
                            $my_pos += 1
                        end
                    ),
                    literal(true) => Step(
                        stride = (ctx, idx, ext) -> value(my_next_i),
                        chunk = Lookup(
                            body = (i) -> Thunk(
                                # preamble = :(println("Looking up at $($my_pos + $(ctx(i))) - 1")),
                                body = Simplify(value(:($(lvl.ex).values[$my_pos + $(ctx(i)) - 1]), lvl.Tv))
                            )
                        ),
                        next = (ctx, idx, ext) -> quote
                            $my_pos += $(high_bit_mask()) & $my_header
                        end
                    )
                ]),
                epilogue = quote
                    $my_hpos += 1
                    $my_i = $my_next_i
                    $(incr_coord(:($my_next_i)))
                end
            )
        )
    )

    exfurl(body, ctx, mode, idx)
end

# function unfurl(fbr::VirtualFiber{VirtualRepeatRLELevel}, ctx, mode, ::Extrude, idx, idxs...)
#     lvl = fbr.lvl
#     tag = lvl.ex
    
#     my_pos = ctx.freshen(tag, :_pos)
#     my_end = ctx.freshen(tag, :_end)

#     my_hpos = ctx.freshen(tag, :_hpos)
#     my_hend = ctx.freshen(tag, :_hend)

#     my_i = ctx.freshen(tag, :_i)
#     my_next_i = ctx.freshen(tag, :_next_i)
#     my_header = ctx.freshen(tag, :_header_value)

#     @assert isempty(idxs)


# end
