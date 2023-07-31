"""
Parallelism analysis plan: We will allow automatic paralleization when the following conditions are meet:
All non-locally defined tensors that are written, are only written to with the plain index i in a injective and consistent way and with an associative operator.

all reader or updater accesses on i need to be concurrent (safe to iterate multiple instances of at the same time)

two array axis properties: is_concurrent and is_injective
third properties: is_atomic

You aren't allowed to update a tensor without accessing it with i or marking atomic.

new array: make_atomic
"""

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
    tensorsNeedingAtomics:: Vector{FinchNode}
    nonInjectiveAccss :: Vector{FinchNode}
    nonAssocAssigns:: Vector{FinchNode}
    nonConCurrentAccss::Vector{FinchNode}
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
    tensorsNeedingAtomics:: Vector{FinchNode} = []
    nonInjectiveAccss:: Vector{FinchNode} = []
    nonAssocAssigns:: Vector{FinchNode} = []
    nonConCurrentAccss::Vector{FinchNode} = []
    

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
    assignByRoot :: Dict{FinchNode, Set{FinchNode}} = Dict{FinchNode, Set{FinchNode}}()
    for node in assigns
        root = getroot(node.lhs.tns)
        nodeSet = get!(assignByRoot, root, Set{FinchNode}())
        push!(nodeSet, node)
    end
    # Step 2: For each group, ensure they are all accessed via a plain i and using the same part of the tensor - (i.e the virtuals are identical) -  if not, add the root to the group needing atomics.
    for (root, nodeSet) in assignByRoot
        rep = first(nodeSet)
        tns = rep.lhs.tns
        if rep.lhs.idx[end] != index
            naive = false
            push!(tensorsNeddingAtomics, root)
            push!(nonInjectiveAccss, rep.lhs)
        end

        # FIXME: TRACE.
        # The access is injective
        if !is_injective(tns, ctx)
            naive = false
            push!(tensorsNeddingAtomics, root)
            push!(nonInjectiveAccss, rep.lhs)
        end

        # everyone is accessed in the same way i.e the virtuals are the same.
        for repp in nodeSet
            tnsp = repp.lhs.tns
            if tns != tnsp
                naive = false
                push!(tensorsNeddingAtomics, root)
            end
            if repp.lhs[end] != index
                naive = false
                push!(tensorsNeddingAtomics, root)
            end
        end
        # Step 3: Similarly, for associativity:
        # Check the ops
        # However, it is also not assosciative if there are multiples access with different ops or lhs.
        firstNode = first(nodeSet)
        for repp in nodeSet
            if !isassociative(alg, repp.op)
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
        if !is_concurrent(acc.tns, ctx)
            naive = false
            withAtomics = false
            withAtomicsAndAssoc = false
            break
        end
    end

    return ParallelAnalysisResults(naive, withAtomics, withAtomicssAndAssoc, tensorsNeddingAtomics, nonInjectiveAccss, nonAssocAssigns, nonConCurrentAccs)
end



#=
# willow says hello!
for node in PostOrderDFS(prgm)
    if @capture node access(~tns, ~mode, ~idxs..., i)
    if @capture node access(~tns, ~mode, ~idxs...)
=#
