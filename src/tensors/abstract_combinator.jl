abstract type AbstractCombinator <: AbstractTensor end
abstract type AbstractVirtualCombinator <: AbstractVirtualTensor end

Base.show(io::IO, ex::AbstractCombinator) = throw(NotImplementedError())
labelled_show(io::IO, ::AbstractCombinator) = throw(NotImplementedError())
labelled_children(ex::AbstractCombinator) = throw(NotImplementedError())

is_injective(ctx, lvl::AbstractCombinator) = throw(NotImplementedError())
is_atomic(ctx, lvl::AbstractCombinator) = throw(NotImplementedError())
is_concurrent(ctx, lvl::AbstractCombinator) = throw(NotImplementedError())

unwrap(ctx, arr::AbstractCombinator, var) = throw(NotImplementedError())
lower(ctx::AbstractCompiler, tns::AbstractCombinator, ::DefaultStyle) = throw(NotImplementedError())
virtual_size(ctx::AbstractCompiler, arr::AbstractCombinator) = throw(NotImplementedError())

virtual_resize!(ctx::AbstractCompiler, arr::AbstractCombinator, dims...) = throw(NotImplementedError())

virtual_fill_value(ctx::AbstractCompiler, arr::AbstractCombinator) = throw(NotImplementedError())

instantiate(ctx, arr::AbstractCombinator, mode, protos) = throw(NotImplementedError())

get_style(ctx, node::AbstractCombinator, root) = throw(NotImplementedError())

truncate(ctx, node::AbstractCombinator, ext, ext_2) = throw(NotImplementedError())

get_point_body(ctx, node::AbstractCombinator, ext, idx) = throw(NotImplementedError())

unwrap_thunk(ctx, node::AbstractCombinator) = throw(NotImplementedError())

get_run_body(ctx, node::AbstractCombinator, ext) = throw(NotImplementedError())

get_acceptrun_body(ctx, node::AbstractCombinator, ext) = throw(NotImplementedError())

get_sequence_phases(ctx, node::AbstractCombinator, ext) = throw(NotImplementedError())

phase_body(ctx, node::AbstractCombinator, ext, ext_2) = throw(NotImplementedError())
phase_range(ctx, node::AbstractCombinator, ext) = throw(NotImplementedError())

get_spike_body(ctx, node::AbstractCombinator, ext, ext_2) = throw(NotImplementedError())
get_spike_tail(ctx, node::AbstractCombinator, ext, ext_2) = throw(NotImplementedError())

visit_fill_leaf_leaf(node, tns::AbstractCombinator) = throw(NotImplementedError())
visit_simplify(node::AbstractCombinator) = throw(NotImplementedError())

get_switch_cases(ctx, node::AbstractCombinator) = throw(NotImplementedError())

stepper_range(ctx, node::AbstractCombinator, ext) = throw(NotImplementedError())
stepper_body(ctx, node::AbstractCombinator, ext, ext_2) = throw(NotImplementedError())
stepper_seek(ctx, node::AbstractCombinator, ext) = throw(NotImplementedError())

jumper_range(ctx, node::AbstractCombinator, ext) = throw(NotImplementedError())
jumper_body(ctx, node::AbstractCombinator, ext, ext_2) = throw(NotImplementedError())
jumper_seek(ctx, node::AbstractCombinator, ext) = throw(NotImplementedError())

short_circuit_cases(ctx, node::AbstractCombinator, op) = throw(NotImplementedError())

getroot(tns::AbstractCombinator) = throw(NotImplementedError())

unfurl(ctx, tns::AbstractCombinator, ext, mode, protos...) = throw(NotImplementedError())

lower_access(ctx::AbstractCompiler, node, tns::AbstractCombinator) = throw(NotImplementedError())