struct FinchConcurrencyError
    msg
end

"""
    is_injective(tns, ctx)

Returns a vector of booleans, one for each dimension of the tensor, indicating
whether the access is injective in that dimension.  A dimension is injective if
each index in that dimension maps to a different memory space in the underlying
array.
"""
function is_injective end

"""
    is_atomic(tns, ctx)

    Returns a tuple (below, overall) where below is a vector, indicating which indicies have an atomic that guards them, 
    and overall is a boolean that indicates is the last level had an atomic guarding it.
"""
function is_atomic end

"""
    is_concurrent(tns, ctx)

    Returns a vector of booleans, one for each dimension of the tensor, indicating
    whether the index can be written to without any state. So if a matrix returns [true, false],
    then we can write to A[i, j] and A[i+1, j] without any shared state between the two, but
    we can't write to A[i, j] and A[i, j+1] without carrying over state.
"""
function is_concurrent end

"""
ensure_concurrent(root, ctx)

Ensures that all nonlocal assignments to the tensor root are consistently
accessed with the same indices and associative operator.  Also ensures that the
tensor is either atomic, or accessed by `i` and concurrent and injective on `i`.
"""
function ensure_concurrent(root, ctx)
    @assert @capture root loop(~idx, ~ext, ~body)

    #get local definitions
    locals = Set(filter(!isnothing, map(PostOrderDFS(body)) do node
        if @capture(node, declare(~tns, ~init)) tns end
    end))

    #get nonlocal assignments and group by root
    nonlocal_assigns = Dict()
    for node in PostOrderDFS(body)
        if @capture(node, assign(~lhs, ~op, ~rhs)) && !(getroot(lhs.tns) in locals) && getroot(lhs.tns) !== nothing #TODO remove the nothing check
            push!(get!(nonlocal_assigns, getroot(lhs.tns), []), node)
        end
    end

    # Get all indicies in the parallel region.
    indicies_in_region = [idx]
    for node in PostOrderDFS(body)
        if  @capture node loop(~idxp, ~ext, ~body)
            if !(idxp in indicies_in_region)
                push!(indicies_in_region, idxp)
            end
        end
    end
    


    for (root, agns) in nonlocal_assigns
        ops = map(agn -> (@capture agn assign(~lhs, ~op, ~rhs); op), agns)
        if !allequal(ops)
            throw(FinchConcurrencyError("Nonlocal assignments to $(root) are not all the same operator"))
        end

        accs = map(agn -> (@capture agn assign(~lhs, ~op, ~rhs); lhs), agns)
        acc = first(accs)
        # The operation must be associative.
        oper = first(ops)
        if !(isassociative(ctx.algebra, oper))
            if (length(ops) == 1)
                if (@capture(acc, access(~tns, ~mode, ~i...)))
                    injectivityIdp:: Vector{Bool} = is_injective(tns, ctx)
                    concurrencyInfo = is_concurrent(tns, ctx)
                    if !all(injectivityIdp) || !all(concurrencyInfo)
                        throw(FinchConcurrencyError("Non-associative operations can only be parallelized in the case of a single injective acceses, but the injectivity is $(injectivity) and the concurrency is $(concurrencyInfo)."))
                    else

                        continue # We pass via a single assignment that is completely injective.
                    end
                else
                    throw(FinchConcurrencyError("Assignment $(acc) is invalid!"))
                end
            end
            throw(FinchConcurrencyError("Nonlocal assignments to $(root) via $(oper) are not associative"))
        end
        # If the acceses are different, then all acceses must be atomic.
        if !allequal(accs)
            for acc in accs
                (below, _) = is_atomic(acc.tns, ctx)
                concurrencyInfo = is_concurrent(acc.tns, ctx)
                if !all(below) || !all(concurrencyInfo)
                    throw(FinchConcurrencyError("Nonlocal assignments to $(root) are not all the same access so concurrency and atomics are needed on all acceses!"))
                end
            end 
            continue
        else
            #Since all operations/acceses are the same, a more fine grained analysis takes place:
            #Every access must be injective or they must all be atomic.
            if (@capture(acc, access(~tns, ~mode, ~i...)))
                locations_with_parallel_vars = []
                injectivity:: Vector{Bool} = is_injective(tns, ctx)
                concurrencyInfo = is_concurrent(acc.tns, ctx)
                for loc in 1:length(i)
                    if i[loc] in indicies_in_region
                        push!(locations_with_parallel_vars, loc + 1)
                    end
                end
                if length(locations_with_parallel_vars) == 0
                    (below, overall) = is_atomic(acc.tns, ctx)
                    if !below[1]
                        throw(FinchConcurrencyError("Assignment $(acc) requires last level atomics!"))
                        # FIXME: we could do atomic operations here.
                    else
                        continue
                    end
                end

                if all(injectivity[[x-1 for x in locations_with_parallel_vars]]) && all(concurrencyInfo[[x-1 for x in locations_with_parallel_vars]])
                    continue # We pass due to injectivity!
                end
                # FIXME: This could be more fine grained: atomics need to only protect the non-injectivity. 
                (below, _) = is_atomic(acc.tns, ctx)
                if all(below[locations_with_parallel_vars]) && all(concurrencyInfo[[x-1 for x in locations_with_parallel_vars]])
                    continue # we pass due to atomics!
                else
                    throw(FinchConcurrencyError("Assignment $(acc) requires injectivity or atomics in at least places $(locations_with_parallel_vars), but does not have them, due to injectivity=$(injectivity) and atomics=$(below) and concurrency=$(concurrencyInfo)."))
                end
            else
                throw(FinchConcurrencyError("Assignment $(acc) is invalid! "))

            end
        end
    end
    # we validated everything so we are done!
    return root
end