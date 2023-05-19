struct Resumable
    ctx
    root
end

function Base.show(io::IO, mime::MIME"text/plain", node::Resumable)
    println("@finch")
    show(io, mime, node.root)
end

show_with_indent(io, node, indent, prec) = (print("@finch("); Base.show_unquoted(io, node, indent, prec); print(")"))
function show_with_indent(io, node::FinchNode, indent, prec)
    indent = fld(indent, 2) + 1
    if Finch.FinchNotation.isstateful(node)
        println("@finch begin")
        Finch.FinchNotation.display_statement(io, MIME"text/plain"(), node, indent)
        println()
        print("  "^(indent - 1), "end")
    else
        print("@finch("); Finch.FinchNotation.display_expression(io, MIME"text/plain"(), node); print(")")
    end
end

function Base.show_unquoted(io::IO, node::Resumable, indent::Int, prec::Int)
    show_with_indent(io, node.root, indent, prec)
end


function Base.show(io::IO, node::Resumable)
    println("@finch")
    show(io, MIME"text/plain"(), node.root)
end

#resume = Postwalk(node -> if node isa Resumable
#    node.ctx(node.root))

@kwdef struct WillResumeContext <: AbstractCompiler
    ctx::LowerJulia
    countdown = 5
end

#Sad but true
function Base.getproperty(ctx::WillResumeContext, name::Symbol)
    if name === :countdown
        return getfield(ctx, :countdown)
    elseif name === :ctx
        return getfield(ctx, :ctx)
    end
    getproperty(ctx.ctx, name)
end

function Base.setproperty!(ctx::WillResumeContext, name::Symbol, x)
    setproperty!(ctx.ctx, name, x)
end

#5a. Fine you can write Resume
#5b. Willow defines a formal interface for what it means to implement AbstractFinchContext

function (ctx::WillResumeContext)(node, style)
    if ctx.countdown == 0
        Resumable(ctx.ctx, node)
    else
        lower(node, WillResumeContext(ctx.ctx, ctx.countdown - 1), style)
    end
end