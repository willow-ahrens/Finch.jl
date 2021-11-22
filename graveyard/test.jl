include("redo.jl")

pretty(ex) = MacroTools.prettify(ex, alias=false)

A = Spike(
    extent = Extent(1, 42),
    body = (ctx) -> 0,
    tail = (ctx) -> Virtual{Any}(:(in[$my_i])),
)

B = Virtual{Vector{Any}}(:(out))

println(pretty(Pigeon.visit!((@i @loop i B[i] = A[i]), LowerJuliaContext())))

#=
A = Pipeline([
    Phase(
        body = (ctx) -> begin
            (my_p, my_p′, my_i′) = (gensym(:p, :A), gensym(:p′, :A), gensym(:i′, :A))
            push!(ctx.preamble, quote
                $my_p = lvl.pos[lvl.parent_p]
                $my_p′ = lvl.pos[lvl.parent_p + 1]
                $my_i′ = lvl.idx[$my_p′ - 1]
            end)
            Stream(
                extent = Extent(Bottom(), Virtual{Int}(my_i′)),
                body = (ctx) -> begin
                    my_i = gensym(:i)
                    push!(ctx.preamble, :($my_i = lvl.idx[$my_p′ - 1]))
                    push!(ctx.epilogue, cleanup = :($my_p += 1))
                    Spike(
                        extent = Extent(Bottom(), Virtual(my_i)),
                        default = (ctx) -> 0,
                        value = (ctx) -> Virtual(:(lvl.val[$my_i])),
                    )
                end
            )
        end,
    ),
    Phase(
        body = (ctx) -> Run(
            body = (ctx) -> 0,
            extent = Extent(Bottom(), Top())
        )
    ),
])
=#

#=
A = Virtual{AbstractVector{Any}}(:A)
B = Virtual{AbstractVector{Any}}(:B)
C = Virtual{AbstractVector{Any}}(:C)

B′ = Pipeline([
    Phase(1, :B_start, Literal(0)),
    Phase(2, :B_stop, @i B[i]),
    Phase(3, :top, Literal(0)),
])

x = Cases([
    (:(zero), Literal(0)),
    (:(one), Literal(1))
])

C′ = Pipeline([
    Phase(1, :C_start, x),
    Phase(2, :C_stop, @i C[i]),
    Phase(3, :top, Literal(0)),
])

display(MacroTools.prettify(scope(ctx -> visit!(@i(@loop i A[i] += $B′ * $C′), ctx), JuliaContext()), alias=false))
println()

A = Virtual{AbstractVector{Any}}(:A)
B = Virtual{AbstractVector{Any}}(:B)

C = Cases([(:is_B_empty, Literal(0)), (true, @i B[i])])

display(MacroTools.prettify(scope(ctx -> visit!(@i(@loop i A[i] += B[i]), ctx), JuliaContext()), alias=false))
println()

display(MacroTools.prettify(scope(ctx -> visit!(@i(@loop i A[i] += $C), ctx), JuliaContext()), alias=false))
println()


A = Virtual{AbstractVector{Any}}(:A)
B = Virtual{AbstractVector{Any}}(:B)

A′ = Stream(:(length(A)), Phase(1, :j, @i(A[i])))
B′ = Stream(:(length(B)), Phase(1, :k, @i(B[i])))

display(MacroTools.prettify(scope(ctx -> visit!(@i(@loop i $A′ += $B′), ctx), JuliaContext()), alias=false))
println()

=#