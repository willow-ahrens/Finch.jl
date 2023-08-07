@testset "continuous" begin
    @info "Testing Continuous Usage"
    
    using StatsBase
    using Random

    Shape = 1000
    NumItvl = 100 

    # Generating Random Intervals
    v = sort(sample(Random.seed!(1234), 1:Shape, NumItvl*2, replace=false))
    w = sort(sample(Random.seed!(1234), 1:Shape, NumItvl*2, replace=false))
    s1, e1 = v[begin:2:end], v[begin+1:2:end]
    s2, e2 = w[begin:2:end], w[begin+1:2:end]


    let
      pinpoint_sl = Fiber(SparseList{Float32}(Element{0}(fill(1, NumItvl)), Shape, [1, NumItvl+1], v))
      pinpoint_rle = Fiber(SparseRLE{Float32}(Element{0}(fill(1, NumItvl)), Shape, [1, NumItvl+1], v, v))
      z1 = Scalar(0);
      z2 = Scalar(0);

      io = IOBuffer()
      @repl io @finch_code (z1 .= 0; for i=_; z1[] += pinpoint_sl[i] end)
      @repl io @finch (z1 .= 0; for i=_; z1[] += pinpoint_sl[i] end)
      @test check_output("continuous_pinpoint_sl.txt", String(take!(io)))

      @repl io @finch_code (z2 .= 0; for i=_; z2[] += pinpoint_rle[i] end)
      @repl io @finch (z2 .= 0; for i=_; z2[] += pinpoint_rle[i] end)
      @test check_output("continuous_pinpoint_rle.txt", String(take!(io)))
      
      @finch (z1 .= 0; for i=_; z1[] += pinpoint_sl[i] * ∂(i) end)
      @finch (z2 .= 0; for i=_; z2[] += pinpoint_rle[i] * ∂(i) end)
      @test z1 == 0 && z2 == 0


    end

end
