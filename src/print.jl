#=
function show_buffer(io, args...)
    buf = IOBuffer()
    show(IOContext(buf, io), args...)
    buf
end

show_string(io, args...) = String(take!(show_buffer(io, args...)))

show_width(io, args...) = textwidth(show_string(io, args...))

show_height(io, args...) = length(readlines(show_buffer(io, args...)))

function pretty_padded_elem(io, width, arg)
    show(io, arg)
    println(io, " " ^ max(0, width - show_length(io, args...)))
end
=#

@kwdef struct LeftAlignPrinter
    arg
    width
    pad = " "
end

function Base.show(io, arg::LeftAlignPrinter)
    show(io, arg.arg)
    print(io, arg.pad * (arg.width - textwidth(sprint(show, arg.arg, context = io))))
end

function Base.show(io, ::MIME"text/plain", arg::LeftAlignPrinter)
    show(io, MIME"text/plain"(), arg.arg)
    print(io, arg.pad * (arg.width - textwidth(sprint(show, arg.arg, MIME"text/plain"(), context = io))))
end

function pretty_padded(io, args, width; dots = "…", delim = ", ")
    elem_widths = 
    if sum(pads) + textwidth(delim) * (length(pads) - 1) < width
        for i in 1:length(pads)
            show(io, args[i])
            println(io, " " ^ max(0, pads[i] - textwidth(sprint(show, args[i], context = io))))
            print(io, delim)
        end
    else
        leftwidth = cld(width - textwidth(dots*delim), 2)
        for i = 1:searchsortedlast(cumsum(pads .+ textwidth(delim)), leftwidth)
            show(io, args[i])
            print(io, delim)
            print(io, " " ^ (pads[i] - textwidth(sprint(show, args[i], context = io))))
            leftwidth -= pads[i] + textwidth(delim)
        end
        print(io, " "^leftwidth)
        print(io, dots*delim)
        rightwidth = width - leftwidth - textwidth(dots * delim)
        rightstop = i = length(pads) + 1 - searchsortedlast(cumsum(reverse(pads)), rightwidth)
        sum(pads[rightstop:end])
        for i = rightstop:length(pads) - 1
            show(io, args[i])
            print(io, delim)
            print(io, " " ^ (pads[i] - textwidth(sprint(show, args[i], context = io))))
            leftwidth -= pads[i] + textwidth(delim)
        end
        if rightstop < length(pads)
            show(io, args[i])
            print(io, delim)
        end
    end
        #rightwidth = fld(width - textwidth(space*dots*delim*space), 2)
        #for i = length(pads) + 1 - searchsortedlast(cumsum(reverse(pads)), rightwidth) : length(pads)
        #end

        #lefts = pads[1:]
        #n = 0
        #p = 0
        #while p < fld(width - textwidth(dots) - 1, 2)
        #    n += 1
        #    p += col[n]
        #end
end

args = ones(100)
pads = [3 for _ in args]

pretty_padded(stdout, args, pads, 80, delim = " ")