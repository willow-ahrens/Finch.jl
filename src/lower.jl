struct LowerContext
    preamble::Vector{Any}
    bindings::Dict{Name, Symbol}
    epilogue::Vector{Any}
end

LowerContext() = LowerContext([], Dict(), [])

bind(ctx::LowerContext, vars) = LowerContext([], merge(ctx.bindings, vars), [])
function emit(ctx::LowerContext, ex)
    block = Expr(:block)
    append!(block.args, ctx.preamble)
    push!(block.args, ex)
    append!(block.args, ctx.epilogue)
end
function scope(f, ctx::LowerContext, vars...)
    ctx′ = bind(ctx, vars)
    return emit(ctx′, f(ctx′))
end

lower(root) = lower(root, LowerContext(root))
lower(root, ctx) = lower(root, ctx, lower_style(root, ctx))
lower_style(root, ctx) = lower_style(root, ctx, root)
function lower_style(root, ctx, node)
    if istree(node)
        resolve_lower_style(root, ctx, node, mapreduce(node->lower_style(root, ctx, node), combine_lower_style, arguments(node)))
    end
end
combine_lower_style(a, b) = _combine_lower_style(combine_lower_style_rule(a, b), combine_lower_style_rule(a, b))
_combine_lower_style(a::Missing, b::Missing) = missing
_combine_lower_style(a, b::Missing) = a
_combine_lower_style(a::Missing, b) = b
_combine_lower_style(a::T, b::T) = (a == b) ? a : @assert false "TODO lower_style_ambiguity_error"
_combine_lower_style(a, b) = (a == b) ? a : @assert false "TODO lower_style_ambiguity_error"
combine_lower_style_rule(a::Missing, b) = b

#default lowering

lower(::Pass, ctx::LowerContext, ::Missing) = :()

function lower(root::Assign, ctx::LowerContext, ::Missing)
    @assert root.lhs isa Access && root.lhs.idxs ⊆ keys(ctx.bindings)
    if root.op == nothing
        rhs = lower(root.rhs, ctx)
    else
        rhs = lower(call(root.op, root.lhs, root.rhs), ctx)
    end
    tns = lower(root.lhs.tns, ctx)
    idxs = map(idx->lower(idx, ctx), root.lhs.idxs)
    :($tns[$idxs...] = $rhs)
end

function lower(root::Call, ctx::LowerContext, ::Missing)
    :($(lower(root.op, ctx))(map(arg->lower(arg, ctx), root.args)...))
end

function lower(root::Name, ctx::LowerContext, ::Missing)
    @assert haskey(ctx.bindings, root) "TODO unbound variable error or something"
    return ctx.bindings[root]
end

function lower(ex::Access, ctx::LowerContext, ::Missing)
    @assert root.idxs ⊆ keys(ctx.bindings)
    tns = lower(root.tns, ctx)
    idxs = map(idx->lower(idx, ctx), root.idxs)
    :($tns[$idxs...])
end

