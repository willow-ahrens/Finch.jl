module FinchNotation
    using RewriteTools, SyntaxInterface, AbstractTrees, Finch

    export finch_leaf
    export literal
    export index
    export variable
    export virtual
    export value
    export loop
    export assign
    export call
    export cached
    export reader, updater, access
    export define, declare, thaw, freeze
    export sequence
    export protocol
    export sieve
    export FinchNode

    export follow
    export walk
    export gallop
    export extrude
    export laminate
    export defaultread
    export defaultupdate

    export @f, @finch_program, @finch_program_instance

    export isliteral, isvalue, isconstant, isvirtual, isvariable, isindex

    export isprotocol

    export getval, getname

    export overwrite, initwrite, Dimensionless, dimless, extent

    include("nodes.jl")
    include("instances.jl")
    include("protocols.jl")
    include("syntax.jl")
end