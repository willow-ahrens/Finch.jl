function Block(a, b)
    a_stmts = a isa Expr && a.head == :block ? a.args : [a,]
    b_stmts = b isa Expr && b.head == :block ? b.args : [b,]
    return Expr(:block, vcat(a_stmts, b_stmts))
end

Block(args...) = reduce(Block, args)
Block(arg) = arg