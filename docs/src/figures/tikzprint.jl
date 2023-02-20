using Finch
using Finch: Fiber, SubFiber, ElementLevel, DenseLevel

tikzdisplay(io, fbr::Fiber) = tikzdisplay(io, SubFiber(fbr.lvl, 1), "A", 0, 0)
tikzdisplay(io, fbr) = tikzdisplay(io, fbr, 0)
tikzwidth(fbr::SubFiber{<:ElementLevel}) = 1
tikzwidth(fbr::SubFiber{<:DenseLevel}) =
    sum(p->max(tikzwidth(SubFiber(fbr.lvl.lvl, p)), fbr.lvl.I + 1), (fbr.pos - 1) * fbr.lvl.I .+ 1:fbr.lvl.I, init=0)
function tikzdisplay(io, fbr::SubFiber{<:DenseLevel}, tag, y0, x0)
    lvl = fbr.lvl
    tag_2 = "$(tag)f"
    println(io, """
    \\matrix ($tag_2) [matrix of math nodes,
        nodes = {whclsty},
        left delimiter  = (,
        right delimiter = ),
        ampersand replacement=\\&,
        anchor=north west] at ($(x0 + tikzwidth(fbr)/2)*\\myunit, $y0*\\myunit)
    {
    """)
    join(io, ["|[fillsty]|" for i=1:lvl.I], "\\&"); println(io)
    println(io, "}")
    p = (fbr.pos - 1) * fbr.lvl.I
    x = x0
    for i = 1:lvl.I
        p += 1
        subfbr = SubFiber(lvl.lvl, p)
        postag = "$tag_2-1-$i"
        subtag = tikzdisplay(io, subfbr, postag, y0 + 2, x)
        println(io, "\\draw ($postag.center) -- ($subtag.north) node [midway, fill=white] {\$i\$=$i};")
        x += tikzwidth(subfbr)
    end
    tag_2
end
function tikzdisplay(io, fbr::SubFiber{<:ElementLevel}, tag, y0, x0)
    lvl = fbr.lvl
    tag_2 = "$(tag)f"
    println(io, "\\node ($(tag_2)) [nzsty] {$(lvl.val[fbr.pos])} at ($x0 * \\myunit, $y0 * \\myunit);")
    return tag_2
end

tikzdisplay(stdout, @fiber(d(d(e(0))), reshape(1:9, 3, 3).*11))