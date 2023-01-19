virtualize(ex, T, ctx, tag) = virtualize(ex, T, ctx)

virtualize(ex, (@nospecialize T), ctx) = value(ex, T)

virtualize(ex, ::Type{IndexNotation.literalInstance{val}}, ctx) where {val} = literal(val)
function virtualize(ex, ::Type{IndexNotation.PassInstance{Tnss}}, ctx) where {Tnss}
    tnss = map(enumerate(Tnss.parameters)) do (n, Tns)
        virtualize(:($ex.tnss[$n]), Tns, ctx)
    end
    pass(tnss)
end
virtualize(ex, ::Type{IndexNotation.IndexInstance{name}}, ctx) where {name} = index(name)
virtualize(ex, ::Type{IndexNotation.ProtocolInstance{Idx, Mode}}, ctx) where {Idx, Mode} = protocol(virtualize(:($ex.idx), Idx, ctx), virtualize(:($ex.mode), Mode, ctx))
virtualize(ex, ::Type{IndexNotation.WithInstance{Cons, Prod}}, ctx) where {Cons, Prod} = with(virtualize(:($ex.cons), Cons, ctx), virtualize(:($ex.prod), Prod, ctx))
function virtualize(ex, ::Type{IndexNotation.MultiInstance{Bodies}}, ctx) where {Bodies}
    bodies = map(enumerate(Bodies.parameters)) do (n, Body)
        virtualize(:($ex.bodies[$n]), Body, ctx)
    end
    multi(bodies...)
end
function virtualize(ex, ::Type{IndexNotation.SieveInstance{Cond, Body}}, ctx) where {Cond, Body}
    cond = virtualize(:($ex.cond), Cond, ctx)
    body = virtualize(:($ex.body), Body, ctx)
    sieve(cond, body)
end
function virtualize(ex, ::Type{IndexNotation.LoopInstance{Idx, Body}}, ctx) where {Idx, Body}
    idx = virtualize(:($ex.idx), Idx, ctx)
    body = virtualize(:($ex.body), Body, ctx)
    loop(idx, body)
end
function virtualize(ex, ::Type{IndexNotation.AssignInstance{Lhs, Op, Rhs}}, ctx) where {Lhs, Op, Rhs}
    assign(virtualize(:($ex.lhs), Lhs, ctx), virtualize(:($ex.op), Op, ctx), virtualize(:($ex.rhs), Rhs, ctx))
end
function virtualize(ex, ::Type{IndexNotation.CallInstance{Op, Args}}, ctx) where {Op, Args}
    op = virtualize(:($ex.op), Op, ctx)
    args = map(enumerate(Args.parameters)) do (n, Arg)
        virtualize(:($ex.args[$n]), Arg, ctx)
    end
    call(op, args...)
end
function virtualize(ex, ::Type{IndexNotation.AccessInstance{Tns, Mode, Idxs}}, ctx) where {Tns, Mode, Idxs}
    tns = virtualize(:($ex.tns), Tns, ctx)
    idxs = map(enumerate(Idxs.parameters)) do (n, Idx)
        virtualize(:($ex.idxs[$n]), Idx, ctx)
    end
    access(tns, virtualize(:($ex.mode), Mode, ctx), idxs...)
end
virtualize(ex, ::Type{IndexNotation.ReaderInstance}, ctx) = reader()
function virtualize(ex, ::Type{IndexNotation.UpdaterInstance{Mode}}, ctx) where {Mode}
    mode = virtualize(:($ex.mode), Mode, ctx)
    updater(mode)
end
virtualize(ex, ::Type{IndexNotation.ModifyInstance}, ctx) = modify()
virtualize(ex, ::Type{IndexNotation.CreateInstance}, ctx) = create()
function virtualize(ex, ::Type{IndexNotation.VariableInstance{tag, Tns}}, ctx) where {tag, Tns}
    get!(ctx.bindings, tag) do
        virtualize(:($ex.tns), Tns, ctx, tag)
    end
    return variable(tag)
end
virtualize(ex, ::Type{IndexNotation.ValueInstance{arg}}, ctx) where {arg} = isliteral(arg) ? arg : literal(arg)
virtualize(ex, ::Type{Walk}, ctx) = walk
virtualize(ex, ::Type{FastWalk}, ctx) = fastwalk
virtualize(ex, ::Type{Gallop}, ctx) = gallop
virtualize(ex, ::Type{Follow}, ctx) = follow
virtualize(ex, ::Type{Laminate}, ctx) = laminate
virtualize(ex, ::Type{Extrude}, ctx) = extrude