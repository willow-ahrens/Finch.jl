abstract type IndexNodeInstance end
abstract type IndexStatementInstance <: IndexNodeInstance end
abstract type IndexExpressionInstance <: IndexNodeInstance end
abstract type IndexTerminalInstance <: IndexExpressionInstance end

struct LiteralInstance{val} <: IndexTerminalInstance
end

@inline literal_instance(tns) = LiteralInstance{tns}()

struct PassInstance{Tns} <: IndexStatementInstance
    tns::Tns
end
Base.:(==)(a::PassInstance, b::PassInstance) = a.tns == b.tns

@inline pass_instance(tns) = PassInstance(tns)

struct NameInstance{name} <: IndexTerminalInstance end

@inline name_instance(name) = NameInstance{name}()

struct WithInstance{Cons, Prod} <: IndexStatementInstance
	cons::Cons
	prod::Prod
end
Base.:(==)(a::WithInstance, b::WithInstance) = a.cons == b.cons && a.prod == b.prod

@inline with_instance(cons, prod) = WithInstance(cons, prod)

struct MultiInstance{Bodies} <: IndexStatementInstance
    bodies::Bodies
end
Base.:(==)(a::MultiInstance, b::MultiInstance) = all(a.bodies .== b.bodies)

multi_instance(bodies...) = MultiInstance(bodies)

struct LoopInstance{Idxs<:Tuple, Body} <: IndexStatementInstance
	idxs::Idxs
	body::Body
end
Base.:(==)(a::LoopInstance, b::LoopInstance) = a.idxs == b.idxs && a.body == b.body

@inline loop_instance(args...) = LoopInstance((args[1:end-1]...,), args[end])

struct AssignInstance{Lhs, Op, Rhs} <: IndexStatementInstance
	lhs::Lhs
	op::Op
	rhs::Rhs
end
Base.:(==)(a::AssignInstance, b::AssignInstance) = a.lhs == b.lhs && a.op == b.op && a.rhs == b.rhs

@inline assign_instance(lhs, rhs) = AssignInstance(lhs, nothing, rhs)
@inline assign_instance(lhs, op, rhs) = AssignInstance(lhs, op, rhs)

struct CallInstance{Op, Args<:Tuple} <: IndexExpressionInstance
    op::Op
    args::Args
end
Base.:(==)(a::CallInstance, b::CallInstance) = a.op == b.op && a.args == b.args

@inline call_instance(op, args...) = CallInstance(op, args)

struct AccessInstance{Tns, Mode, Idxs} <: IndexExpressionInstance
    tns::Tns
    mode::Mode
    idxs::Idxs
end
Base.:(==)(a::AccessInstance, b::AccessInstance) = a.tns == b.tns && a.mode == b.mode && a.idxs == b.idxs

@inline access_instance(tns, mode, idxs...) = AccessInstance(tns, mode, idxs)

struct LabelInstance{tag, Tns} <: IndexExpressionInstance
    tns::Tns
end
Base.:(==)(a::LabelInstance, b::LabelInstance) = false
Base.:(==)(a::LabelInstance{tag}, b::LabelInstance{tag}) where {tag} = a.tns == b.tns

@inline label_instance(tag, tns) = LabelInstance{tag, typeof(tns)}(tns)

struct ValueInstance{arg} end

@inline value_instance(arg) = isbits(arg) ? ValueInstance{arg}() : arg
@inline value_instance(arg::Symbol) = ValueInstance{arg}()