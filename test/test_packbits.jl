@testset "PackBits" begin
    A = @fiber PackBits{0,Int64, UInt8, Float64}(10,[1,2],[10],[1,11],[0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0])
    B = @fiber d{Int64}(e(0.0))
    @finch @loop i B[i] = A[i]
    @test reference_isequal(B, [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0])

    C = @fiber PackBits{0,Int64, UInt8, Float64}(10,[1,3],[0x5,0x85],[1,8],[0.1,0.2,0.3,0.4,0.5,0.6])
    B = @fiber d{Int64}(e(0.0))
    @finch @loop i B[i] = C[i]
    @test reference_isequal(B, [0.1,0.2,0.3,0.4,0.5,0.6,0.6,0.6,0.6,0.6])

    E = copyto!(@fiber(d(pb(Float64))), [ones(4, 4) zeros(4, 4); zeros(4, 4) ones(4, 4)])
    F = @fiber(d(e(0.0)))
    @finch @loop i j F[i] += E[i, j]
    @test reference_isequal(F, [4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0])

    G = @fiber PackBits{Float64}()
    Gd = copyto!(@fiber(d(e(0.0))), [ones(4,1); 6; 7; 8; 9; zeros(4,1); 7; ones(4,1); 8; zeros(4,1); 9])
    @finch @loop i G[i] = Gd[i]
    Gdc = copyto!(@fiber(d(e(0.0))), G)
    @test reference_isequal(Gdc,Gd)

    H = @fiber PackBits{0,Int32, UInt16, Float64}(Int32(0))
    Hd = copyto!(@fiber(d(e(0.0))), [ones(4,1); 6; 7; 8; 9; zeros(4,1); 7; ones(4,1); 8; zeros(4,1); 9; 10; 11])
    @finch @loop i H[i] = Hd[i]
    Hdc = copyto!(@fiber(d(e(0.0))), H)
    @test reference_isequal(Hdc,Hd)
end