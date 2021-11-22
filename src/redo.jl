using Pigeon
using Pigeon: DefaultStyle, visit!, getname

using TermInterface
using Base.Iterators: product
using SymbolicUtils: Postwalk
using MacroTools
using Parameters

struct Virtual{T}
    ex
end
TermInterface.istree(::Type{<:Virtual}) = false

@with_kw struct Extent{T}
    start
    stop
end

struct Top end
struct Bottom end

@with_kw struct LowerJuliaContext
    preamble::Vector{Any} = []
    bindings::Dict{Name, Symbol} = Dict()
    epilogue::Vector{Any} = []
end

bind(f, ctx::LowerJuliaContext) = f()
function bind(f, ctx::LowerJuliaContext, (var, val′), tail...)
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

function scope(f, ctx::LowerJuliaContext)
    thunk = Expr(:block)
    ctx′ = LowerJuliaContext([], ctx.bindings, [])
    body = f(ctx′)
    append!(thunk.args, ctx′.preamble)
    push!(thunk.args, body)
    append!(thunk.args, ctx′.epilogue)
    return thunk
end

#default lowering

Pigeon.visit!(::Pass, ctx::LowerJuliaContext, ::DefaultStyle) = :()

function Pigeon.visit!(root::Assign, ctx::LowerJuliaContext, ::DefaultStyle)
    @assert root.lhs isa Access && root.lhs.idxs ⊆ keys(ctx.bindings)
    if root.op == nothing
        rhs = visit!(root.rhs, ctx)
    else
        rhs = visit!(call(root.op, root.lhs, root.rhs), ctx)
    end
    tns = visit!(root.lhs.tns, ctx)
    idxs = map(idx->visit!(idx, ctx), root.lhs.idxs)
    :($tns[$(idxs...)] = $rhs)
end

function Pigeon.visit!(root::Call, ctx::LowerJuliaContext, ::DefaultStyle)
    :($(visit!(root.op, ctx))($(map(arg->visit!(arg, ctx), root.args)...)))
end

function Pigeon.visit!(root::Name, ctx::LowerJuliaContext, ::DefaultStyle)
    @assert haskey(ctx.bindings, root) "TODO unbound variable error or something"
    return ctx.bindings[root]
end

function Pigeon.visit!(root::Literal, ctx::LowerJuliaContext, ::DefaultStyle)
    return root.val
end

function Pigeon.visit!(root, ctx::LowerJuliaContext, ::DefaultStyle)
    if Pigeon.isliteral(root) return Pigeon.value(root) end
    error()
end

function Pigeon.visit!(root::Virtual, ctx::LowerJuliaContext, ::DefaultStyle)
    return root.ex
end

function Pigeon.visit!(root::Access, ctx::LowerJuliaContext, ::DefaultStyle)
    @assert root.idxs ⊆ keys(ctx.bindings)
    tns = visit!(root.tns, ctx)
    idxs = map(idx->visit!(idx, ctx), root.idxs)
    :($tns[$(idxs...)])
end

function Pigeon.visit!(stmt::Loop, ctx::LowerJuliaContext, ::DefaultStyle)
    if isempty(stmt.idxs)
        return visit!(stmt.body, ctx)
    else
        idx_sym = gensym(Pigeon.getname(stmt.idxs[1]))
        stmt′ = Loop(stmt.idxs[2:end], stmt.body)
        return bind(ctx, stmt.idxs[1] => idx_sym) do 
            scope(ctx, ) do ctx′
                quote
                    for $idx_sym = 1:$(10#=dimension(idx) TODO=#)
                        $(visit!(stmt′, ctx′))
                    end
                end
            end
        end
    end
end

@with_kw struct Cases
    cases
end

struct CaseStyle end

#TODO handle children of access?
Pigeon.make_style(root, ctx::LowerJuliaContext, node::Cases) = CaseStyle()
Pigeon.combine_style(a::DefaultStyle, b::CaseStyle) = CaseStyle()

function Pigeon.visit!(stmt, ctx::LowerJuliaContext, ::CaseStyle)
    cases = collect_cases(stmt, ctx)
    thunk = Expr(:block)
    for (guard, body) in cases
        push!(thunk.args, :(
            if $(guard)
                $(visit!(body, ctx))
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

function collect_cases(node::Cases, ctx::LowerJuliaContext)
    node.cases
end

@with_kw struct Pipeline
    phases
end

mutable struct Phase
    key
    stop #integer representing the last index
    body
end

Phase(; key=nothing, stop=nothing, body=nothing) = Phase(key, stop, body)
copy(x::Phase) = Phase(x.key, x.stop, x.body)

phase_precedence(x) = []
phase_precedence(x::Phase, ctx) = [x.key(ctx)]
phase_stop(x) = []
phase_stop(x::Phase, ctx) = [x.stop(ctx)]
phase_body(x) = x
phase_body(x::Phase, ctx) = x.body(ctx)

TermInterface.istree(::Phase) = false

struct PipelineStyle end

#TODO handle children of access?
Pigeon.make_style(root::Loop, ctx::LowerJuliaContext, node::Pipeline) = PipelineStyle()
#TODO note that we should only insert pipelines into loops with valid first indices
Pigeon.combine_style(a::DefaultStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::PipelineStyle, b::PipelineStyle) = PipelineStyle()

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::PipelineStyle)
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
                    $(visit!(body, ctx′))
                end
            )
        end)
    end
    return thunk
