using Finch
using Finch.IndexNotation
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

    # 
    (@rule @f(@chunk $i a (b[j...] <<$or>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<$or>>= $d)
    end),

    (@rule @f(@chunk $i a @multi b... (c[j...] <<$or>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @f @multi (c[j...] <<$or>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),
    (@rule @f($or(0, $a)) => a),
    (@rule @f($or($a, 0)) => a),
    (@rule @f($or($a, 1)) => 1),
    (@rule @f($or(1, $a)) => 1),
    
    (@rule @f(@chunk $i a (b[j...] <<$choose>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<$choose>>= $d)
    end),
    (@rule @f(@chunk $i a @multi b... (c[j...] <<choose>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @f @multi (c[j...] <<choose>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),
    (@rule @f($choose(0, $a)) => a),
    (@rule @f($choose($a, 0)) => a)
])

Finch.register()

function F_init(F, source)
    @finch @loop j F[j] = (j == $source)
end

function P_init(P, source)
    @finch @loop j P[j] = (j == $source) * (0 - 2) + (j != $source) * (0 - 1)
end

function V_func(V_out, P_in)
    @finch @loop j V_out[j] = (P_in[j] == (0 - 1))
end

# F_out[j] = edges[j][k] * F_in[k] * V_out[j] | k: (OR, 0)
function F_out_func(F_out, edges, F_in, V_out)
    @finch @loop j k F_out[j] <<$or>>= edges[j, k] * F_in[k] * V_out[j]
end

# P_out[j] = edges[j][k] * F_in[k] * V_out[j] * (k + 1) | k:(CHOOSE, P_in[j])
function P_out_func(P_out, edges, F_in, V_out, P_in, N)
    B = Finch.Fiber(
        Dense(N,
            Element{0, Cint}([])
        )
    )
    @finch @loop j k B[j] <<$choose>>= edges[j, k] * F_in[k] * V_out[j] * k
    @finch @loop j P_out[j] = $choose(B[j], P_in[j])
end

# F_out[j] = edges[j][k] * F_in[k] * V_out[j] | k: (OR, 0)
# P_out[j] = edges[j][k] * F_in[k] * V_out[j] * (k + 1) | k:(CHOOSE, P_in[j])
function P_F(F_out, P_out, P_in, edges, F_in, V_out, N) 
    B = Finch.Fiber(
        Dense(N,
            Element{0, Cint}([])
        )
    )
    @finch @loop j k begin
        F_out[j] <<$or>>= edges[j, k] * F_in[k] * V_out[j]
        B[j] <<$choose>>= edges[j, k] * F_in[k] * V_out[j] * k
      end
    @finch @loop j P_out[j] = $choose(B[j], P_in[j])
end

function main()
    N = 5
    source = 5
    F = Finch.Fiber(
        SparseList(N,
        Element{0, Cint}([]))
    );
    
    F_init(F, source);
    println("F_in:")
    println(F.lvl.lvl.val)

    P = Finch.Fiber(
        Dense(N,
        Element{0, Cint}([]))
    );
    P_init(P, source);
    println("P_in:")
    println(P.lvl.lvl.val)

    V_out = Finch.Fiber(
        Dense(N,
        Element{0, Cint}([]))
    );
    V_func(V_out, P);
    println("V_out:")
    println(V_out.lvl.lvl.val)

    # [0 1 0 0 1; 0 0 1 0 0; 0 0 0 1 0; 0 0 0 0 1; 0 0 0 0 0]
    edge_matrix = sparse([0 0 0 0 0; 1 0 0 0 0; 0 1 0 0 0; 0 0 1 0 0; 1 0 0 1 0])
    edges = Finch.Fiber(
                Dense(N,
                SparseList(N, edge_matrix.colptr, edge_matrix.rowval,
                Element{0.0}(edge_matrix.nzval))))
    # edge_pos = [1, 3, 4, 5, 6, 6]
    # edge_idx = [2, 5, 3, 4, 5]
    # edge_vals = [1, 1, 1, 1, 1]
    # edges = Finch.Fiber(
    #             Dense(N,
    #             SparseList(N, edge_pos, edge_idx,
    #             Element{0.0}(edge_vals))))
    println("Edges:")
    println(edges.lvl.lvl.lvl.val)
    println(edges.lvl.lvl.pos)
    println(edges.lvl.lvl.idx)
    println(edges.lvl.lvl.I)

    F_out = Finch.Fiber(
        SparseList(N,
        Element{0, Cint}([]))
    );
    # F_out_func(F_out, edges, F, V_out);
    # println("F_out:")
    # println(F_out.lvl.lvl.val)

    P_out = Finch.Fiber(
        Dense(N,
        Element{0, Cint}([]))
    );
    # P_out_func(P_out, edges, F, V_out, P, N)
    # println("P_out:")
    # println(P_out.lvl.lvl.val)
    P_F(F_out, P_out, P, edges, F, V_out, N)
    println("F_out:")
    println(F_out.lvl.lvl.val)

    println("P_out:")
    println(P_out.lvl.lvl.val)
end

main()

# works on F dense, edges dense
# fails on F sparse, edges sparse
# fails on F dense, edges sparse
# works on F sparse, edges dense 