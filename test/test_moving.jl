@testset "moving" begin
    @info "Testing Fiber Moving"

    using Base.Meta
    
    struct ForceCopyArray{T, N} <: AbstractArray{T, N}
        data::Array{T, N}
        function ForceCopyArray(arr:: AbstractArray{T, N}; override=false) where {T, N}
            if ! override
                copied = copy(arr)
                new{T, N}(arr)
            else
                new{T, N}(arr)
            end
        end

        function ForceCopyArray{T, N}(arr:: AbstractArray{T, N}; override=false) where {T, N}
            if ! override
                copied = copy(arr)
                new{T, N}(arr)
            else
                new{T, N}(arr)
            end
        end

        
    end


    struct NoCopyArray{T, N} <: AbstractArray{T, N}
        data::Array{T, N}
    end


    Base.size(A::ForceCopyArray{T, N}) where {T, N} = size(A.data)
    Base.firstindex(A::ForceCopyArray{T, N}) where {T, N} = Base.firstindex(A.data)
    Base.lastindex(A::ForceCopyArray{T, N}) where {T, N} = Base.lastindex(A.data)

    Base.resize!(A::ForceCopyArray{T, N}, ts) where {T, N} = ForceCopyArray{T, N}(resize!(A.data, ts), override=true)
    Base.resize!(A::NoCopyArray{T, N}, ts) where {T, N} = NoCopyArray{T, N}(resize!(A.data, ts))

    Base.size(A::NoCopyArray{T, N}) where {T, N} = size(A.data)
    Base.firstindex(A::NoCopyArray{T, N}) where {T, N} = Base.firstindex(A.data)
    Base.lastindex(A::NoCopyArray{T, N}) where {T, N} = Base.lastindex(A.data)


    Base.getindex(A::NoCopyArray{T,N}, idx:: Int) where {T,N} =
       A.data[idx]
    Base.getindex(A::ForceCopyArray{T,N}, idx:: Int) where {T,N} =
        A.data[idx]
    Base.setindex(A::NoCopyArray{T,N}, v, idx:: Int) where {T,N} =
        setindex(A.data, v, idx)
    Base.setindex(A::ForceCopyArray{T,N}, v, idx:: Int) where {T,N} =
        setindex(A.data, v, idx)
    
    Base.getindex(A::NoCopyArray{T,N}, idx::Vararg{Int,N}) where {T,N} =
        A.data[idx...]
    Base.setindex!(A::NoCopyArray{T,N}, v, idx::Vararg{Int,N}) where {T,N} =
        setindex!(A.data, v, idx...)
    Base.getindex(A::ForceCopyArray{T,N}, idx::Vararg{Int,N}) where {T,N} =
        A.data[idx...]
    Base.setindex!(A::ForceCopyArray{T,N}, v, idx::Vararg{Int,N}) where {T,N} =
        setindex!(A.data, v, idx...)
    Base.show(io::IO, m::MIME"text/plain", A::Union{ForceCopyArray, NoCopyArray}) = show(io, m, A.data)


    Base.promote_rule(::Type{NoCopyArray{T1, N1}}, ::Type{Array{T2, N1}}) where {T1, T2, N1} = Array{Base.promote_type(T1, T2), N1}
    Base.convert(::Type{Array{T1, N1}}, x::NoCopyArray{T2, N2})  where {T1, T2, N1, N2} = convert(Array{T1, N1}, x.data)

    Base.promote_rule(::Type{ForceCopyArray{T1, N1}}, ::Type{Array{T2, N1}}) where {T1, T2, N1} = Array{Base.promote_type(T1, T2),N1}
    Base.convert(::Type{Array{T1, N1}}, x::ForceCopyArray{T1, N1}) where {T1, N1} = convert(Array{T1, N1}, x.data)

    
    @testset "Fiber!(SparseList(Element(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        erg = ForceCopyArray{Float64, 1}(arr)
        a = erg[1]
        println(io, a)

        println(io, "Fiber!(SparseList(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseList(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))


        fbr = dropdefaults!(Fiber!(SparseList{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))

        fbr = Fiber!(SparseList(Element(0.0), 7))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))


        fbr = Fiber!(SparseList{Int16}(Element(0.0), 7))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))

        fbr = Fiber!(SparseList(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))

        fbr = Fiber!(SparseList{Int16}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        @test check_output("format_moves_sl_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseVBL(Element(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseVBL(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseVBL(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))

        fbr = dropdefaults!(Fiber!(SparseVBL{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))

        fbr = Fiber!(SparseVBL(Element(0.0), 7))
                println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))

        fbr = Fiber!(SparseVBL{Int16}(Element(0.0), 7))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))

        fbr = Fiber!(SparseVBL(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))


        fbr = Fiber!(SparseVBL{Int16}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
       

        @test check_output("format_moves_sv_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseByteMap(Element(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseByteMap(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseByteMap(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
       
        fbr = dropdefaults!(Fiber!(SparseByteMap{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))        

        fbr = Fiber!(SparseByteMap(Element(0.0), 7))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseByteMap{Int16}(Element(0.0), 7))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        fbr = Fiber!(SparseByteMap(Element(0.0)))
        println(io, "empty fiber: ", fbr)
        lvl = fbr.lvl
        @test (==)(fbr, moveto(fbr, ForceCopyArray))
        @test (==)(fbr, moveto(fbr, NoCopyArray))

        fbr = Fiber!(SparseByteMap{Int16}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        @test check_output("format_moves_sm_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseCOO{1}(Element(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseCOO{1}(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseCOO{1}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = dropdefaults!(Fiber!(SparseCOO{1, Tuple{Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))

        fbr = Fiber!(SparseCOO{1}(Element(0.0), (7,)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseCOO{1, Tuple{Int16}}(Element(0.0), 7))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseCOO{1}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseCOO{1, Tuple{Int16}}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
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
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = dropdefaults!(Fiber!(SparseCOO{2, Tuple{Int16, Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))

        fbr = Fiber!(SparseCOO{2}(Element(0.0), (3, 7)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseCOO{2}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseCOO{2, Tuple{Int16, Int16}}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        @test check_output("format_moves_sc2_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseHash{1}(Element(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseHash{1}(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseHash{1}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = dropdefaults!(Fiber!(SparseHash{1, Tuple{Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))

        fbr = Fiber!(SparseHash{1}(Element(0.0), (7,)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseHash{1, Tuple{Int16}}(Element(0.0), (7,)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseHash{1}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseHash{1, Tuple{Int16}}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
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
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = dropdefaults!(Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))        

        fbr = Fiber!(SparseHash{2}(Element(0.0), (3, 7)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0), (3, 7)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseHash{2}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseHash{2, Tuple{Int16, Int16}}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
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
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = dropdefaults!(Fiber!(SparseTriangle{2, Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))

        fbr = Fiber!(SparseTriangle{2}(Element(0.0), 7))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseTriangle{2, Int16}(Element(0.0), 7))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseTriangle{2}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseTriangle{2, Int16}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        @test check_output("format_moves_st2_e.txt", String(take!(io)))
    end

    @testset "Fiber!(SparseTriangle{3}(Element(0))" begin
        io = IOBuffer()
        arr = collect(reshape(1.0 .* (1:27), 3, 3, 3))

        println(io, "Fiber!(SparseTriangle{3}(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseTriangle{3}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = dropdefaults!(Fiber!(SparseTriangle{3, Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))

        fbr = Fiber!(SparseTriangle{3}(Element(0.0), 7))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseTriangle{3, Int16}(Element(0.0), 7))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseTriangle{3}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseTriangle{3, Int16}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        @test check_output("format_moves_st3_e.txt", String(take!(io))) 
    end
     
    @testset "Fiber!(SparseRLE(Element(0))" begin
        io = IOBuffer()
        arr = [0.0, 2.0, 2.0, 0.0, 3.0, 3.0]

        println(io, "Fiber!(SparseRLE(Element(0)) moves:")

        fbr = dropdefaults!(Fiber!(SparseRLE(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = dropdefaults!(Fiber!(SparseRLE{Int16}(Element(zero(eltype(arr))))), arr)
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))

        fbr = Fiber!(SparseRLE(Element(0.0), 7))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseRLE{Int16}(Element(0.0), 7))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseRLE(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        fbr = Fiber!(SparseRLE{Int16}(Element(0.0)))
        println(io, "initialized fiber: ", fbr)
        fbr_1 = moveto(fbr, ForceCopyArray)
        println(io, "initialized fiber: ", fbr_1)
        fbr_2 = moveto(fbr, NoCopyArray)
        fbr_3 = moveto(fbr_2, Array)
        println(io, "initialized fiber: ", fbr_2)
        println(io, "initialized fiber: ", fbr_3)
        @test (==)(fbr, fbr_1)
        @test (==)(fbr, fbr_2)
        @test (==)(fbr, fbr_3)
        @test !(isstructequal(fbr, fbr_1))
        @test !(isstructequal(fbr, fbr_2))
        @test (isstructequal(fbr, fbr_3))
        
        @test check_output("format_moves_srl_e.txt", String(take!(io)))
    end

    @testset "typicalAfterMove" begin
        @info "Testing Typical Usage After Move"

        let
            io = IOBuffer()

            @repl io Ap = Fiber!(SparseList(Element(0.0)), [2.0, 0.0, 3.0, 0.0, 4.0, 0.0, 5.0, 0.0, 6.0, 0.0])
            @repl io Bp = Fiber!(Dense(Element(0.0)), fill(1.1, 10))
            @repl io A = moveto(Ap, ForceCopyArray)
            @repl io B = moveto(Bp, ForceCopyArray)
            @repl io @finch_code for i=_; B[i] += A[i] end
            @repl io @finch for i=_; B[i] += A[i] end
        
            @test check_output("typical_inplace_sparse_add_move.txt", String(take!(io)))
        end


        let
            io = IOBuffer()

            @repl io Ap = Fiber!(Dense(SparseList(Element(0.0))), [0 0 3.3; 1.1 0 0; 2.2 0 4.4; 0 0 5.5])
            @repl io yp = fiber!([1.0, 2.0, 3.0, 4.0])
            @repl io xp = fiber!([1, 2, 3])
            @repl io A = moveto(Ap, ForceCopyArray)
            @repl io y = moveto(yp, ForceCopyArray)
            @repl io x = moveto(xp, ForceCopyArray)

            @repl io @finch_code begin
                y .= 0
                for j = _
                    for i = _
                        y[i] += A[i, j] * x[j]
                    end
                end
            end
            @repl io @finch begin
                y .= 0
                for j = _
                    for i = _
                        y[i] += A[i, j] * x[j]
                    end
                end
            end
        
            @test check_output("typical_spmv_csc_move.txt", String(take!(io)))
        end

        # MArray{9}

    #     let
    #         io = IOBuffer()

    #         @repl io A = Fiber!(Dense(SparseList(Element(0.0))), [0 0 3.3; 1.1 0 0; 2.2 0 4.4; 0 0 5.5])
    #         @repl io B = Fiber!(SparseHash{2}(Element(0.0)))
    #         @repl io @finch_code begin
    #             B .= 0
    #             for j = _
    #                 for i = _
    #                     B[j, i] = A[i, j]
    #                 end
    #             end
    #         end
    #         @repl io @finch begin
    #             B .= 0
    #             for j = _
    #                 for i = _
    #                     B[j, i] = A[i, j]
    #                 end
    #             end
    #         end
        
    #         @test check_output("typical_transpose_csc_to_coo.txt", String(take!(io)))
    #     end

    #     let
    #         x = Fiber(
    #             SparseList{Int64, Int64}(
    #                 Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0]),
    #                 10, [1, 6], [1, 3, 5, 7, 9]))
    #         y = Fiber(
    #             SparseList{Int64, Int64}(
    #                 Element{0.0}([1.0, 1.0, 1.0]),
    #                 10, [1, 4], [2, 5, 8]))
    #         z = Fiber(SparseList{Int64, Int64}(Element{0.0}(), 10))
    
    #         io = IOBuffer()

    #         @repl io @finch_code (z .= 0; for i=_; z[i] = x[gallop(i)] + y[gallop(i)] end)
    #         @repl io @finch (z .= 0; for i=_; z[i] = x[gallop(i)] + y[gallop(i)] end)

    #         @test check_output("typical_merge_gallop.txt", String(take!(io)))

    #         io = IOBuffer()

    #         @repl io @finch_code (z .= 0; for i=_; z[i] = x[gallop(i)] + y[i] end)
    #         @repl io @finch (z .= 0; for i=_; z[i] = x[gallop(i)] + y[i] end)

    #         @test check_output("typical_merge_leadfollow.txt", String(take!(io)))

    #         io = IOBuffer()

    #         @repl io @finch_code (z .= 0; for i=_; z[i] = x[i] + y[i] end)
    #         @repl io @finch (z .= 0; for i=_; z[i] = x[i] + y[i] end)

    #         @test check_output("typical_merge_twofinger.txt", String(take!(io)))

    #         io = IOBuffer()

    #         @repl io X = Fiber!(SparseList(Element(0.0)), [1.0, 0.0, 0.0, 3.0, 0.0, 2.0, 0.0])
    #         @repl io x_min = Scalar(Inf)
    #         @repl io x_max = Scalar(-Inf)
    #         @repl io x_sum = Scalar(0.0)
    #         @repl io x_var = Scalar(0.0)
    #         @repl io @finch_code begin
    #             for i = _
    #                 x = X[i]
    #                 x_min[] <<min>>= x
    #                 x_max[] <<max>>= x
    #                 x_sum[] += x
    #                 x_var[] += x * x
    #             end
    #         end

    #         @test check_output("typical_stats_example.txt", String(take!(io)))
    #     end
    end
        
end
