using Finch
using Pigeon
using Test
using MacroTools

using Finch: VirtualAbstractArray, Run, Spike, Extent, Scalar, Cases, Stream, Packet

Base.@kwdef struct ChunkVector
    body
    ext
    name = gensym()
end

Pigeon.lower_axes(arr::ChunkVector, ctx::Finch.LowerJuliaContext) = (arr.ext,)
Pigeon.getsites(arr::ChunkVector) = (1,)
Pigeon.getname(arr::ChunkVector) = arr.name
Pigeon.make_style(root, ctx::Finch.LowerJuliaContext, node::Access{ChunkVector}) = Finch.ChunkStyle()
function Pigeon.visit!(node::Access{ChunkVector}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle)
    return Access(node.tns.body, node.mode, node.idxs)
end

@testset "Finch.jl" begin
    A = VirtualAbstractArray(1, :A, :A)
    B = VirtualAbstractArray(1, :B, :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = ChunkVector(Run(VirtualAbstractArray(0, :A, :A), Extent(1, 10)), Extent(1, 10), :A)
    B = ChunkVector(Run(VirtualAbstractArray(0, :B, :B), Extent(1, 10)), Extent(1, 10), :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = VirtualAbstractArray(1, :A, :A)
    B = ChunkVector(Spike(0, 1, Extent(1, 10)), Extent(1, 10), :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = ChunkVector(Spike(VirtualAbstractArray(0, :A, :A1), VirtualAbstractArray(0, :A, :A2), Extent(1, 10)), Extent(1, 10), :A)
    B = ChunkVector(Spike(0, 1, Extent(1, 10)), Extent(1, 10), :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = ChunkVector(Spike(VirtualAbstractArray(0, :A, :A1), VirtualAbstractArray(0, :A, :A2), Extent(1, 10)), Extent(1, 10), :A)
    B = ChunkVector(Cases([
        :foobar => Spike(0, 1, Extent(1, 10))
        true => Run(42, Extent(1, 10))
    ]), Extent(1, 10), :B)
    println(lower_julia(@i @loop i A[i] = B[i]))

    A = ChunkVector(Stream(
        extent = Extent(1, 10),
        body = (ctx) -> begin
            my_i = gensym(:stream_i0)
            my_i′ = gensym(:stream_i1)
            my_p = gensym(:stream_p)
            push!(ctx.preamble, :($my_p = 2))
            push!(ctx.preamble, :($my_i = lvl.idx[$my_p]))
            push!(ctx.preamble, :($my_i′ = lvl.idx[$my_p + 1]))
            Packet(
                body = (ctx, start, stop) -> begin
                    push!(ctx.epilogue, :($my_p += ($my_i == $stop)))
                    push!(ctx.epilogue, :($my_i = $my_i′))
                    push!(ctx.epilogue, :($my_i′ = lvl.idx[$my_p + 1]))
                    Spike(
                        body = 0,
                        tail = (ctx) -> Virtual(:(lvl.val[$my_i])),
                        ext = Extent(start, stop)
                    )
                end,
                step = (ctx, start, stop) -> my_i
            )
        end),
        Extent(1, 10), :A)
    
    B = VirtualAbstractArray(1, :B, :B)

    println(lower_julia(@i @loop i B[i] = A[i]))

end