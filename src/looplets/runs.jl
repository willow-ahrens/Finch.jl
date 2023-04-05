@kwdef mutable struct Run
    body
end

Base.show(io::IO, ex::Run) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Run)
    print(io, "Run(body = ")
    print(io, ex.body)
    print(io, ")")
end

FinchNotation.finch_leaf(x::Run) = virtual(x)

struct RunStyle end

(ctx::Stylize{LowerJulia})(node::Run) = ctx.root.kind === chunk ? RunStyle() : DefaultStyle()
combine_style(a::DefaultStyle, b::RunStyle) = RunStyle()
combine_style(a::ThunkStyle, b::RunStyle) = ThunkStyle()
combine_style(a::AbstractSimplifyStyle, b::RunStyle) = a
combine_style(a::RunStyle, b::RunStyle) = RunStyle()

function (ctx::LowerJulia)(root::FinchNode, ::RunStyle)
    if root.kind === chunk
        root = Rewrite(Postwalk(
            @rule access(~a::isvirtual, ~m, ~i..., ~j) => begin
                a_2 = get_run_body(a.val, ctx, root.ext)
                if a_2 != nothing
                    access(a_2, m, i...)
                else
                    access(a, m, i..., j)
                end
            end
        ))(root)
        if Stylize(root, ctx)(root) isa RunStyle #TODO do we need this always? Can we do this generically?
            error("run style couldn't lower runs")
        end
        return ctx(root)
    else
        error("unimplemented")
    end
end

get_run_body(node, ctx, ext) = nothing
get_run_body(node::Run, ctx, ext) = node.body
get_run_body(node::Shift, ctx, ext) = get_run_body(node.body, ctx,
        shiftdim(ext, call(-, node.delta)))

#assume ssa

@kwdef mutable struct AcceptRun
    body
end

FinchNotation.finch_leaf(x::AcceptRun) = virtual(x)

#TODO this should go somewhere else
function Finch.virtual_default(x::FinchNode)
    if x.kind === virtual
        Finch.virtual_default(x.val)
    else
        error("unimplemented")
    end
end

Base.show(io::IO, ex::AcceptRun) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::AcceptRun)
    print(io, "AcceptRun(…)")
end

struct AcceptRunStyle end

(ctx::Stylize{LowerJulia})(node::AcceptRun) = ctx.root.kind === chunk ? AcceptRunStyle() : DefaultStyle()
combine_style(a::DefaultStyle, b::AcceptRunStyle) = AcceptRunStyle()
combine_style(a::ThunkStyle, b::AcceptRunStyle) = ThunkStyle()
combine_style(a::AbstractSimplifyStyle, b::AcceptRunStyle) = a
combine_style(a::AcceptRunStyle, b::AcceptRunStyle) = AcceptRunStyle()
combine_style(a::RunStyle, b::AcceptRunStyle) = RunStyle()

function (ctx::LowerJulia)(root::FinchNode, ::AcceptRunStyle)
    if root.kind === chunk
        body = Rewrite(Postwalk(
            @rule access(~a::isvirtual, ~m, ~i..., ~j) => begin
                a_2 = get_acceptrun_body(a.val, ctx, root.ext)
                if a_2 != nothing
                    access(a_2, m, i...)
                else
                    access(a, m, i..., j)
                end
            end
        ))(root.body)
        if getname(root.idx) in getunbound(body)
            #The loop body isn't constant after removing AcceptRuns, lower with a for-loop
            return ctx(root, DefaultStyle())
        else
            #The loop body is constant after removing AcceptRuns, lower only the body once
            return ctx(body)
        end
    elseif root.kind === sequence 
        quote end #TODO this shouldn't need to be specified
    else
        error("unimplemented")
    end
end

get_acceptrun_body(node, ctx, ext) = nothing
get_acceptrun_body(node::AcceptRun, ctx, ext) = node.body(ctx, ext)
get_acceptrun_body(node::Shift, ctx, ext) = get_acceptrun_body(node.body, ctx,
        shiftdim(ext, call(-, node.delta)))

get_point_body(node::AcceptRun, ctx, idx) = node.body(ctx, Extent(idx, idx))

supports_shift(::RunStyle) = true
supports_shift(::AcceptRunStyle) = true