module FinchLogic
    using RewriteTools, SyntaxInterface, AbstractTrees, Finch
    using Finch: virtualize, freshen

    export logic_leaf
    export literal
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
    export result
    export plan
    export LogicNode

    export isliteral, isvalue, isalias, isfield

    export isprotocol

    include("nodes.jl")
end
