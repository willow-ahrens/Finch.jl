#TODO delete this line and figure this out with logic_leaf_instance
Finch.virtualize(ex, (@nospecialize T), ctx) = value(ex, T)

Finch.virtualize(ex, ::Type{FinchLogic.LiteralInstance{val}}, ctx) where {val} = literal(val)
function Finch.virtualize(ex, ::Type{FinchLogic.IndexInstance{name}}, ctx) where {name}
    freshen(ctx, name)
    index(name)
end
Finch.virtualize(ex, ::Type{FinchLogic.DefineInstance{Lhs, Rhs, Body}}, ctx) where {Lhs, Rhs, Body} = define(virtualize(:($ex.lhs), Lhs, ctx), virtualize(:($ex.rhs), Rhs, ctx), virtualize(:($ex.body), Body, ctx))
Finch.virtualize(ex, ::Type{FinchLogic.DeclareInstance{Tns, Init}}, ctx) where {Tns, Init} = declare(virtualize(:($ex.tns), Tns, ctx), virtualize(:($ex.init), Init, ctx))
Finch.virtualize(ex, ::Type{FinchLogic.FreezeInstance{Tns}}, ctx) where {Tns} = freeze(virtualize(:($ex.tns), Tns, ctx))
Finch.virtualize(ex, ::Type{FinchLogic.ThawInstance{Tns}}, ctx) where {Tns} = thaw(virtualize(:($ex.tns), Tns, ctx))
function Finch.virtualize(ex, ::Type{FinchLogic.BlockInstance{Bodies}}, ctx) where {Bodies}
    bodies = map(enumerate(Bodies.parameters)) do (n, Body)
        virtualize(:($ex.bodies[$n]), Body, ctx)
    end
    block(bodies...)
end
function Finch.virtualize(ex, ::Type{FinchLogic.SieveInstance{Cond, Body}}, ctx) where {Cond, Body}
    cond = virtualize(:($ex.cond), Cond, ctx)
    body = virtualize(:($ex.body), Body, ctx)
    sieve(cond, body)
end
function Finch.virtualize(ex, ::Type{FinchLogic.LoopInstance{Idx, Ext, Body}}, ctx) where {Idx, Ext, Body}
    idx = virtualize(:($ex.idx), Idx, ctx)
    ext = virtualize(:($ex.ext), Ext, ctx)
    body = virtualize(:($ex.body), Body, ctx)
    loop(idx, ext, body)
end
function Finch.virtualize(ex, ::Type{FinchLogic.AssignInstance{Lhs, Op, Rhs}}, ctx) where {Lhs, Op, Rhs}
    assign(virtualize(:($ex.lhs), Lhs, ctx), virtualize(:($ex.op), Op, ctx), virtualize(:($ex.rhs), Rhs, ctx))
end
function Finch.virtualize(ex, ::Type{FinchLogic.CallInstance{Op, Args}}, ctx) where {Op, Args}
    op = virtualize(:($ex.op), Op, ctx)
    args = map(enumerate(Args.parameters)) do (n, Arg)
        virtualize(:($ex.args[$n]), Arg, ctx)
    end
    call(op, args...)
end
function Finch.virtualize(ex, ::Type{FinchLogic.AccessInstance{Tns, Mode, Idxs}}, ctx) where {Tns, Mode, Idxs}
    tns = virtualize(:($ex.tns), Tns, ctx)
    idxs = map(enumerate(Idxs.parameters)) do (n, Idx)
        virtualize(:($ex.idxs[$n]), Idx, ctx)
    end
    access(tns, virtualize(:($ex.mode), Mode, ctx), idxs...)
end
Finch.virtualize(ex, ::Type{FinchLogic.VariableInstance{tag}}, ctx) where {tag} = variable(tag)
function Finch.virtualize(ex, ::Type{FinchLogic.TagInstance{Var, Bind}}, ctx) where {Var, Bind}
    var = virtualize(:($ex.var), Var, ctx)
    bind = virtualize(:($ex.bind), Bind, ctx, var.name)
    tag(var, bind)
end