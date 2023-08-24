abstract type AbstractCompiler end

struct Freshen
    seen
    counts
end
Freshen() = Freshen(Set(), Dict())
function (spc::Freshen)(tags...)
    name = Symbol(tags...)
    m = match(r"^(.*)_(\d*)$", string(name))
    if m === nothing
        tag = name
        n = 1
    else
        tag = Symbol(m.captures[1])
        n = parse(BigInt, m.captures[2])
    end
    if (tag, n) in spc.seen
        n = max(get(spc.counts, tag, 0), n) + 1
        spc.counts[tag] = n
    end
    push!(spc.seen, (tag, n))
    if n == 1
        return Symbol(tag)
    else
        return Symbol(tag, :_, n)
    end
end

@kwdef mutable struct JuliaContext <: AbstractCompiler
    freshen::Freshen = Freshen()
    preamble::Vector{Any} = []
    epilogue::Vector{Any} = []
end

virtualize(ex, T, ctx, tag) = virtualize(ex, T, ctx)


"""
    contain(f, ctx)

Call f on a subcontext of `ctx` and return the result. Variable bindings,
preambles, and epilogues defined in the subcontext will not escape the call to
contain.
"""
function contain(f, ctx::JuliaContext)
    preamble = Expr(:block)
    epilogue = Expr(:block)
    ctx_2 = JuliaContext(ctx.freshen, preamble.args, epilogue.args)
    body = f(ctx_2)
    if epilogue == Expr(:block)
        return quote
            $preamble
            $body
        end
    else
        res = ctx.freshen(:res)
        return quote
            $preamble
            $res = $body
            $epilogue
            $res
        end
    end
end