end

struct Top end

expand_pipeline(node, ctx) = [node]
expand_pipeline(node::Pipeline, ctx) = map((n, a) -> (b = copy(phase); b.key = n; b), node.phases)

function collect_pipelines(node::Pipeline, ctx::LowerJuliaContext)
    node.phases
end

function truncate_block(root, node, i, ctx)
    if istree(node)
        operation(node)(map(arg->truncate_block(root, arg, i, ctx), arguments(node))...)
    else
        node
    end
end

@with_kw struct Stream
    body
    ext
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
Pigeon.make_style(root::Loop, ctx::LowerJuliaContext, node::Stream) = StreamStyle()
#TODO note that we should only insert pipelines into loops with valid first indices
Pigeon.combine_style(a::DefaultStyle, b::StreamStyle) = StreamStyle()
Pigeon.combine_style(a::StreamStyle, b::StreamStyle) = StreamStyle()
Pigeon.combine_style(a::StreamStyle, b::PipelineStyle) = PipelineStyle()

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::StreamStyle)
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
                visit!(truncate_block(root, body, i′′, ctx′), ctx′)
            end)
        end
    end
end

expand_pipeline(node, ctx) = [node]
expand_pipeline(node::Pipeline, ctx) = node.phases

function collect_pipelines(node::Pipeline, ctx::LowerJuliaContext)
    node.phases
end

function truncate_block(root, node, i, ctx)
    if istree(node)
        operation(node)(map(arg->truncate_block(root, arg, i, ctx), arguments(node))...)
    else
        node
    end
end

@with_kw struct Run
    body
    ext
end

function truncate_block(root, node::Run, i, ctx)
    return Run(node.body, i)
end

@with_kw struct Spike
    body
    tail
    ext
end

function truncate_block(root, node::Spike, i, ctx)
    return Cases([
        (:($i = $(node.stop)), node),
        (true, truncate_block(root, node.body, i, ctx)),
    ])
end

struct SpikeStyle end

#TODO handle children of access?
Pigeon.make_style(root::Loop, ctx::LowerJuliaContext, node::Spike) = SpikeStyle()
#TODO note that we should only insert pipelines into loops with valid first indices
Pigeon.combine_style(a::DefaultStyle, b::SpikeStyle) = SpikeStyle()
Pigeon.combine_style(a::SpikeStyle, b::SpikeStyle) = SpikeStyle()
Pigeon.combine_style(a::SpikeStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::StreamStyle, b::SpikeStyle) = StreamStyle()

struct RunStyle end

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::SpikeStyle)
    #1. simplify
    #2. "dispatch" on spike = ..., no matter where it occurs in expr.

    return Expr(:block,
        visit!(Pigeon.Prewalk(node->spike_body(node, ctx))(root), ctx),
        visit!(Pigeon.Prewalk(node->spike_tail(node, ctx))(root), ctx)
    )
end

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::RunStyle)
    #1. simplify
    #2. "dispatch" on run = ..., no matter where it occurs in expr.

    return Expr(:block,
        visit!(Pigeon.Prewalk(node->spike_tail(node, ctx))(root), ctx)
    )
end


