@testset "moving" begin
    @info "Testing Fiber Moving"

    using Base.Meta
    
    struct ForceCopyArray{T, N} <: AbstractArray{T, N}
        data::Array{T, N}
        function ForceCopyArray{T, N}(arr:: AbstractArray{T, N}) where {T, N}
            copied = copy(arr)
            new{T, N}(arr)
        end
    end


    struct NoCopyArray{T, N} <: AbstractArray{T, N}
        data::Array{T, N}
    end

    Base.promote_rule(::Type{NoCopyArray{T1, N1}}, ::Type{Array{T2, N1}}) where {T1, T2, N1} = Array{Base.promote_type(T1, T2), N1}
    Base.convert(::Type{Array{T1, N1}}, x::NoCopyArray{T2, N2})  where {T1, T2, N1, N2} = convert(Array{T1, N1}, x.data)

    Base.promote_rule(::Type{ForceCopyArray{T1, N1}}, ::Type{Array{T2, N1}}) where {T1, T2, N1} = Array{Base.promote_type(T1, T2),N1}
    Base.convert(::Type{Array{T1, N1}}, x::ForceCopyArray{T1, N1}) where {T1, N1} = convert(Array{T1, N1}, x.data)

    
    @testset "Fiber!(SparseList(Element(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseList(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseList(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArrayconv))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = dropdefaults!(Fiber!(SparseList{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseList(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseList{Int16}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseList(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseList{Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        @test check_output("format_moves_sl_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseVBL(Element(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseVBL(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseVBL(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = dropdefaults!(Fiber!(SparseVBL{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseVBL(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseVBL{Int16}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseVBL(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))


        fbr = Fiber!(SparseVBL{Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))
       

        @test check_output("format_moves_sv_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseByteMap(Element(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseByteMap(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseByteMap(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))
       
        fbr = dropdefaults!(Fiber!(SparseByteMap{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))
        

        fbr = Fiber!(SparseByteMap(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseByteMap{Int16}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseByteMap(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseByteMap{Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        @test check_output("format_moves_sm_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseCOO{1}(Element(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseCOO{1}(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseCOO{1}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = dropdefaults!(Fiber!(SparseCOO{1, Tuple{Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))


        fbr = Fiber!(SparseCOO{1}(Element(0.0), (7,)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseCOO{1, Tuple{Int16}}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseCOO{1}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseCOO{1, Tuple{Int16}}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        @test check_output("format_moves_sc1_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseCOO{2}(Element(0))" begin
        io = IOBuffer()
        arr = [0.0 2.0 2.0 0.0 3.0 3.0;
               1.0 0.0 7.0 1.0 0.0 0.0;
               0.0 0.0 0.0 0.0 0.0 9.0]

        println(io, "Fiber!(SparseCOO{2}(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseCOO{2}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = dropdefaults!(Fiber!(SparseCOO{2, Tuple{Int16, Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))


        fbr = Fiber!(SparseCOO{2}(Element(0.0), (3, 7)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseCOO{2}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        @test check_output("format_moves_sc2_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseHash{1}(Element(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseHash{1}(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseHash{1}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = dropdefaults!(Fiber!(SparseHash{1, Tuple{Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))


        fbr = Fiber!(SparseHash{1}(Element(0.0), (7,)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseHash{1, Tuple{Int16}}(Element(0.0), (7,)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseHash{1}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseHash{1, Tuple{Int16}}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        @test check_output("format_moves_sh1_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseHash{2}(Element(0))" begin
        io = IOBuffer()
        arr = [0.0 2.0 2.0 0.0 3.0 3.0;
               1.0 0.0 7.0 1.0 0.0 0.0;
               0.0 0.0 0.0 0.0 0.0 9.0]

        println(io, "Fiber!(SparseHash{2}(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseHash{2}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = dropdefaults!(Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))


        fbr = Fiber!(SparseHash{2}(Element(0.0), (3, 7)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7)))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseHash{2}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        @test check_output("format_moves_sh2_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseTriangle{2}(Element(0))" begin
        io = IOBuffer()
        arr = [1.0  2.0  3.0  4.0  5.0; 
               6.0  7.0  8.0  9.0  10.0; 
               11.0 12.0 13.0 14.0 15.0; 
               16.0 17.0 18.0 19.0 20.0; 
               21.0 22.0 23.0 24.0 25.0]

        println(io, "Fiber!(SparseTriangle{2}(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseTriangle{2}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = dropdefaults!(Fiber!(SparseTriangle{2, Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))


        fbr = Fiber!(SparseTriangle{2}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseTriangle{2, Int16}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseTriangle{2}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseTriangle{2, Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        @test check_output("format_moves_st2_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseTriangle{3}(Element(0))" begin
        io = IOBuffer()
        arr = collect(reshape(1.0 .* (1:27), 3, 3, 3))

        println(io, "Fiber!(SparseTriangle{3}(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseTriangle{3}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = dropdefaults!(Fiber!(SparseTriangle{3, Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))


        fbr = Fiber!(SparseTriangle{3}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseTriangle{3, Int16}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseTriangle{3}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseTriangle{3, Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        @test check_output("format_moves_st3_e.txt", String(take!(io))) 
    end
     
    @testset "Fiber!(SparseRLE(Element(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseRLE(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseRLE(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = dropdefaults!(Fiber!(SparseRLE{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))


        fbr = Fiber!(SparseRLE(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseRLE{Int16}(Element(0.0), 7))
        println(io, "sized fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseRLE(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseRLE{Int16}(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        #@test check_output("format_moves_srl_e.txt", String(take!(io)))
    end
end
