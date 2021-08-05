function block(a, b)
    a_stmts = a isa Expr && a.head == :block ? a.args : [a,]
    b_stmts = b isa Expr && b.head == :block ? b.args : [b,]
    return Expr(:block, vcat(a_stmts, b_stmts))
end

block(args...) = reduce(block, args)

struct SparseLevel{Ti}
    pos
    idx
end

struct VirtualSparseLevel
    Ti
    ex
    name
    default
    parent_p
    child
end

iterator_codegen(lvl::VirtualSparseLevel)
    my_p = Symbol("p_", lvl.name)
    my_p′ = Symbol("p′_", lvl.name)
    my_i′ = Symbol("i′_", lvl.name)
    return PhaseIterator(
        setup = (i)->quote
            $my_p = $(ex).pos[$(lvl.parent_p)]
            $my_p′ = $(ex).pos[$(lvl.parent_p) + 1]
        end,
        phases = (
            LoopIterator(
                is_empty = :($my_p < $my_p′),
                setup = :($my_i′ = $(ex).idx[$my_p]),
                finish = :($(ex).idx[$my_p′ - 1])
                body = CaseIterator(
                    cases = (
                        Case(:($i′ == $my_i′),
                            Spike(
                                default = Literal(lvl.default),
                                value = iterator_child(lvl, my_i′, my_p)
                                cleanup = :($my_p += 1)
                                ),
                        ),
                        Case(true,
                            Run(
                                default = Literal(lvl.default),
                            ),
                        )
                    )
                    finish = my_i′
                )
            ),
            Run(
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