function lower(stmt::Loop, ctx::LowerContext, ::Missing)
    if isempty(stmt.idxs)
        return lower(stmt.body, ctx)
    else
        idx_sym = gensym(name(idx))
        scope(ctx, idx => idx_sym) do ctx′
            quote
                for $idx_sym = 1:$(10#=dimension(idx) TODO=#)
                    $(lower(lower_simplify(stmt, ctx′), ctx′))
                end
            end
        end
    end
end

lower_rewriters(stmt, ctx) = []

function lower_simplify(stmt, ctx)
    rewriters = ctx.rewriters
    Postwalk(node->(append!(rewriters, lower_rewriters(node, ctx)); node))(stmt)
    return Fixpoint(Postwalk(rewriters), ctx)
end

struct DimensionalizeStyle{Style}
    style::Style
end

combine_lower_style_rule(a::DimensionalizeStyle, b) = DimensionalizeStyle(b)
combine_lower_style_rule(a::DimensionalizeStyle, b::DimensionalizeStyle) = DimensionalizeStyle(combine_lower_style(a.style, b.style))

dimensionalize(stmt, ctx) = map(arg->dimensionalize(arg, ctx), arguments(stmt))
function dimensionalize(stmt::Access, ctx)
    if stmt.tns != Access && !(stmt.inds ⊆ keys(ctx.axes))
        for ind in inds
            do the dimension thing
        push!(ctx.preamble, :(axes(stmt.tns))
    else
        dimensionalize(stmt.tns, ctx)
    end
end

function lower(stmt, ctx::LowerContext, style::DimensionalizeStyle)
    (dims, checks) = dimensionalize(stmt, ctx)
    push!(ctx.dims, dims)
    push!(ctx.preamble, checks)
    return lower(stmt, ctx, style.style)
end


struct Virtual{T}
    expr
end

#What's going on here?  We're going to create a virtual code generator for
#nested blocks A block is a contiguous group of other blocks Initially, we
#assume the blocks are aligned, but the style of the blocks tells us how to
#merge them.  When we merge split blocks or use a block loop, we need to
#truncate the blocks to realign them.  This might produce a switch-case block
#depending on what the truncated block is.  At some point, we'll reach a point
#where we can simply emit code or simplify a block merge to a no-op the
#destination block assignment is tricky. We need to iterate over the
#destination, but it's nontrivial to do increments on a sparse destination, etc.
#If the destination is e.g. a run, then we need some rules about
#how to encode spikes as two separate runs, etc.  presumably we should simplify
#the destination and source iterators until we get to the bottom (spikes, runs,
#singles), then use destination rules about how to do the storage.

#=

#Peter about three weeeks later: It's pretty clear that locate iterators are
#sorta different from coiterate iterators, and choosing one or the other should
#be a scheduling decision.

#PETER even later:
#There seems to be some xinteraction between a lowering loop and a simplify
#loop.  In particular, it seems that the spikes and stuff are all just subloops,
#and some of those subloops can be simplified or become pass statements. After
#each lower, we want to apply a simplify, and after simplifying, we need to
#lower again. The lower step allows the tensors to declare which tensors need
#handling first.
#One question is how to extensibly encode simplification rules. For now, we might
#just want to have a list of rules that get applied.
#Also, the virtual types are a little unnecessary. We can just have a single virtualtensor type and
#overload calls to the virtual type.
struct VirtualSparseFiber
    Ti
    ex
    name
    default
    parent_p
    child
end

function lower(lvl::VirtualSparseFiber, i, ctx)
    my_p = Symbol("p_", lvl.name)
    my_p′ = Symbol("p′_", lvl.name)
    my_i′ = Symbol("i′_", lvl.name)
    return PhaseIterator(
        setup = (i, ctx)->quote
            $my_p = $(ex).pos[$(lvl.parent_p)]
            $my_p′ = $(ex).pos[$(lvl.parent_p) + 1]
        end,
        phases = (
            (i, ctx)->push!(ctx.preamble)
                LoopIterator(
                is_empty = :($my_p < $my_p′),
                setup = :($my_i′ = $(ex).idx[$my_p]),
                finish = :($(ex).idx[$my_p′ - 1])
                body = (i, ctx)->CaseIterator(
                    cases = (
                        (i, ctx)->Case(:($i′ == $my_i′),
                            (i, ctx)->Spike(
                                default = Literal(lvl.default),
                                value = iterator_child(lvl, my_i′, my_p)
                                cleanup = :($my_p += 1)
                            ),
                        ),
                        (i, ctx)->Case(true,
                            (i, ctx)->Run(
                                default = Literal(lvl.default),
                            ),
                        )
                    )
                    finish = my_i′
                )
            ),
            (i)->Run(
                finish = Top(),
                default = Literal(lvl.default),
            )
        ),
        finish = Top(),
    )
end

function coiterate(itrs)
    style = reduce_style(map(IteratorStyle, itrs))
    thunk = Expr(:block)
    map(arg->(thunk = block(thunk, setup(arg))), itrs))
    thunk = block(thunk, coiterate(itrs, style))
    map(arg->(thunk = block(thunk, cleanup(arg))), itrs))
