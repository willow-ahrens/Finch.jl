struct Virtual{T}
    ex
end

virtualize(ex, T, ctx, tag) = virtualize(ex, T, ctx)

virtualize(ex, T, ctx) = Virtual{T}(ex)

SyntaxInterface.istree(::Virtual) = false

isliteral(::Virtual) = false

virtualize(ex, ::Type{IndexNotation.MesaLiteral{val}}, ctx) where {val} = Literal(val)
virtualize(ex, ::Type{IndexNotation.MesaPass{Tns}}, ctx) where {Tns} = Pass(virtualize(:($ex.tns), Tns, ctx))
virtualize(ex, ::Type{IndexNotation.MesaName{name}}, ctx) where {name} = Name(name)
virtualize(ex, ::Type{IndexNotation.MesaWith{Cons, Prod}}, ctx) where {Cons, Prod} = With(virtualize(:($ex.cons), Cons, ctx), virtualize(:($ex.prod), Prod, ctx))
function virtualize(ex, ::Type{IndexNotation.MesaLoop{Idxs, Body}}, ctx) where {Idxs, Body}
    idxs = map(enumerate(Idxs.parameters)) do (n, Idx)
        virtualize(:($ex.idxs[$n]), Idx, ctx)
    end
    body = virtualize(:($ex.body), Body, ctx)
    Loop(idxs, body)
end
function virtualize(ex, ::Type{IndexNotation.MesaAssign{Lhs, Nothing, Rhs}}, ctx) where {Lhs, Rhs}
    Assign(virtualize(:($ex.lhs), Lhs, ctx), nothing, virtualize(:($ex.rhs), Rhs, ctx))
end
function virtualize(ex, ::Type{IndexNotation.MesaAssign{Lhs, Op, Rhs}}, ctx) where {Lhs, Op, Rhs}
    Assign(virtualize(:($ex.lhs), Lhs, ctx), virtualize(:($ex.op), Op, ctx), virtualize(:($ex.rhs), Rhs, ctx))
end
function virtualize(ex, ::Type{IndexNotation.MesaCall{Op, Args}}, ctx) where {Op, Args}
    op = virtualize(:($ex.op), Op, ctx)
    args = map(enumerate(Args.parameters)) do (n, Arg)
        virtualize(:($ex.args[$n]), Arg, ctx)
    end
    Call(op, args)
end
function virtualize(ex, ::Type{IndexNotation.MesaAccess{Tns, Mode, Idxs}}, ctx) where {Tns, Mode, Idxs}
    tns = virtualize(:($ex.tns), Tns, ctx)
    idxs = map(enumerate(Idxs.parameters)) do (n, Idx)
        virtualize(:($ex.idxs[$n]), Idx, ctx)
    end
    Access(tns, virtualize(:($ex.mode), Mode, ctx), idxs)
end
virtualize(ex, ::Type{Read}, ctx) = Read()
virtualize(ex, ::Type{Write}, ctx) = Write()
virtualize(ex, ::Type{Update}, ctx) = Update()
function virtualize(ex, ::Type{IndexNotation.MesaLabel{tag, Tns}}, ctx) where {tag, Tns}
    return virtualize(:($ex.tns), Tns, ctx, tag)
end
virtualize(ex, ::Type{IndexNotation.MesaValue{arg}}, ctx) where {arg} = arg
virtualize(ex, ::Type{IndexNotation.MesaWalk{name}}, ctx) where {name} = Walk(name)
virtualize(ex, ::Type{IndexNotation.MesaFollow{name}}, ctx) where {name} = Follow(name)
virtualize(ex, ::Type{IndexNotation.MesaExtrude{name}}, ctx) where {name} = Extrude(name)
virtualize(ex, ::Type{IndexNotation.MesaLaminate{name}}, ctx) where {name} = Laminate(name)