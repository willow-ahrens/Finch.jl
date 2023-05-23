@kwdef struct Resumable
    ctx
    root
    style
    meta 
end

function Base.show(io::IO, mime::MIME"text/plain", node::Resumable)
    if length(node.meta) == 0
        println("@finch")
        show(io, mime, node.root)
    else
        println("@finch")
        show(io, mime, node.meta)
        show(io, mime, node.root)
    end
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
    if length(node.meta) == 0
        println("@finch")
        show(io, MIME"text/plain"(), node.root)
    else
        println("@finch")
        show(io, MIME"text/plain"(), node.meta)
        show(io, MIME"text/plain"(), node.root)
    end
end


function number_resumables(code)
    counter = 0
    Postwalk(node -> 
                    if node isa Resumable 
                        node.meta[:Number] = counter
                        counter+=1 
                        node
                    end )(code)
end

function record_methods(code)
    Postwalk(node -> 
    if node isa Resumable 
        node.meta[:Which] = @which node.ctx(node.root)
        counter+=1 
        node
    end )(code)
end


abstract type AbstractLoweringControl end

function should_resume(c :: AbstractLoweringControl, ctx, node, style, meta)
   true
end

function update_meta(c:: AbstractLoweringControl, ctx, node, style, meta)
   meta
end

function should_pause(c:: AbstractLoweringControl, ctx, node, style)
    false
end

function init_meta(c:: AbstractLoweringControl, ctx, node, style)
    Dict{Symbol,Any}()
end

function evolve_control(c:: AbstractLoweringControl, ctx, node, style)
    c
end

@kwdef struct DebugContext{T<:AbstractLoweringControl} <: AbstractCompiler
    ctx=LowerJulia()
    control::T
end

#Sad but true
function Base.getproperty(ctx::DebugContext, name::Symbol)
    if name === :control
        return getfield(ctx, :control)
    elseif name === :ctx
        return getfield(ctx, :ctx)
    end
    getproperty(ctx.ctx, name)
end

function Base.setproperty!(ctx::DebugContext, name::Symbol, x)
    setproperty!(ctx.ctx, name, x)
end

function (ctx::DebugContext)(node, style)
    if node isa Resumable
        if should_resume(ctx.control, ctx, node.root, style, node.meta)
            node.ctx(node.root)
        else
            Resumable(ctx.ctx, node.root, style, update_meta(ctx.control, ctx, node.root, style, node.meta))
        end
    elseif should_pause(ctx.control, ctx, node, style)
        Resumable(ctx.ctx, node, style, init_meta(ctx.control, ctx, node, style))
    else
        control = evolve_control(ctx.control, ctx, node, style)
        lower(node, DebugContext(ctx.ctx, control), style)
    end
end

function (ctx::DebugContext)(code: Expr)
    Postwalk(node -> 
    if node isa Resumable 
        (ctx::DebugContext)(node.node, node.style)
    end )(code)
end

@kwdef struct SimpleStepControl <: AbstractLoweringControl
    step=1
end
function evolve_control(c:: SimpleStepControl, ctx, node, style)
    SimpleStepControl(step = c.step - 1)
end

function should_pause(c:: SimpleStepControl, ctx, node, style)
    c.step == 0
end


@kwdef struct StepOnlyControl <: AbstractLoweringControl
    step:: Int = 1
    resumeLocations = nothing
    resumeStyles = nothing
    resumeFilter = nothing
end

function evolve_control(c:: StepOnlyControl, ctx, node, style)
    StepExceptControl(step=c.step - 1, resumeLocations=c.resumeLocations,
    resumeStyles=c.resumeStyles, resumeFilter=c.resumeFilter)
end

function should_resume(c :: StepOnlyControl, ctx, node, style, meta)
    should = false
    if !isnothing(c.resumeLocations) && !isnothing(meta)
        if :Number in meta 
            should = meta[:Number] in c.resumeLocations
        end
    end
    if !isnothing(c.resumeStyles)
        should = should || style in c.resumeStyles
    end
    if !isnothing(c.resumeFilter)
        should = should || c.resumeFilter(node)
    end
    should
 end

 function should_pause(c:: StepOnlyControl, ctx, node, style)
    return c.step == 0 && 
 end

# step -> analysis
# step -> analysis -> log.
# new execute code with ...






# Goals:
# Lower by number, by age, by pass function, by source
# Interface: History  as global meta, location as local meta.
# 
# Numbering pass for meta
# WillResumeContext has a meta.
# 
# Lower by number.
# Lower by 
# lower by number
# lower by age.
# lower by countdown