end

struct SplitStyle end

abstract type Iterator end

struct PhaseIterator
    setup
    cleanup
    phases
end

PhaseIterator(;setup=nothing, cleanup=nothing, phases=())

phases(itr::PhaseIterator) = itr.phases
phases(itr) = (itr,)

IteratorStyle(itr::PhaseIterator) = PhaseStyle()

function coiterate(itrs, ::PhaseStyle)
    pipelines = map(phases, itrs)
    pipekeys = map(pipeline->1:length(pipeline), pipelines)
    maxkey = maximum(map(maximum, pipekeys))
    phases = reshape(collect(Iterators.product(pipekeys...)), :)
    sort!(phases, by=phase->map(k->count(key->key>k, phase), 1:maxkey))
    for phase in phases
        itrs′ = map(((pipeline, key))->pipeline[key], zip(pipelines, phase))
        push!(thunk.args, coiterate(itrs′))
    end
    return thunk
end

struct CaseStyle end

struct CaseIterator
    setup
    cleanup
    cases
end

IteratorStyle(itr::CaseIterator) = CaseStyle()

CaseIterator(;setup=nothing, cleanup=nothing, cases=())

cases(itr::CaseIterator) = itr.cases
cases(itr) = [(true, itr),]

IteratorStyle(::CaseIterator, ::PhaseStyle) = PhaseStyle()

function coiterate(itrs, ::CaseStyle)
    pipelines = map(cases, itrs)
    pipekeys = map(pipeline->1:length(pipeline), pipelines)
    maxkey = maximum(map(maximum, pipekeys))
    phases = reshape(collect(Iterators.product(pipekeys...)), :)
    sort!(phases, by=phase->map(k->count(key->key>k, phase), 1:maxkey))
    for phase in phases
        itrs′ = map(((pipeline, key))->pipeline[key], zip(pipelines, phase))
        #do an if else tree
        push!(thunk.args, coiterate(itrs′))
    end
    return thunk
end

cases(itr) = (itr, )

function stage_and(a, b)
    if a == true
        return b
    elseif b == true
        return a
    else
        return :($a && $b)
    end
end

stage_and() = true
stage_and(args...) = reduce(stage_and, args)

function stage_min(args...)
    args = filter(arg -> arg !== Top(), args)
    if length(args) == 0
        return Top()
    elseif length(args) == 1
        return args[]
    else
        return :(min($args...))
    end
end

struct LoopStyle end

struct LoopIterator
    setup
    cleanup
    body
end

IteratorStyle(itr::LoopIterator) = LoopStyle()

LoopIterator(;setup=nothing, cleanup=nothing, cases=())

body(itr::LoopIterator) = itr
body(itr) = itr

function coiterate(i, itrs, ::LoopStyle)
    i′ = Symbol(i, "′")
    return quote
        while $(stage_and(map(is_valid_check, itrs)...))
            $i′ = $(stage_min(map(block_end,)))
            $(next_block(i, i′, itr))
            $(coiterate(i, map(itr->truncate(itr, i′))))
            $i = $i′
        end
    end
end

function coiterate(i, itrs, ::TruncateSingleStyle)
    i′ = Symbol(i, "′")
    return quote
        if $(stage_and(map(is_valid_check, itrs)...))
            $i′ = $(stage_min(map(block_end,)))
            $(coiterate(i, map(itr->truncate(itr, i′))))
            $i = $i′
        end
    end
end

function coiterate(i, itrs, ::TerminalStyle)
    return terminal(map(simplify, itrs))
end


=#

