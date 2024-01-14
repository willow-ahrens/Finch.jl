abstract type LogicNodeInstance end

struct LiteralInstance{val} <: LogicNodeInstance end
struct IndexInstance{name} <: LogicNodeInstance end
struct VariableInstance{name} <: LogicNodeInstance end
struct AccessInstance{Tns, Idxs <: Tuple} <: LogicNodeInstance tns::Tns; idxs::Idxs end
struct DefineInstance{Lhs, Rhs, Body} <: LogicNodeInstance lhs::Lhs; rhs::Rhs; body::Body end
struct MappedInstance{Op, Args<:Tuple} <: LogicNodeInstance op::Op; args::Args end
struct ReducedInstance{Op, Init, Arg, Idxs <: Tuple} <: LogicNodeInstance op::Op; init::Init; arg::Arg; idxs::Idxs end
struct ReorderInstance{Arg, Idxs <: Tuple} <: LogicNodeInstance arg::Arg; idxs::Idxs end
struct RenameInstance{Arg, Idxs <: Tuple} <: LogicNodeInstance arg::Arg; idxs::Idxs end
struct ReformatInstance{Tns, Arg} <: LogicNodeInstance tns::Tns; arg::Arg end
struct ResultInstance{Args<:Tuple} <: LogicNodeInstance args::Args end
struct EvaluateInstance{Arg} <: LogicNodeInstance arg::Arg end

# Property getters
Base.getproperty(::LiteralInstance{val}, name::Symbol) where {val} = name == :val ? val : error("type LiteralInstance has no field $name")
Base.getproperty(::IndexInstance{val}, name::Symbol) where {val} = name == :name ? val : error("type IndexInstance has no field $name")
Base.getproperty(::VariableInstance{val}, name::Symbol) where {val} = name == :name ? val : error("type VariableInstance has no field $name")

# Instance constructors
@inline literal_instance(val) = LiteralInstance{val}()
@inline index_instance(name) = IndexInstance{name}()
@inline variable_instance(name) = VariableInstance{name}()
@inline access_instance(tns, idxs...) = AccessInstance(tns, idxs)
@inline define_instance(lhs, rhs, body) = DefineInstance(lhs, rhs, body)
@inline mapped_instance(op, args...) = MappedInstance(op, args)
@inline reduced_instance(op, init, arg, idxs...) = ReducedInstance(op, init, arg, idxs)
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
	index => index_instance,
	variable => variable_instance,
	access => access_instance,
	define => define_instance,
	mapped => mapped_instance,
	reduced => reduced_instance,
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
SyntaxInterface.operation(::IndexInstance) = index
SyntaxInterface.operation(::VariableInstance) = variable
SyntaxInterface.operation(::AccessInstance) = access
SyntaxInterface.operation(::DefineInstance) = define
SyntaxInterface.operation(::MappedInstance) = mapped
SyntaxInterface.operation(::ReducedInstance) = reduced
SyntaxInterface.operation(::ReorderInstance) = reorder
SyntaxInterface.operation(::RenameInstance) = rename
SyntaxInterface.operation(::ReformatInstance) = reformat
SyntaxInterface.operation(::ResultInstance) = result
SyntaxInterface.operation(::EvaluateInstance) = evaluate

# Define the arguments function for each instance type
SyntaxInterface.arguments(node::DefineInstance) = [node.lhs, node.rhs, node.body]
SyntaxInterface.arguments(node::AccessInstance) = [node.tns, node.idxs...]
SyntaxInterface.arguments(node::MappedInstance) = [node.op, node.args...]
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