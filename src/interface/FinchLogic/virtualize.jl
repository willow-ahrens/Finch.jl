# Import necessary modules or types
using Finch

# Base case for virtualization
Finch.virtualize(ex, (@nospecialize T), ctx) = value(ex, T)

# Virtualization for specific node instances
Finch.virtualize(ex, ::Type{LogicNodeInstance.LiteralInstance{val}}, ctx) where {val} = literal(val)
Finch.virtualize(ex, ::Type{LogicNodeInstance.ValueInstance{Val, Type}}, ctx) where {Val, Type} = value(Val, Type)
Finch.virtualize(ex, ::Type{LogicNodeInstance.FieldInstance{name}}, ctx) where {name} = field(freshen(ctx, name))
Finch.virtualize(ex, ::Type{LogicNodeInstance.AliasInstance{name}}, ctx) where {name} = alias(name)

function Finch.virtualize(ex, ::Type{LogicNodeInstance.TableInstance{Tns, Idxs}}, ctx) where {Tns, Idxs}
    tns = virtualize(:($ex.tns), Tns, ctx)
    idxs = [virtualize(:($ex.idxs[$n]), Idx, ctx) for (n, Idx) in enumerate(Idxs.parameters)]
    table(tns, idxs...)
end

function Finch.virtualize(ex, ::Type{LogicNodeInstance.SubQueryInstance{Lhs, Rhs, Body}}, ctx) where {Lhs, Rhs, Body}
    lhs = virtualize(:($ex.lhs), Lhs, ctx)
    rhs = virtualize(:($ex.rhs), Rhs, ctx)
    body = virtualize(:($ex.body), Body, ctx)
    subquery(lhs, rhs, body)
end

function Finch.virtualize(ex, ::Type{LogicNodeInstance.MapJoinInstance{Op, Args}}, ctx) where {Op, Args}
    op = virtualize(:($ex.op), Op, ctx)
    args = [virtualize(:($ex.args[$n]), Arg, ctx) for (n, Arg) in enumerate(Args.parameters)]
    mapjoin(op, args...)
end

function Finch.virtualize(ex, ::Type{LogicNodeInstance.ReducedInstance{Op, Init, Arg, Idxs}}, ctx) where {Op, Init, Arg, Idxs}
    op = virtualize(:($ex.op), Op, ctx)
    init = virtualize(:($ex.init), Init, ctx)
    arg = virtualize(:($ex.arg), Arg, ctx)
    idxs = [virtualize(:($ex.idxs[$n]), Idx, ctx) for (n, Idx) in enumerate(Idxs.parameters)]
    aggregate(op, init, arg, idxs...)
end

function Finch.virtualize(ex, ::Type{LogicNodeInstance.ReorderInstance{Arg, Idxs}}, ctx) where {Arg, Idxs}
    arg = virtualize(:($ex.arg), Arg, ctx)
    idxs = [virtualize(:($ex.idxs[$n]), Idx, ctx) for (n, Idx) in enumerate(Idxs.parameters)]
    reorder(arg, idxs...)
end

function Finch.virtualize(ex, ::Type{LogicNodeInstance.RenameInstance{Arg, Idxs}}, ctx) where {Arg, Idxs}
    arg = virtualize(:($ex.arg), Arg, ctx)
    idxs = [virtualize(:($ex.idxs[$n]), Idx, ctx) for (n, Idx) in enumerate(Idxs.parameters)]
    rename(arg, idxs...)
end

function Finch.virtualize(ex, ::Type{LogicNodeInstance.ReformatInstance{Tns, Arg}}, ctx) where {Tns, Arg}
    tns = virtualize(:($ex.tns), Tns, ctx)
    arg = virtualize(:($ex.arg), Arg, ctx)
    reformat(tns, arg)
end

function Finch.virtualize(ex, ::Type{LogicNodeInstance.ResultInstance{Args}}, ctx) where {Args}
    args = [virtualize(:($ex.args[$n]), Arg, ctx) for (n, Arg) in enumerate(Args.parameters)]
    result(args...)
end

function Finch.virtualize(ex, ::Type{LogicNodeInstance.EvaluateInstance{Arg}}, ctx) where {Arg}
    arg = virtualize(:($ex.arg), Arg, ctx)
    evaluate(arg)
end