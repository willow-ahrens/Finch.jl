using Finch
using Finch.IndexNotation
using Finch: execute_code_lowered
using RewriteTools
using BenchmarkTools
using SparseArrays
using LinearAlgebra

or(x,y) = x == 1|| y == 1

function choose(x, y)
    if x != 0
        return x
    else
        return y
    end
end

@slots a b c d e i j Finch.add_rules!([
    (@rule @f(@chunk $i a (b[j...] <<min>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<min>>= $d)
    end),

    (@rule @f(@chunk $i a @multi b... (c[j...] <<min>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @f @multi (c[j...] <<min>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),

    (@rule @f(@chunk $i a (b[j...] <<$or>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<$or>>= $d)
    end),

    (@rule @f(@chunk $i a @multi b... (c[j...] <<$or>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @f @multi (c[j...] <<$or>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),
])

Finch.register()

function out_d_init(out_d, edges)
    @finch @loop i j out_d[j] += edges[i, j]
end

function r_init(r, N)
    @finch @loop j r[j] = 1.0 / $N
end

function c_init(contrib, r_in, out_d)
    @finch @loop i contrib[i] = r_in[i] / out_d[i]
end

function main()
    N = 4
    edge_vector = Cint[0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0]
    edges = Finch.Fiber(
        Dense(N,
                Dense(N,
                    Element{0, Cint}(edge_vector)
                )
            )
    )
    println("Edges:")
    println(edges.lvl.lvl.lvl.val)

    out_d = Finch.Fiber(
        Dense(N,
            Element{0, Cint}([])
        )
    )
    out_d_init(out_d, edges);
    println("Out degree:");
    println(out_d.lvl.lvl.val);

    r = Finch.Fiber(
        Dense(N,
            Element{0, Float64}([])
        )
    )
    r_init(r, N);
    println("R: ");
    println(r.lvl.lvl.val);

    contrib = Finch.Fiber(
        Dense(N,
            Element{0, Float64}([])
        )
    )
    c_init(contrib, r, out_d);
    println("contrib: ");
    println(contrib.lvl.lvl.val);
end

main()