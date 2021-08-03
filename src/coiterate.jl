struct SparseVector{Ti}
    pos
    idx
end

iterator_codegen(type::SparseVector{Ti})
    return SplitIterator(
        setup = (i)->quote

        end,
        phases = (
            TruncateLoopIterator(
                block_end = quote
                    pos[p]
                end
                truncate = (i′)->quote
                    CaseIterator(
                        setup = :(i_p = idx[p])
                        cases = (
                            Case(:($i′ == $i_p),
                                Spike(
                                    start = :i,
                                    finish = :i′,
                                    default = Literal(type.default),
                                    value = Typed(type, SparseFiber(:i))
                                    cleanup = :(p += 1)
                                    ),
                            Case(true,
                                Run(
                                    start = :i,
                                    finish = :i′,
                                    default = Literal(type.default),
                                ),
                            )
                        )
                    )
                end
            )
            while
        ),
        cleanup = (i)->quote
        end,
    )
end

struct SparseVectorSplitIterator
    prev_pos
    vec
end

IteratorStyle(itr::SparseVectorSplitIterator) = SplitStyle()

setup(itr::SparseVectorSplitIterator) = :(p = 1)

splits(itr::SparseVectorSplitIterator) = (Split(itr.vec, itr.prev_pos), SparseVectorRunCleanup(vec))

struct SparseVectorSpikeLoop
    prev_pos
    vec
end

block_end(itr::SparseVectorSpikeLoop) = :($(itr.vec.pos)[$(itr.prev_pos)])

IteratorStyle(itr::SparseVectorSpikeLoop) = IterativeTruncateStyle()

struct SparseVectorRunCleanup
    vec
end

IteratorStyle(itr::SparseVectorRunCleanup) = TerminalStyle()

function coiterate(itrs)
    style = reduce_style(map(IteratorStyle, itrs))
    coiterate(itrs, style)
end

struct SplitStyle end

struct SplitIterator
    setup
    cleanup
    phases
end

function phase_order()
end

function coiterate(itrs, ::SplitStyle)
    pipelines = map(itr->splits, itrs)
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

splits(itr) = (itr, )

struct CaseStyle end

function phase_order()
end

function coiterate(itrs, ::CaseStyle)
    pipelines = map(itr->splits, itrs)
    pipekeys = map(pipeline->1:length(pipeline), pipelines)
    maxkey = maximum(map(maximum, pipekeys))
    phases = reshape(collect(Iterators.product(pipekeys...)), :)
    sort!(phases, by=phase->map(k->count(key->key>k, phase), 1:maxkey))
    for phase in phases
        itrs′ = map(((pipeline, key))->pipeline[key], zip(pipelines, phase))
        #do an if else
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

function coiterate(i, itrs, ::TruncateLoopStyle)
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
