let
    #This is a script intended to exercise the basic functionality of Finch during precompilation so that Finch will load faster.

    #the key formats will be 0, 1, 2, and 3 dimensional tensors. The key formats will be Dense, DCSF, CSF, and COO

    #We will test the finch macro through the high-level interface.

    #Since we don't specialize for the size, all sizes will be square

    #We will use Bool, Int, and Float64, and fill values will be 0 and 1

    formats = []
    Ts = [Bool, Int, Float64]

    tik = time()
    for (n, T) in enumerate(Ts)
        if n > 1
            tok = time()
            estimated = ceil(Int, (tok - tik)/(n - 1) * (length(Ts) - n + 1))
            @info "Precompiling common tensor formats... (estimated: $(fld(estimated, 60)) minutes and $(mod(estimated, 60)) seconds)"
        else
            @info "Precompiling common tensor formats..."
        end
        f = zero(T)
        for N in 0:2
            vals = rand(T, [2 for _ in 1:N]...)
            if N == 0
                push!(formats, Scalar(f))
            else
                #Dense
                format = Element(f)
                for i in 1:N
                    format = Dense(format)
                end
                push!(formats, Tensor(format, vals))

                #DCSF
                format = Element(f)
                for i in 1:N
                    format = SparseList(format)
                end
                push!(formats, Tensor(format, vals))

                if N >= 1
                    #CSF
                    if N >= 2
                        format = Element(f)
                        for i in 1:(N - 1)
                            format = SparseList(format)
                        end
                        format = Dense(format)
                        push!(formats, Tensor(format, vals))
                    end
                end
            end
        end
    end

    for (n, format) in enumerate(formats)
        if n > 1
            tok = time()
            estimated = ceil(Int, (tok - tik)/(n - 1) * (length(formats) - n + 1))
            @info "Precompiling common tensor operations... (estimated: $(fld(estimated, 60)) minutes and $(mod(estimated, 60)) seconds)"
        else
            @info "Precompiling common tensor operations..."
        end
        A = deepcopy(format)
        B = deepcopy(format)

        if ndims(format) > 0
            dropfills(A)
        end
        copyto!(A, B)
        A == B
        i = rand(1:2, ndims(A))
        A[i...]
        if eltype(format) == Bool
            .!(A)
            any(A)
            all(A)
        end
        if eltype(format) <: Integer
            .~(A)
            A .& B
            A .| B
        end
        if eltype(format) <: Union{Integer, AbstractFloat} && eltype(format) != Bool
            sum(A)
            A .+ B
            A .- B
            A .* B
        end
    end
    @info "Done!"
end