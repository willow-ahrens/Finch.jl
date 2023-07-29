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


struct ParallelAnalysisResults
    naive:: bool
    withAtomics:: bool
    withAtomicsAndAssoc:: bool
    tensorsNeedingAtomics:: Vector{FinchNode}
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
    assignByRoot :: Dict{FinchNode, Set{FinchNode}} = {}
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
        end

        # FIXME: TRACE.
        # The access is injective
        if !is_injective(tns, ctx, (length(rep.lhs,idx),))
            naie = false
            push!(tensorsNeddingAtomics, root)
        end

        # everyone is accessed in the same way i.e the virtuals are the same.
        for rep' in nodeSet
            tns' = rep'.lhs.tns
            if tns != tns'
                naive = false
                push!(tensorsNeddingAtomics, root)
            end
            if rep'.lhs[end] != index
                naive = false
                push!(tensorsNeddingAtomics, root)
            end
        end
        # Step 3: Similarly, for associativity
        for rep' in nodeSet
            if !isassociative(alg, rep'.lhs.op)
                naive = false
                withAtomics = false
                push!(nonAssocAssigns, rep')
            end
        end
        
    end

    # Step 4: Look through all accesses and make sure they are concurrent.
    for acc in nonLocAccs
        if length(acc.idx) == 0
            if !is_concurrent(acc.tns, ctx)
                naive = false
                withAtomics = false
                withAtomicsAndAssoc = false
                break
            end
        else
            if !is_concurrent(acc.tns, ctx, )
                #erm, should I have written this with the protocol.
            end
        end
    end

    return ParallelAnalysisResults(naive, withAtomics, withAtomicssAndAssoc, tensorsNeddingAtomics, nonAssocAssigns, nonConCurrentAccs)
end



#=
# willow says hello!
for node in PostOrderDFS(prgm)
    if @capture node access(~tns, ~mode, ~idxs..., i)
    if @capture node access(~tns, ~mode, ~idxs...)
=#
