virtualize(ex, T, ctx, tag) = virtualize(ex, T, ctx)

virtualize(ex, (@nospecialize T), ctx) = value(ex, T)

virtualize(ex, ::Type{FinchNotation.LiteralInstance{val}}, ctx) where {val} = literal(val)
function virtualize(ex, ::Type{FinchNotation.PassInstance{Tnss}}, ctx) where {Tnss}
    tnss = map(enumerate(Tnss.parameters)) do (n, Tns)
        virtualize(:($ex.tnss[$n]), Tns, ctx)
    end
    pass(tnss)
end
function virtualize(ex, ::Type{FinchNotation.IndexInstance{name}}, ctx) where {name}
    ctx.freshen(name)
    index(name)
end
virtualize(ex, ::Type{FinchNotation.ProtocolInstance{Idx, Mode}}, ctx) where {Idx, Mode} = protocol(virtualize(:($ex.idx), Idx, ctx), virtualize(:($ex.mode), Mode, ctx))
virtualize(ex, ::Type{FinchNotation.WithInstance{Cons, Prod}}, ctx) where {Cons, Prod} = with(virtualize(:($ex.cons), Cons, ctx), virtualize(:($ex.prod), Prod, ctx))
function virtualize(ex, ::Type{FinchNotation.MultiInstance{Bodies}}, ctx) where {Bodies}
    bodies = map(enumerate(Bodies.parameters)) do (n, Body)
        virtualize(:($ex.bodies[$n]), Body, ctx)
    end
    multi(bodies...)
end
function virtualize(ex, ::Type{FinchNotation.SieveInstance{Cond, Body}}, ctx) where {Cond, Body}
    cond = virtualize(:($ex.cond), Cond, ctx)
    body = virtualize(:($ex.body), Body, ctx)
    sieve(cond, body)
end
function virtualize(ex, ::Type{FinchNotation.LoopInstance{Idx, Body}}, ctx) where {Idx, Body}
    idx = virtualize(:($ex.idx), Idx, ctx)
    body = virtualize(:($ex.body), Body, ctx)
    loop(idx, body)
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
function virtualize(ex, ::Type{FinchNotation.UpdaterInstance{Mode}}, ctx) where {Mode}
    mode = virtualize(:($ex.mode), Mode, ctx)
    updater(mode)
end
virtualize(ex, ::Type{FinchNotation.ModifyInstance}, ctx) = modify()
virtualize(ex, ::Type{FinchNotation.CreateInstance}, ctx) = create()
function virtualize(ex, ::Type{FinchNotation.VariableInstance{tag, Tns}}, ctx) where {tag, Tns}
    x = virtualize(:($ex.tns), Tns, ctx, tag)
    if index_leaf(x).kind !== virtual
        return x
    else
        ctx.freshen(tag)
        get!(ctx.bindings, tag, x)
        return variable(tag)
    end
end
virtualize(ex, ::Type{Walk}, ctx) = walk
virtualize(ex, ::Type{FastWalk}, ctx) = fastwalk
virtualize(ex, ::Type{Gallop}, ctx) = gallop
virtualize(ex, ::Type{Follow}, ctx) = follow
virtualize(ex, ::Type{Laminate}, ctx) = laminate
virtualize(ex, ::Type{Extrude}, ctx) = extrude