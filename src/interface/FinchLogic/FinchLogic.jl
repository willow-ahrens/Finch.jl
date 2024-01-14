module FinchLogic
    using RewriteTools, SyntaxInterface, AbstractTrees, Finch
    using Finch: virtualize, freshen

    export logic_leaf
    export literal
    export index
    export variable
    export value
    export access
    export define
    export mapped
    export reduced
    export reorder
    export reformat
    export result
    export evaluate
    export LogicNode

    export follow
    export walk
    export gallop
    export extrude
    export laminate
    export defaultread
    export defaultupdate

    export @f, @finch_program, @finch_program_instance

    export isliteral, isvalue, isvariable, isindex

    export isprotocol

    include("nodes.jl")
    #include("instances.jl")
    #include("virtualize.jl")
    #include("syntax.jl")
end
