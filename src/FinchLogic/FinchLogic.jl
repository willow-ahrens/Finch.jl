module FinchLogic
    using RewriteTools, SyntaxInterface, AbstractTrees, Finch
    using Finch: virtualize, freshen

    export logic_leaf
    export immediate
    export field
    export alias
    export value
    export table
    export subquery
    export query
    export mapjoin
    export aggregate
    export reorder
    export reformat
    export produce
    export plan
    export LogicNode

    export isimmediate, isvalue, isalias, isfield

    export isprotocol

    include("nodes.jl")
end
