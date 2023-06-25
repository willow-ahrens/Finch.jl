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
    export reader, updater, create, modify, access
    export declare, thaw, freeze, forget
    export sequence
    export protocol
    export sieve
    export FinchNode

    export Follow, follow
    export Walk, walk
    export Gallop, gallop
    export Extrude, extrude
    export Laminate, laminate

    export @f, @finch_program, @finch_program_instance

    export isliteral, isvalue, isconstant, isvirtual, isvariable, isindex

    export getval, getname

    export overwrite, initwrite

    include("nodes.jl")
    include("instances.jl")
    include("protocols.jl")
    include("syntax.jl")
end