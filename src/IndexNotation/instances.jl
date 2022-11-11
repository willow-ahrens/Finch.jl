abstract type IndexNodeInstance end
abstract type IndexStatementInstance <: IndexNodeInstance end
abstract type IndexExpressionInstance <: IndexNodeInstance end
abstract type IndexTerminalInstance <: IndexExpressionInstance end

struct literalInstance{val} <: IndexTerminalInstance
end

@inline literal_instance(tns) = literalInstance{tns}()

struct PassInstance{Tnss<:Tuple} <: IndexStatementInstance
    tnss::Tnss
end
Base.:(==)(a::PassInstance, b::PassInstance) = Set([a.tnss...]) == Set([b.tnss...])

@inline pass_instance(tnss...) = PassInstance(tnss)

struct IndexInstance{name} <: IndexTerminalInstance end

@inline index_instance(name) = IndexInstance{name}()

struct ProtocolInstance{Idx, Val} <: IndexExpressionInstance
	idx::Idx
	val::Val
end
Base.:(==)(a::ProtocolInstance, b::ProtocolInstance) = a.idx == b.idx && a.val == b.val
@inline protocol_instance(idx, val) = ProtocolInstance(idx, val)

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

struct LoopInstance{Idx, Body} <: IndexStatementInstance
	idx::Idx
	body::Body
end
Base.:(==)(a::LoopInstance, b::LoopInstance) = a.idx == b.idx && a.body == b.body

@inline loop_instance(idx, body) = LoopInstance(idx, body)
@inline loop_instance(body) = body
@inline loop_instance(idx, args...) = LoopInstance(idx, loop_instance(args...))

struct SieveInstance{Cond, Body} <: IndexStatementInstance
	cond::Cond
	body::Body
end
Base.:(==)(a::SieveInstance, b::SieveInstance) = a.cond == b.cond && a.body == b.body

@inline sieve_instance(cond, body) = SieveInstance(cond, body)
@inline sieve_instance(body) = body
@inline sieve_instance(cond, args...) = SieveInstance(cond, sieve_instance(args...))

struct AssignInstance{Lhs, Op, Rhs} <: IndexStatementInstance
	lhs::Lhs
	op::Op
	rhs::Rhs
end
Base.:(==)(a::AssignInstance, b::AssignInstance) = a.lhs == b.lhs && a.op == b.op && a.rhs == b.rhs

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

struct ReaderInstance end
reader_instance() = ReaderInstance()
Base.:(==)(a::ReaderInstance, b::ReaderInstance) = true
struct UpdaterInstance{InPlace}
	inplace::InPlace
end
@inline updater_instance(inplace) = UpdaterInstance(inplace)
Base.:(==)(a::UpdaterInstance, b::UpdaterInstance) = a.inplace == b.inplace

struct ValueInstance{arg} end

#TODO what is going on here?
#@inline value_instance(arg) = (isbits(arg) || arg isa Type) ? ValueInstance{arg}() : arg #TODO how does this interact with immutable outputs?
#@inline value_instance(arg::Symbol) = ValueInstance{arg}()
@inline value_instance(arg) = index_terminal_instance(arg)
@inline index_terminal_instance(arg::Type) = literal_instance(arg)
@inline index_terminal_instance(arg::Function) = literal_instance(arg)
@inline index_terminal_instance(arg::IndexNodeInstance) = arg
@inline index_terminal_instance(arg) = arg #TODO ValueInstance

@inline index_terminal(arg::Type) = literal(arg)
@inline index_terminal(arg::Function) = literal(arg)
@inline index_terminal(arg::CINNode) = arg
@inline index_terminal(arg) = isliteral(arg) ? literal(arg) : virtual(arg)

Base.convert(::Type{CINNode}, x) = index_terminal(x)
Base.convert(::Type{CINNode}, x::CINNode) = x
Base.convert(::Type{CINNode}, x::Symbol) = error()