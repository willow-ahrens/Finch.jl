abstract type FinchNodeInstance end

struct literalInstance{val} <: FinchNodeInstance
end

@inline literal_instance(tns) = literalInstance{tns}()

struct PassInstance{Tnss<:Tuple} <: FinchNodeInstance
    tnss::Tnss
end
Base.:(==)(a::PassInstance, b::PassInstance) = Set([a.tnss...]) == Set([b.tnss...])

@inline pass_instance(tnss...) = PassInstance(tnss)

struct IndexInstance{name} <: FinchNodeInstance end

@inline index_instance(name) = IndexInstance{name}()

struct ProtocolInstance{Idx, Mode} <: FinchNodeInstance
	idx::Idx
	mode::Mode
end
Base.:(==)(a::ProtocolInstance, b::ProtocolInstance) = a.idx == b.idx && a.mode == b.mode
@inline protocol_instance(idx, mode) = ProtocolInstance(idx, mode)

struct WithInstance{Cons, Prod} <: FinchNodeInstance
	cons::Cons
	prod::Prod
end
Base.:(==)(a::WithInstance, b::WithInstance) = a.cons == b.cons && a.prod == b.prod

@inline with_instance(cons, prod) = WithInstance(cons, prod)

struct MultiInstance{Bodies} <: FinchNodeInstance
    bodies::Bodies
end
Base.:(==)(a::MultiInstance, b::MultiInstance) = all(a.bodies .== b.bodies)

multi_instance(bodies...) = MultiInstance(bodies)

struct LoopInstance{Idx, Body} <: FinchNodeInstance
	idx::Idx
	body::Body
end
Base.:(==)(a::LoopInstance, b::LoopInstance) = a.idx == b.idx && a.body == b.body

@inline loop_instance(idx, body) = LoopInstance(idx, body)
@inline loop_instance(body) = body
@inline loop_instance(idx, args...) = LoopInstance(idx, loop_instance(args...))

struct SieveInstance{Cond, Body} <: FinchNodeInstance
	cond::Cond
	body::Body
end
Base.:(==)(a::SieveInstance, b::SieveInstance) = a.cond == b.cond && a.body == b.body

@inline sieve_instance(cond, body) = SieveInstance(cond, body)
@inline sieve_instance(body) = body
@inline sieve_instance(cond, args...) = SieveInstance(cond, sieve_instance(args...))

struct AssignInstance{Lhs, Op, Rhs} <: FinchNodeInstance
	lhs::Lhs
	op::Op
	rhs::Rhs
end
Base.:(==)(a::AssignInstance, b::AssignInstance) = a.lhs == b.lhs && a.op == b.op && a.rhs == b.rhs

@inline assign_instance(lhs, op, rhs) = AssignInstance(lhs, op, rhs)

struct CallInstance{Op, Args<:Tuple} <: FinchNodeInstance
    op::Op
    args::Args
end
Base.:(==)(a::CallInstance, b::CallInstance) = a.op == b.op && a.args == b.args

@inline call_instance(op, args...) = CallInstance(op, args)

struct AccessInstance{Tns, Mode, Idxs} <: FinchNodeInstance
    tns::Tns
    mode::Mode
    idxs::Idxs
end
Base.:(==)(a::AccessInstance, b::AccessInstance) = a.tns == b.tns && a.mode == b.mode && a.idxs == b.idxs

@inline access_instance(tns, mode, idxs...) = AccessInstance(tns, mode, idxs)

struct VariableInstance{tag, Tns} <: FinchNodeInstance
    tns::Tns
end
Base.:(==)(a::VariableInstance, b::VariableInstance) = false
Base.:(==)(a::VariableInstance{tag}, b::VariableInstance{tag}) where {tag} = a.tns == b.tns

@inline variable_instance(tag, tns) = VariableInstance{tag, typeof(tns)}(tns)

struct ReaderInstance end
reader_instance() = ReaderInstance()
Base.:(==)(a::ReaderInstance, b::ReaderInstance) = true
struct UpdaterInstance{Mode}
	mode::Mode
end
@inline updater_instance(mode) = UpdaterInstance(mode)
Base.:(==)(a::UpdaterInstance, b::UpdaterInstance) = a.mode == b.mode
struct ModifyInstance end
modify_instance() = ModifyInstance()
Base.:(==)(a::ModifyInstance, b::ModifyInstance) = true
struct CreateInstance end
create_instance() = CreateInstance()
Base.:(==)(a::CreateInstance, b::CreateInstance) = true

struct ValueInstance{arg} end

#TODO what is going on here?
#@inline value_instance(arg) = (isbits(arg) || arg isa Type) ? ValueInstance{arg}() : arg #TODO how does this interact with immutable outputs?
#@inline value_instance(arg::Symbol) = ValueInstance{arg}()
@inline value_instance(arg) = index_leaf_instance(arg)
@inline index_leaf_instance(arg::Type) = literal_instance(arg)
@inline index_leaf_instance(arg::Function) = literal_instance(arg)
@inline index_leaf_instance(arg::FinchNodeInstance) = arg
@inline index_leaf_instance(arg) = arg #TODO ValueInstance

@inline index_leaf(arg::Type) = literal(arg)
@inline index_leaf(arg::Function) = literal(arg)
@inline index_leaf(arg::FinchNode) = arg
@inline index_leaf(arg) = isliteral(arg) ? literal(arg) : virtual(arg)

Base.convert(::Type{FinchNode}, x) = index_leaf(x)
Base.convert(::Type{FinchNode}, x::FinchNode) = x
Base.convert(::Type{FinchNode}, x::Symbol) = error()