let
    #This is a script intended to exercise the basic functionality of Finch during precompilation so that Finch will load faster.

    #the key formats will be 0, 1, 2, and 3 dimensional tensors. The key formats will be Dense, Sparse, CSF, and COO

    #We will test the finch macro through the high-level interface.

    #Since we don't specialize for the size, all sizes will be square

    #We will use Bool, Int, and Float64, and default values will be 0 and 1

    formats = []
    for T in [Bool, Int, Float32, Float64]
        for F in [0, 1]
            f = T(F)
            for N in 0:3
                vals = rand(T, [2 for _ in 1:N]...)
                if N == 0
                    push!(formats, Scalar(f))
                else
                    bases = []
                    push!(bases, Element(f))
                    if T == Bool && F == 0
                        push!(bases, Pattern())
                    end
                    for base in bases
                        #Dense
                        format = deepcopy(base)
                        for i in 1:N
                            format = Dense(format)
                        end
                        push!(formats, Tensor(format, vals))

                        #Sparse
                        format = deepcopy(base)
                        for i in 1:N
                            format = Sparse(format)
                        end
                        push!(formats, Tensor(format, vals))

                        #CSF
                        if N >= 2
                            format = deepcopy(base)
                            for i in 1:(N - 1)
                                format = Sparse(format)
                            end
                            format = Dense(format)
                            push!(formats, Tensor(format, vals))
                        end

                        #COO
                        push!(formats, Tensor(SparseCOO{N}(deepcopy(base)), vals))
                    end
                end
            end
        end
    end

    for format in formats
        As = Any[deepcopy(format)]
        Bs = Any[deepcopy(format)]
        if ndims(format) >= 2
            push!(As, swizzle(deepcopy(format), (ndims(format):-1:1)...))
            push!(Bs, swizzle(deepcopy(format), (ndims(format):-1:1)...))
        end

        for A = As
            if ndims(format) > 0
                dropdefaults(A)
            end
            i = rand(1:2, ndims(A))
            A[i...]
            if ndims(format) == 2
                x = rand(eltype(format), size(A)[2])
                @einsum y[i] += A[i, j] * x[j]
            end
            if eltype(format) == Bool
                all(A)
                any(A)
                .!(A)
            end
            if eltype(format) <: Union{Integer, AbstractFloat} && eltype(format) != Bool
                sum(A)
                prod(A)
                maximum(A)
                minimum(A)
                extrema(A)
                norm(A)
            end
        end
        for A = As, B = Bs
            copyto!(A, B)
            if eltype(format) <: Integer
                A .& B
                A .| B
                A .⊻ B
            end
            if eltype(format) <: Union{Integer, AbstractFloat} && eltype(format) != Bool
                A .+ B
                A .- B
                A .* B
                max.(A, B)
                min.(A, B)
                if ndims(format) == 2
                    @einsum C[i, j] += A[i, k] * B[k, j]
                end
            end
        end
    end
end