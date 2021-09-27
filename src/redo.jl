using Pigeon
using Pigeon: DefaultStyle, lower!, getname

using TermInterface
using Base.Iterators: product
using SymbolicUtils: Postwalk
using MacroTools

struct Virtual{T}
    ex
end
TermInterface.istree(::Type{<:Virtual}) = false

struct JuliaContext
    preamble::Vector{Any}
    bindings::Dict{Name, Symbol}
    epilogue::Vector{Any}
end

JuliaContext() = JuliaContext([], Dict(), [])

bind(f, ctx::JuliaContext) = f()
function bind(f, ctx::JuliaContext, (var, val′), tail...)
    if haskey(ctx.bindings, var)
        val = ctx.bindings[var]
        ctx.bindings[var] = val′
        res = bind(f, ctx, tail...)
        ctx.bindings[var] = val
        return res
    else
        ctx.bindings[var] = val′
        res = bind(f, ctx, tail...)
        pop!(ctx.bindings, var)
        return res
    end
end

function scope(f, ctx::JuliaContext)
    thunk = Expr(:block)
    ctx′ = JuliaContext([], ctx.bindings, [])
    body = f(ctx′)
    append!(thunk.args, ctx′.preamble)
    push!(thunk.args, body)
    append!(thunk.args, ctx′.epilogue)
    return thunk
end

#default lowering

Pigeon.lower!(::Pass, ctx::JuliaContext, ::DefaultStyle) = :()

function Pigeon.lower!(root::Assign, ctx::JuliaContext, ::DefaultStyle)
    @assert root.lhs isa Access && root.lhs.idxs ⊆ keys(ctx.bindings)
    if root.op == nothing
        rhs = lower!(root.rhs, ctx)
    else
        rhs = lower!(call(root.op, root.lhs, root.rhs), ctx)
    end
    tns = lower!(root.lhs.tns, ctx)
    idxs = map(idx->lower!(idx, ctx), root.lhs.idxs)
    :($tns[$(idxs...)] = $rhs)
end

function Pigeon.lower!(root::Call, ctx::JuliaContext, ::DefaultStyle)
    :($(lower!(root.op, ctx))($(map(arg->lower!(arg, ctx), root.args)...)))
end

function Pigeon.lower!(root::Name, ctx::JuliaContext, ::DefaultStyle)
    @assert haskey(ctx.bindings, root) "TODO unbound variable error or something"
    return ctx.bindings[root]
end

function Pigeon.lower!(root::Literal, ctx::JuliaContext, ::DefaultStyle)
    return root.val
end

function Pigeon.lower!(root, ctx::JuliaContext, ::DefaultStyle)
    if Pigeon.isliteral(root) return Pigeon.value(root) end
    error()
end

function Pigeon.lower!(root::Virtual, ctx::JuliaContext, ::DefaultStyle)
    return root.ex
end

function Pigeon.lower!(root::Access, ctx::JuliaContext, ::DefaultStyle)
    @assert root.idxs ⊆ keys(ctx.bindings)
    tns = lower!(root.tns, ctx)
    idxs = map(idx->lower!(idx, ctx), root.idxs)
    :($tns[$(idxs...)])
end

