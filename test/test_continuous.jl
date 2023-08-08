@testset "continuous" begin
    @info "Testing Continuous Usage"
    
    using StatsBase
    using Random

    Shape = 100 #1000
    NumItvl = 10 #100 

    # Generating Random Intervals
    v = sort(sample(Random.seed!(1234), 1:Shape, NumItvl*2, replace=false))
    w = sort(sample(Random.seed!(4321), 1:Shape, NumItvl*2, replace=false))
    s1, e1 = v[begin:2:end], v[begin+1:2:end]
    s2, e2 = w[begin:2:end], w[begin+1:2:end]


    let
        x = Fiber(SparseList{Float32}(Element{0}(fill(1, NumItvl)), Shape, [1, NumItvl+1], v))
        y = Fiber(SparseRLE{Float32}(Element{0}(fill(1, NumItvl)), Shape, [1, NumItvl+1], v, v))
        z1 = Scalar(0);
        z2 = Scalar(0);

        io = IOBuffer()
        @repl io @finch_code (z1 .= 0; for i=_; z1[] += x[i] end)
        @repl io @finch (z1 .= 0; for i=_; z1[] += x[i] end)
        @test check_output("continuous_pinpoint_sl.txt", String(take!(io)))

        @repl io @finch_code (z2 .= 0; for i=_; z2[] += y[i] end)
        @repl io @finch (z2 .= 0; for i=_; z2[] += y[i] end)
        @test check_output("continuous_pinpoint_rle.txt", String(take!(io)))
        
        @finch (z1 .= 0; for i=_; z1[] += x[i] * ∂(i) end)
        @finch (z2 .= 0; for i=_; z2[] += y[i] * ∂(i) end)
        @test z1.val == 0 && z2.val == 0
    end

    let
        x = Fiber(SparseRLE{Float32}(Element{0}(fill(1, NumItvl)), Shape, [1, NumItvl+1], s1, e1))
        y = Fiber(SparseRLE{Float32}(Element{0}(fill(1, NumItvl)), Shape, [1, NumItvl+1], s2, e2))
        z = Fiber(SparseRLE{Limit{Float32}}(Element{0}(), Shape))
        s = Scalar(0)

        io = IOBuffer()
        @repl io @finch_code (z .= 0; for i=_; z[i] += x[i] * y[i]  end)
        @repl io @finch (z .= 0; for i=_; z[i] += x[i] * y[i]  end)
        @test check_output("continuous_intersect.txt", String(take!(io)))

        @repl io @finch_code (z .= 0; for i=_; z[i] += x[i] + y[i]  end)
        @repl io @finch (z .= 0; for i=_; z[i] += x[i] + y[i]  end)
        @test check_output("continuous_union.txt", String(take!(io)))

        @repl io @finch_code (s .= 0; for i=_; s[] += (x[i] * y[i])  end)
        @repl io @finch (s .= 0; for i=_; s[] += (x[i] * y[i])  end)
        @test check_output("continuous_intersect_counting.txt", String(take!(io)))

        @repl io @finch_code (s .= 0; for i=_; s[] += (x[i] * y[i]) * ∂(i) end)
        @repl io @finch (s .= 0; for i=_; s[] += (x[i] * y[i]) * ∂(i)  end)
        @test check_output("continuous_intersect_lebesgue.txt", String(take!(io)))
        
        @repl io @finch_code (s .= 0; for i=_; s[] += (x[i] + y[i])  end)
        @repl io @finch (s .= 0; for i=_; s[] += (x[i] + y[i])  end)
        @test check_output("continuous_union_counting.txt", String(take!(io)))

        @repl io @finch_code (s .= 0; for i=_; s[] += (x[i] + y[i]) * ∂(i) end)
        @repl io @finch (s .= 0; for i=_; s[] += (x[i] + y[i]) * ∂(i)  end)
        @test check_output("continuous_union_lebesgue.txt", String(take!(io)))
    end


    let
        colptr = [1+NumItvl*i for i in 0:NumItvl]
        endpoint1 = vcat([sort(sample(Random.seed!(i), 1:Shape, NumItvl*2, replace=false)) for i in 1:NumItvl]...)
        endpoint2 = vcat([sort(sample(Random.seed!(i+NumItvl), 1:Shape, NumItvl*2, replace=false)) for i in 1:NumItvl]...)
        col_s1, col_e1 = endpoint1[begin:2:end], endpoint1[begin+1:2:end]
        col_s2, col_e2 = endpoint2[begin:2:end], endpoint2[begin+1:2:end]

        x = Fiber(SparseRLE{Float32}(SparseRLE{Float32}(Element{0}(fill(1, NumItvl*NumItvl)), Shape, colptr, col_s1, col_e1), Shape, [1, NumItvl+1], s1, e1))
        y = Fiber(SparseRLE{Float32}(SparseRLE{Float32}(Element{0}(fill(1, NumItvl*NumItvl)), Shape, colptr, col_s2, col_e2), Shape, [1, NumItvl+1], s2, e2))
        z = Fiber(SparseRLE{Limit{Float32}}(SparseRLE{Limit{Float32}}(Element{0}(), Shape), Shape))
        s = Scalar(0)

        io = IOBuffer()
        @repl io @finch_code (z .= 0; for i=_, j=_; z[j,i] += x[j,i] * y[j,i] end)
        @repl io @finch (z .= 0; for i=_, j=_; z[j,i] += x[j,i] * y[j,i] end)
        @test check_output("continuous_2d_intersect.txt", String(take!(io)))  

        @repl io @finch_code (z .= 0; for i=_, j=_; z[j,i] += x[j,i] + y[j,i] end)
        @repl io @finch (z .= 0; for i=_, j=_; z[j,i] += x[j,i] + y[j,i] end)
        @test check_output("continuous_2d_union.txt", String(take!(io)))  

        @repl io @finch_code (s .= 0; for i=_, j=_; s[] += (x[j,i] * y[j,i]) * ∂(i,j) end)
        @repl io @finch (s .= 0; for i=_, j=_; s[] += (x[j,i] * y[j,i]) * ∂(i,j) end)
        @test check_output("continuous_2d_intersect_lebesgue.txt", String(take!(io)))  

        @repl io @finch_code (s .= 0; for i=_, j=_; s[] += (x[j,i] * y[j,i]) end)
        @repl io @finch (s .= 0; for i=_, j=_; s[] += (x[j,i] * y[j,i]) end)
        @test check_output("continuous_2d_intersect_counting.txt", String(take!(io)))  

        @repl io @finch_code (s .= 0; for i=_, j=_; s[] += (x[j,i] + y[j,i]) * ∂(i,j) end)
        @repl io @finch (s .= 0; for i=_, j=_; s[] += (x[j,i] + y[j,i]) * ∂(i,j) end)
        @test check_output("continuous_2d_union_lebesgue.txt", String(take!(io)))  

        @repl io @finch_code (s .= 0; for i=_, j=_; s[] += (x[j,i] + y[j,i]) end)
        @repl io @finch (s .= 0; for i=_, j=_; s[] += (x[j,i] + y[j,i]) end)
        @test check_output("continuous_2d_union_counting.txt", String(take!(io)))  
    end

    let
        colptr = [1+NumItvl*i for i in 0:NumItvl]
        endpoint1 = vcat([sort(sample(Random.seed!(i), 1:Shape, NumItvl*2, replace=false)) for i in 1:NumItvl]...)
        col_s1, col_e1 = endpoint1[begin:2:end], endpoint1[begin+1:2:end]

        x1 = Fiber(SparseList{Float32}(SparseRLE{Float32}(Element{0}(fill(1, NumItvl*NumItvl)), Shape, colptr, col_s1, col_e1), Shape, [1, NumItvl+1], e1))
        x2 = Fiber(SparseRLE{Float32}(SparseRLE{Float32}(Element{0}(fill(1, NumItvl*NumItvl)), Shape, colptr, col_s1, col_e1), Shape, [1, NumItvl+1], e1, e1))
        y = Fiber(SparseRLE{Float32}(Element{0}(fill(1, NumItvl)), Shape, [1, NumItvl+1], s2, e2))

        s1 = Scalar(0);
        s2 = Scalar(0);
 
        io = IOBuffer()
        @repl io @finch_code (s1 .= 0; for i=_, j=_; s1[] += x1[j,i] * y[j] * ∂(j) end)
        @repl io @finch (s1 .= 0; for i=_, j=_; s1[] += x1[j,i] * y[j] * ∂(j) end)
        @test check_output("continuous_2d_itvl_sum_sl.txt", String(take!(io)))  

        @repl io @finch_code (s2 .= 0; for i=_, j=_; s2[] += x1[j,i] * y[j] * ∂(j) end)
        @repl io @finch (s2 .= 0; for i=_, j=_; s2[] += x1[j,i] * y[j] * ∂(j) end)
        @test check_output("continuous_2d_itvl_sum_rle.txt", String(take!(io)))  
   
        @test s1==s2
    end

end
