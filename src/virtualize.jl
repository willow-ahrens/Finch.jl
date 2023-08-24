virtualize(ex, T, ctx, tag) = virtualize(ex, T, ctx)

virtualize(ex, (@nospecialize T), ctx) = value(ex, T)

virtualize(ex, ::Type{FinchNotation.LiteralInstance{val}}, ctx) where {val} = literal(val)
function virtualize(ex, ::Type{FinchNotation.IndexInstance{name}}, ctx) where {name}
    ctx.code.freshen(name)
    index(name)
end
virtualize(ex, ::Type{FinchNotation.DefineInstance{Lhs, Rhs}}, ctx) where {Lhs, Rhs} = define(virtualize(:($ex.lhs), Lhs, ctx), virtualize(:($ex.rhs), Rhs, ctx))
virtualize(ex, ::Type{FinchNotation.DeclareInstance{Tns, Init}}, ctx) where {Tns, Init} = declare(virtualize(:($ex.tns), Tns, ctx), virtualize(:($ex.init), Init, ctx))
virtualize(ex, ::Type{FinchNotation.FreezeInstance{Tns}}, ctx) where {Tns} = freeze(virtualize(:($ex.tns), Tns, ctx))
virtualize(ex, ::Type{FinchNotation.ThawInstance{Tns}}, ctx) where {Tns} = thaw(virtualize(:($ex.tns), Tns, ctx))
function virtualize(ex, ::Type{FinchNotation.BlockInstance{Bodies}}, ctx) where {Bodies}
    bodies = map(enumerate(Bodies.parameters)) do (n, Body)
        virtualize(:($ex.bodies[$n]), Body, ctx)
    end
    block(bodies...)
end
function virtualize(ex, ::Type{FinchNotation.SieveInstance{Cond, Body}}, ctx) where {Cond, Body}
    cond = virtualize(:($ex.cond), Cond, ctx)
    body = virtualize(:($ex.body), Body, ctx)
    sieve(cond, body)
end
function virtualize(ex, ::Type{FinchNotation.LoopInstance{Idx, Ext, Body}}, ctx) where {Idx, Ext, Body}
    idx = virtualize(:($ex.idx), Idx, ctx)
    ext = virtualize(:($ex.ext), Ext, ctx)
    body = virtualize(:($ex.body), Body, ctx)
    loop(idx, ext, body)
end
function virtualize(ex, ::Type{FinchNotation.AssignInstance{Lhs, Op, Rhs}}, ctx) where {Lhs, Op, Rhs}
    assign(virtualize(:($ex.lhs), Lhs, ctx), virtualize(:($ex.op), Op, ctx), virtualize(:($ex.rhs), Rhs, ctx))
end
function virtualize(ex, ::Type{FinchNotation.CallInstance{Op, Args}}, ctx) where {Op, Args}
    op = virtualize(:($ex.op), Op, ctx)
    args = map(enumerate(Args.parameters)) do (n, Arg)
        virtualize(:($ex.args[$n]), Arg, ctx)
    end
    call(op, args...)
end
function virtualize(ex, ::Type{FinchNotation.AccessInstance{Tns, Mode, Idxs}}, ctx) where {Tns, Mode, Idxs}
    tns = virtualize(:($ex.tns), Tns, ctx)
    idxs = map(enumerate(Idxs.parameters)) do (n, Idx)
        virtualize(:($ex.idxs[$n]), Idx, ctx)
    end
    access(tns, virtualize(:($ex.mode), Mode, ctx), idxs...)
end
virtualize(ex, ::Type{FinchNotation.ReaderInstance}, ctx) = reader()
virtualize(ex, ::Type{FinchNotation.UpdaterInstance}, ctx) = updater()
virtualize(ex, ::Type{FinchNotation.VariableInstance{tag}}, ctx) where {tag} = variable(tag)
function virtualize(ex, ::Type{FinchNotation.TagInstance{Var, Bind}}, ctx) where {Var, Bind}
    var = virtualize(:($ex.var), Var, ctx)
    bind = virtualize(:($ex.bind), Bind, ctx, var.name)
    tag(var, bind)
end