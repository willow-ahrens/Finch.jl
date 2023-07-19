struct SyntaxVisitor
    ctx
end

"""
    enforce_syntax(prgm, ctx)

Enforce the syntax of a finch program `prgm`. This function is called by
`@finch_program` and `@finch_program_instance` to ensure that the syntax of a
finch program is correct. It is not necessary to call this function directly.
"""
function enforce_syntax(prgm, ctx)
    SyntaxVisitor(ctx)(prgm)
end

function enforce_virtual(node, ctx)
    if node.kind isa virtual
        return node
    elseif @capture node call(~op::isliteral, ~args...)
        args = map(arg->enforce_virtual(arg, ctx), args)
        return virtual_call(op, args...)
    else
        throw(FinchSyntaxError("Expected virtual, got $(node)"))
    end
end

function (ctx::SyntaxVisitor)(node)
    if @capture node access(~tns, ~mode, ~idxs...)
        tns = enforce_virtual(tns, ctx.ctx)
        mode.kind in [reader, updater] || throw(FinchSyntaxError("Expected reader or updater, got $(mode)"))
        All(idxs::isexpression) || throw(FinchSyntaxError("Expected expressions, got $(idxs)"))
        return virtual_access(tns, mode, idxs...) 

    
   
end

