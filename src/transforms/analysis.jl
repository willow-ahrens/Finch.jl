"""
Parallelism analysis plan: We will allow automatic paralleization when the following conditions are met:
All non-locally defined tensors that are written, are only written to with the plain index i in a injective and consistent way and with an associative operator.

all reader or updater accesses on i need to be concurrent (safe to iterate multiple instances of at the same time)

two array axis properties: is_concurrent and is_injective
third properties: is_atomic

You aren't allowed to update a tensor without accessing it with i or marking atomic.

new array: make_atomic
"""

"""
    is_injective(tns, ctx)

Returns a vector of booleans, one for each dimension of the tensor, indicating
whether the access is injective in that dimension.  A dimension is injective if
each index in that dimension maps to a different memory space in the underlying
array.
"""
function is_injective end

"""
    is_concurrent(tns, ctx)

Returns a vector of booleans, one for each dimension of the tensor, indicating
whether multiple threads can loop through the corresponding dimension.
"""
function is_concurrent end

"""
    is_atomic(tns, ctx)

Returns a boolean indicating whether it is safe to update the same element of the
tensor from multiple simultaneous threads.
"""
function is_injective end
function is_atomic end

function gatherAcceses(prog) :: Vector{FinchNode}
    ret:: Vector{FinchNode} = []
    for node in PostOrderDFS(prog)
        if @capture node access(~tns, ~mode, ~idxs...)
            push!(ret, node)
        else
            continue
        end
    end
    return ret
end

function gatherAssignments(prog) :: Vector{FinchNode}
    ret:: Vector{FinchNode} = []
    for node in PostOrderDFS(prog)
        if @capture node assign(~lhs, ~op, ~rhs)
            push!(ret, node)
        else
            continue
        end
    end
    return ret
end

function gatherLocalDeclerations(prog) :: Vector{FinchNode}
    ret:: Vector{FinchNode} = []
    for node in PostOrderDFS(prog)
        if @capture node declare(~tns, ~init)
            push!(ret, tns)
        else
            continue
        end
    end
    return ret
end


struct ParallelAnalysisResults <: Exception
    naive:: Bool
    withAtomics:: Bool
    withAtomicsAndAssoc:: Bool
    tensorsNeedingAtomics:: Set{Any}
    nonInjectiveAccss :: Set{FinchNode}
    nonAssocAssigns:: Set{FinchNode}
    nonConCurrentAccss::Set{FinchNode}
end

function parallelAnalysis(prog, index, alg, ctx) :: ParallelAnalysisResults
    accs = gatherAcceses(prog)
    assigns = gatherAssignments(prog)
    locDefs = Set{FinchNode}(gatherLocalDeclerations(prog))

    nonLocAccs:: Set{FinchNode} = Set{FinchNode}()
    nonLocAssigns:: Set{FinchNode} = Set{FinchNode}()
    naive = true
    withAtomics = true
    withAtomicsAndAssoc = true
    tensorsNeedingAtomics:: Set{Any} = Set{Any}()
    nonInjectiveAccss:: Set{FinchNode} = Set{FinchNode}()
    nonAssocAssigns:: Set{FinchNode} = Set{FinchNode}()
    nonConCurrentAccs::Set{FinchNode} = Set{FinchNode}()
    

    # Step 0:Filter out local defs
    for node in accs
        if node.tns in locDefs
            continue
        end
        push!(nonLocAccs, node)
    end

    for node in assigns
        if node.lhs.tns in locDefs
            continue
        end
        push!(nonLocAssigns, node)
    end


    # Step 1: Gather all the assigns and group them per root
    assignByRoot :: Dict{Any, Set{FinchNode}} = Dict{FinchNode, Set{FinchNode}}()
    for node in assigns
        root = Finch.getroot(node.lhs.tns.val)
        nodeSet = get!(assignByRoot, root, Set{FinchNode}())
        push!(nodeSet, node)
    end
    # Step 2: For each group, ensure they are all accessed via a plain i and using the same part of the tensor - (i.e the virtuals are identical) -  if not, add the root to the group needing atomics.
    for (root, nodeSet) in assignByRoot
        rep = first(nodeSet)
        tns = rep.lhs.tns
        if rep.lhs.idxs[end] != index
            naive = false
            push!(tensorsNeedingAtomics, root)
            push!(nonInjectiveAccss, rep.lhs)
        end

        if @capture acc access(~a, ~m, ~j..., i)
            if is_injective(a, ctx)[length(j) + 1]
                @assert is_concurrent(a, ctx)[length(j) + 1]
            else
                @assert is_atomic(a, ctx)
            end
        end


        # The access is injective
        if !Finch.is_injective(tns.val, ctx, (length(rep.lhs.idxs),))
            naive = false
            push!(tensorsNeedingAtomics, root)
            push!(nonInjectiveAccss, rep.lhs)
        end

        # everyone is accessed in the same way i.e the virtuals are the same.
        for repp in nodeSet
            tnsp = repp.lhs.tns
            if tns != tnsp
                naive = false
                push!(tensorsNeedingAtomics, root)
            end
            if repp.lhs.idxs[end] != index
                naive = false
                push!(tensorsNeedingAtomics, root)
            end
        end
        # Step 3: Similarly, for associativity:
        # Check the ops
        # However, it is also not assosciative if there are multiples access with different ops or lhs.
        firstNode = first(nodeSet)
        for repp in nodeSet
            if !Finch.isassociative(alg, repp.op)
                naive = false
                withAtomics = false
                push!(nonAssocAssigns, repp)
            end
            if firstNode.op != repp.op
                for x in nodeSet
                    naive = false
                    withAtomics = false
                    push!(nonAssocAssigns, x)
                end
                break
            end
        end
        
    end

    # Step 4: Look through all accesses and make sure they are concurrent:
    for acc in nonLocAccs
        if !Finch.is_concurrent(acc.tns.val, ctx)
            naive = false
            withAtomics = false
            withAtomicsAndAssoc = false
            push!(nonConCurrentAccs, acc)
            break
        end
    end

    return ParallelAnalysisResults(naive, withAtomics, withAtomicsAndAssoc, tensorsNeedingAtomics, nonInjectiveAccss, nonAssocAssigns, nonConCurrentAccs)
end

