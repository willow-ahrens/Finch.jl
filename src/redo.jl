using Pigeon
using Pigeon: DefaultStyle, lower!

using TermInterface
using Base.Iterators: product

struct Virtual{T}
    ex
end

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
    block = Expr(:block)
    ctx′ = JuliaContext([], ctx.bindings, [])
    body = f(ctx′)
    append!(block.args, ctx.preamble)
    if body isa Expr && body.head == :block
        append!(block.args, body.args)
    else
        push!(block.args, body)
    end
    append!(block.args, ctx.epilogue)
    return block
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

A = Virtual{AbstractVector{Any}}(:A)
B = Virtual{AbstractVector{Any}}(:B)

C = Cases([(:is_B_empty, Literal(0)), (true, i"B[i]")])

display(scope(ctx -> lower!(i"∀ i A[i] += B[i]", ctx), JuliaContext()))

display(scope(ctx -> lower!(i"∀ i A[i] += $C", ctx), JuliaContext()))