function Pigeon.lower!(stmt::Loop, ctx::JuliaContext, ::DefaultStyle)
    if isempty(stmt.idxs)
        return lower!(stmt.body, ctx)
    else
        idx_sym = gensym(Pigeon.getname(stmt.idxs[1]))
        stmt′ = Loop(stmt.idxs[2:end], stmt.body)
        return bind(ctx, stmt.idxs[1] => idx_sym) do 
            scope(ctx, ) do ctx′
                quote
                    for $idx_sym = 1:$(10#=dimension(idx) TODO=#)
                        $(lower!(stmt′, ctx′))
                    end
                end
            end
        end
    end
end

struct Cases
    cases
end

struct CaseStyle end

#TODO handle children of access?
Pigeon.make_style(root, ctx::JuliaContext, node::Cases) = CaseStyle()
Pigeon.combine_style(a::DefaultStyle, b::CaseStyle) = CaseStyle()

function Pigeon.lower!(stmt, ctx::JuliaContext, ::CaseStyle)
    cases = collect_cases(stmt, ctx)
    thunk = Expr(:block)
    for (guard, body) in cases
        push!(thunk.args, :(
            if $(guard)
                $(lower!(body, ctx))
            end
        ))
    end
    return thunk
end

function collect_cases(node, ctx)
    if istree(node)
        map(product(map(arg->collect_cases(arg, ctx), arguments(node))...)) do case
            (guards, bodies) = zip(case...)
            (reduce((a, b) -> :($a && $b), guards), operation(node)(bodies...))
        end
    else
        [(true, node),]
    end
end

function collect_cases(node::Cases, ctx::JuliaContext)
    node.cases
end

struct Cases
    cases
end

struct CaseStyle end

#TODO handle children of access?
Pigeon.make_style(root, ctx::JuliaContext, node::Cases) = CaseStyle()
Pigeon.combine_style(a::DefaultStyle, b::CaseStyle) = CaseStyle()

function Pigeon.lower!(stmt, ctx::JuliaContext, ::CaseStyle)
    cases = collect_cases(stmt, ctx)
    thunk = Expr(:block)
    for (guard, body) in cases
        push!(thunk.args, :(
            if $(guard)
                $(lower!(body, ctx))
            end
        ))
    end
    return thunk
end

collect_cases_reduce(x, y) = x === true ? y : (y === true : x : :($x && $y))
function collect_cases(node, ctx)
    if istree(node)
        map(product(map(arg->collect_cases(arg, ctx), arguments(node))...)) do case
            (guards, bodies) = zip(case...)
            (reduce(collect_cases_reduce, guards), operation(node)(bodies...))
        end
    else
        [(true, node),]
    end
end

function collect_cases(node::Cases, ctx::JuliaContext)
    node.cases
end

struct Pipeline
    phases
end

struct Phase
    key #precedence of the phase, could be derived
    stop #integer representing the last index
    body
end

phase_precedence(x) = []
phase_precedence(x::Phase) = [x.key]
phase_stop(x) = []
phase_stop(x::Phase) = [x.stop]
phase_body(x) = x
phase_body(x::Phase) = x.body

TermInterface.istree(::Phase) = false

struct PipelineStyle end

#TODO handle children of access?
Pigeon.make_style(root::Loop, ctx::JuliaContext, node::Pipeline) = PipelineStyle()
#TODO note that we should only insert pipelines into loops with valid first indices
Pigeon.combine_style(a::DefaultStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::PipelineStyle, b::PipelineStyle) = PipelineStyle()

function Pigeon.lower!(root::Loop, ctx::JuliaContext, ::PipelineStyle)
    states = Pigeon.PrewalkStep(node->expand_pipeline(node, ctx))(root)
    keys = map(state->collectwalk(phase_precedence, vcat, state), states)
    maxkey = maximum(map(maximum, keys))
    σ = sortperm(keys, by=key->map(l->count(k->k>l, key), 1:maxkey))
    i = getname(root.idxs[1])
    thunk = Expr(:block)
    for state in states[σ]
        body = Postwalk(phase_body)(state)
        cond = collectwalk(phase_stop, vcat, state)
        push!(thunk.args, scope(ctx) do ctx′
            i′ = gensym(Symbol("_", i))
            push!(ctx′.preamble, :($i′ = min($(cond...))))
            body = truncate_block(root, body, i′, ctx′)
            #TODO do dimension truncation as well
            return :(
                if $i < $i′
                    $(lower!(body, ctx′))
                end
            )
        end)
    end
    return thunk
end

struct Top end

expand_pipeline(node, ctx) = [node]
expand_pipeline(node::Pipeline, ctx) = node.phases

function collect_pipelines(node::Pipeline, ctx::JuliaContext)
    node.phases
end

function truncate_block(root, node, i, ctx)
    if istree(node)
        operation(node)(map(arg->truncate_block(root, arg, i, ctx), arguments(node))...)
    else
        node
    end
end

struct Stream
    stop #integer representing the last index
    body
end


function collectwalk(f, op, node)
    if istree(node)
        return mapreduce(arg->collectwalk(f, op, arg), op, arguments(node))
    else
        return f(node)
    end
end

stream_stop(x, ctx) = []
stream_stop(x::Stream, ctx) = [x.stop]
stream_body(x, ctx) = x
stream_body(x::Stream, ctx) = x.body

struct StreamStyle end

#TODO handle children of access?
Pigeon.make_style(root::Loop, ctx::JuliaContext, node::Stream) = StreamStyle()
#TODO note that we should only insert pipelines into loops with valid first indices
Pigeon.combine_style(a::DefaultStyle, b::StreamStyle) = StreamStyle()
Pigeon.combine_style(a::StreamStyle, b::StreamStyle) = StreamStyle()
Pigeon.combine_style(a::StreamStyle, b::PipelineStyle) = PipelineStyle()

function Pigeon.lower!(root::Loop, ctx::JuliaContext, ::StreamStyle)
    body = Pigeon.Prewalk(node->stream_body(node, ctx))(root)
    stop = collectwalk(node->stream_stop(node, ctx), vcat, root)
    i = getname(root.idxs[1])
    thunk = Expr(:block)
    i′ = gensym(Symbol("_", i))
    i′′ = gensym(Symbol("_", i))
    return quote
        $i′ = min($(stop...))
        while $i′′ < $i′
            $(scope(ctx) do ctx′
                body = Postwalk(phase_body)(body)
                cond = collectwalk(phase_stop, vcat, body)
                push!(ctx′.preamble, :($i′′ = min($(cond...))))
                lower!(truncate_block(root, body, i′′, ctx′), ctx′)
            end)
        end
    end
end

struct Top end

expand_pipeline(node, ctx) = [node]
expand_pipeline(node::Pipeline, ctx) = node.phases

function collect_pipelines(node::Pipeline, ctx::JuliaContext)
    node.phases
end

function truncate_block(root, node, i, ctx)
    if istree(node)
        operation(node)(map(arg->truncate_block(root, arg, i, ctx), arguments(node))...)
    else
        node
    end
end

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

display(MacroTools.prettify(scope(ctx -> lower!(@i(@loop i A[i] += $B′ * $C′), ctx), JuliaContext()), alias=false))
println()

A = Virtual{AbstractVector{Any}}(:A)
B = Virtual{AbstractVector{Any}}(:B)

C = Cases([(:is_B_empty, Literal(0)), (true, @i B[i])])

display(MacroTools.prettify(scope(ctx -> lower!(@i(@loop i A[i] += B[i]), ctx), JuliaContext()), alias=false))
println()

display(MacroTools.prettify(scope(ctx -> lower!(@i(@loop i A[i] += $C), ctx), JuliaContext()), alias=false))
println()


A = Virtual{AbstractVector{Any}}(:A)
B = Virtual{AbstractVector{Any}}(:B)

A′ = Stream(:(length(A)), Phase(1, :j, @i(A[i])))
B′ = Stream(:(length(B)), Phase(1, :k, @i(B[i])))

display(MacroTools.prettify(scope(ctx -> lower!(@i(@loop i $A′ += $B′), ctx), JuliaContext()), alias=false))
println()

struct Run
    body
    stop
end

function truncate_block(root, node::Run, i, ctx)
    return Run(node.body, i)
end

struct Spike
    body
    tail
    stop
end

function truncate_block(root, node::Spike, i, ctx)
    return Cases([
        (:($i = $(node.stop)), node),
        (true, truncate_block(root, node.body, i, ctx)),
    ])
end

struct SpikeStyle end

#TODO handle children of access?
Pigeon.make_style(root::Loop, ctx::JuliaContext, node::Spike) = SpikeStyle()
#TODO note that we should only insert pipelines into loops with valid first indices
Pigeon.combine_style(a::DefaultStyle, b::SpikeStyle) = SpikeStyle()
Pigeon.combine_style(a::SpikeStyle, b::SpikeStyle) = SpikeStyle()
Pigeon.combine_style(a::SpikeStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::StreamStyle, b::SpikeStyle) = StreamStyle()

struct RunStyle end

function Pigeon.lower!(root::Loop, ctx::JuliaContext, ::SpikeStyle)
    #1. simplify
    #2. "dispatch" on spike = ..., no matter where it occurs in expr.

    return Expr(:block,
        lower!(Pigeon.Prewalk(node->spike_body(node, ctx))(root), ctx),
        lower!(Pigeon.Prewalk(node->spike_tail(node, ctx))(root), ctx)
    )
end

function Pigeon.lower!(root::Loop, ctx::JuliaContext, ::RunStyle)
    #1. simplify
    #2. "dispatch" on run = ..., no matter where it occurs in expr.

    return Expr(:block,
        lower!(Pigeon.Prewalk(node->spike_tail(node, ctx))(root), ctx)
    )
end


