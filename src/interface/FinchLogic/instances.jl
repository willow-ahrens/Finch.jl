abstract type LogicNodeInstance end

struct LiteralInstance{val} <: LogicNodeInstance end
struct FieldInstance{name} <: LogicNodeInstance end
struct AliasInstance{name} <: LogicNodeInstance end
struct TableInstance{Tns, Idxs <: Tuple} <: LogicNodeInstance tns::Tns; idxs::Idxs end
struct SubQueryInstance{Lhs, Rhs, Body} <: LogicNodeInstance lhs::Lhs; rhs::Rhs; body::Body end
struct MapJoinInstance{Op, Args<:Tuple} <: LogicNodeInstance op::Op; args::Args end
struct ReducedInstance{Op, Init, Arg, Idxs <: Tuple} <: LogicNodeInstance op::Op; init::Init; arg::Arg; idxs::Idxs end
struct ReorderInstance{Arg, Idxs <: Tuple} <: LogicNodeInstance arg::Arg; idxs::Idxs end
struct RenameInstance{Arg, Idxs <: Tuple} <: LogicNodeInstance arg::Arg; idxs::Idxs end
struct ReformatInstance{Tns, Arg} <: LogicNodeInstance tns::Tns; arg::Arg end
struct ResultInstance{Args<:Tuple} <: LogicNodeInstance args::Args end
struct EvaluateInstance{Arg} <: LogicNodeInstance arg::Arg end

# Property getters
Base.getproperty(::LiteralInstance{val}, name::Symbol) where {val} = name == :val ? val : error("type LiteralInstance has no field $name")
Base.getproperty(::FieldInstance{val}, name::Symbol) where {val} = name == :name ? val : error("type FieldInstance has no field $name")
Base.getproperty(::AliasInstance{val}, name::Symbol) where {val} = name == :name ? val : error("type AliasInstance has no field $name")

# Instance constructors
@inline literal_instance(val) = LiteralInstance{val}()
@inline field_instance(name) = FieldInstance{name}()
@inline alias_instance(name) = AliasInstance{name}()
@inline table_instance(tns, idxs...) = TableInstance(tns, idxs)
@inline subquery_instance(lhs, rhs, body) = SubQueryInstance(lhs, rhs, body)
@inline mapjoin_instance(op, args...) = MapJoinInstance(op, args)
@inline aggregate_instance(op, init, arg, idxs...) = ReducedInstance(op, init, arg, idxs)
@inline reorder_instance(arg, idxs...) = ReorderInstance(arg, idxs)
@inline rename_instance(arg, idxs...) = RenameInstance(arg, idxs)
@inline reformat_instance(tns, arg) = ReformatInstance(tns, arg)
@inline result_instance(args...) = ResultInstance(args)
@inline evaluate_instance(arg) = EvaluateInstance(arg)

# Leaf node logic
@inline logic_leaf_instance(arg::Type) = literal_instance(arg)
@inline logic_leaf_instance(arg::Function) = literal_instance(arg)
@inline logic_leaf_instance(arg::LogicNodeInstance) = arg
@inline logic_leaf_instance(arg) = arg

SyntaxInterface.istree(node::LogicNodeInstance) = Int(operation(node)) & IS_TREE != 0
AbstractTrees.children(node::LogicNodeInstance) = istree(node) ? arguments(node) : []
isstateful(node::LogicNodeInstance) = false  # Assuming none of the LogicNode instances are stateful

instance_ctrs = Dict(
	literal => literal_instance,
	field => field_instance,
	alias => alias_instance,
	table => table_instance,
	subquery => subquery_instance,
	mapjoin => mapjoin_instance,
	aggregate => aggregate_instance,
	reorder => reorder_instance,
	rename => rename_instance,
	reformat => reformat_instance,
	result => result_instance,
	evaluate => evaluate_instance
)

function SyntaxInterface.similarterm(::Type{LogicNodeInstance}, op::LogicNodeKind, args)
	instance_ctrs[op](args...)
end

SyntaxInterface.operation(::LiteralInstance) = literal
SyntaxInterface.operation(::FieldInstance) = field
SyntaxInterface.operation(::AliasInstance) = alias
SyntaxInterface.operation(::TableInstance) = table
SyntaxInterface.operation(::SubQueryInstance) = subquery
SyntaxInterface.operation(::MapJoinInstance) = mapjoin
SyntaxInterface.operation(::ReducedInstance) = aggregate
SyntaxInterface.operation(::ReorderInstance) = reorder
SyntaxInterface.operation(::RenameInstance) = rename
SyntaxInterface.operation(::ReformatInstance) = reformat
SyntaxInterface.operation(::ResultInstance) = result
SyntaxInterface.operation(::EvaluateInstance) = evaluate

# SubQuery the arguments function for each instance type
SyntaxInterface.arguments(node::SubQueryInstance) = [node.lhs, node.rhs, node.body]
SyntaxInterface.arguments(node::TableInstance) = [node.tns, node.idxs...]
SyntaxInterface.arguments(node::MapJoinInstance) = [node.op, node.args...]
SyntaxInterface.arguments(node::ReducedInstance) = [node.op, node.init, node.arg, node.idxs...]
SyntaxInterface.arguments(node::ReorderInstance) = [node.arg, node.idxs...]
SyntaxInterface.arguments(node::RenameInstance) = [node.arg, node.idxs...]
SyntaxInterface.arguments(node::ReformatInstance) = [node.tns, node.arg]
SyntaxInterface.arguments(node::ResultInstance) = node.args
SyntaxInterface.arguments(node::EvaluateInstance) = [node.arg]

# Display functions
function Base.show(io::IO, node::LogicNodeInstance)
	print(io, instance_ctrs[operation(node)], "(")
	join(io, arguments(node), ", ")
	print(io, ")")
end

function Base.show(io::IO, mime::MIME"text/plain", node::LogicNodeInstance)
	print(io, "Finch Logic Instance: ")
	display_expression(io, mime, node, 0)
end