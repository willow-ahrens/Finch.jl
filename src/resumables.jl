struct Resumable
    ctx
    root
end

quote
    for i = 1:10
        println(i)
        $(Hole(ctx, root))
    end
end

function show(io, node::Hole)
end
function show(io, mime::MIME"text/plain", node::Hole)
    println("@finch")
    show(io, mime, node.root)
end

resume = Postwalk(node -> if node isa Hole
    node.ctx(node.root))

quote
    for i = 1:10
        println(i)
        @finch ctx A[i] += B[i] ...
    end
end

struct WillResumeContext
    ctx::LowerJulia
    countdown = 5
end

Base.getproperty(ctx::WillResumeContext, name) = ctx.ctx.name

#1. make (ctx::LowerJulia)(node, style) call prehook(ctx, node, style)
#2. prehook(ctx, node, style) calls lower(ctx, node, style)
#3. rename every overload of LowerJulia as a callable object to an overload of lower function
#4. turn LowerJulia overloads into Abstract type overloads
#5. now you can add WillResumeContext as a subtype of AbstractFinchContext
#5a. Willow defines a formal interface for what it means to implement AbstractFinchContext
#6. Fine you can write Resume

function (ctx::WillResumeContext)(node, style)
    if style == ctx.triggerstyle
        do something real fancy
    elseif ctx.countdown == 0
        Resumable(ctx.ctx, node)
    else
        style = get_style(node)
        WillResumeContext(ctx.ctx, countdown - 1)(node, style)
    end
end