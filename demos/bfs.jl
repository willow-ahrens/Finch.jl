using Finch
using Finch.IndexNotation
using RewriteTools
using BenchmarkTools
using SparseArrays
using LinearAlgebra
using MatrixMarket

# function bfs(edges, source=5)
#     (n, m) = size(edges)

#     @assert n == m
#     F_in = @fiber sl(n, e(0))
#     F_out = @fiber sl(n, e(0))
#     F_tmp = @fiber sl(n, e(0))
#     @finch @loop j F_in[j] = (j == $source)

#     P_in = @fiber d(n, e(0))
#     P_out = @fiber d(n, e(0))
#     P_tmp = @fiber d(n, e(0))
#     @finch @loop j P_in[j] = (j == $source) * (0 - 2) + (j != $source) * (0 - 1)

#     V = @fiber d(n, e(0))
#     B = @fiber d(n, e(0))
#     w = Scalar{0}()

#     while !iszero(F_in.lvl.lvl.val)
#         @finch @loop j V[j] = (P_in[j] == (0 - 1))
    
#         @finch (@loop j @loop k (begin
#             F_out[j] <<or_>>= w[]
#             B[j] <<choose>>= w[] * k
#         end
#             where (w[] = edges[j, k] * F_in[k] * V[j]) ) )
        
#             @finch @loop j P_out[j] = choose(B[j], P_in[j])
       
#         P_tmp = P_in
#         P_in = P_out
#         P_out = P_tmp

#         F_tmp = F_in
#         F_in = F_out
#         F_out = F_tmp
#     end

#     println(P_in.lvl.lvl.val)
#     return P_in
# end

function main()
    s = Scalar{0, Int64}()
    println(s())
    # N = 5
    # matrix = copy(transpose(MatrixMarket.mmread("./graphs/dag5.mtx")))
    # nzval = ones(size(matrix.nzval, 1))
    # edges = Finch.Fiber(
    #             Dense(N,
    #             SparseList(N, matrix.colptr, matrix.rowval,
    #             Element{0}(nzval))))

    # bfs(edges)
end

main()

# works on F dense, edges dense
# fails on F sparse, edges sparse
# fails on F dense, edges sparse
# works on F sparse, edges dense 


@finch (@loop j @loop k (begin
            F_out[j] <<$or>>= w[]
            B[j] <<$choose>>= w[] * k
        end
            where (w[] = edges[j, k] * F_in[k] * V_out[j]) ) )

@finch @loop j P_out[j] = $choose(B[j], P_in[j])