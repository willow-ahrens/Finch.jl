#!/usr/bin/env julia

# SPDX-FileCopyrightText: 2026 Finch Developers
# SPDX-License-Identifier: MIT
#
# Julia CLI adapters for the Binsparse compliance test suite.
# These use Finch.jl to perform the actual tensor conversions,
# verifying that Finch understands tensors the same way the
# binsparse spec intends.

using Finch
using HDF5
using NPZ
using JSON
using SparseArrays

# ─── binsparse_to_npy ────────────────────────────────────────────────
# Read a Binsparse HDF5 file with Finch, then write its dense values,
# explicit‑storage pattern, and fill value as separate .npy files.

function cmd_binsparse_to_npy(args)
    if length(args) != 4
        println(
            stderr,
            "usage: binsparse_to_npy <tensor_in> <tensor_out> <pattern_out> <fill_value_out>",
        )
        return 2
    end
    tensor_in, tensor_out, pattern_out, fill_value_out = args

    tns = h5open(tensor_in, "r") do io
        Finch.bspread(io)
    end

    Vf = Finch.fill_value(tns)

    # Dense values
    dense = Array(tns)
    npzwrite(tensor_out, dense)

    pat = Array(pattern!(tns))
    npzwrite(pattern_out, pat)

    npzwrite(fill_value_out, fill(Vf))

    return 0
end

# ─── npy_to_binsparse ────────────────────────────────────────────────
# Read dense .npy, pattern .npy, fill‑value .npy, and a partial JSON
# header, then write a Binsparse HDF5 file using Finch.

function cmd_npy_to_binsparse(args)
    if length(args) != 5
        println(
            stderr,
            "usage: npy_to_binsparse <tensor_in> <pattern_in> <fill_value_in> <header_in> <tensor_out>",
        )
        return 2
    end
    tensor_in, pattern_in, fill_value_in, header_in, tensor_out = args

    dense = npzread(tensor_in)
    pattern = npzread(pattern_in)
    fill_arr = npzread(fill_value_in)
    fill_val = ndims(fill_arr) == 0 ? fill_arr[] : fill_arr[1]
    header = JSON.parsefile(header_in)

    # Build a Finch tensor from dense + pattern + fill
    N = ndims(dense)
    if N == 0
        elem = Element{fill_val,eltype(dense),Int}([dense[]])
        tns = Tensor(elem)
    else
        coords = findall(x -> x != 0, pattern)
        if isempty(coords)
            if N == 1
                tns = Tensor(
                    SparseList(Element{fill_val,eltype(dense),Int}(), size(dense, 1))
                )
            elseif N == 2
                tns = Tensor(
                    Dense{Int}(
                        SparseList(Element{fill_val,eltype(dense),Int}(), size(dense, 1)),
                        size(dense, 2),
                    ),
                )
            else
                idx_arrays = ntuple(i -> Int[], N)
                vals = eltype(dense)[]
                elem = Element{fill_val,eltype(dense),Int}()
                coo = SparseCOO{N,NTuple{N,Int}}(elem, ntuple(i -> size(dense, i), N))
                tns = Tensor(coo)
            end
        else
            idx_arrays = ntuple(i -> Int[c[i] for c in coords], N)
            vals = eltype(dense)[dense[c] for c in coords]
            if N == 1
                perm = sortperm(idx_arrays[1])
                idx_sorted = idx_arrays[1][perm]
                vals_sorted = vals[perm]
                elem = Element{fill_val,eltype(dense),Int}(vals_sorted)
                sl = SparseList{Int}(
                    elem, size(dense, 1), Int[1, length(vals_sorted) + 1], idx_sorted
                )
                tns = Tensor(sl)
            elseif N == 2
                tns = Tensor(
                    Dense{Int}(
                        SparseList(Element{fill_val,eltype(dense),Int}(), size(dense, 1)),
                        size(dense, 2),
                    ),
                )
                for c in coords
                    tns[c[1], c[2]] = dense[c]
                end
            else
                # General N-D: build via dense and dropfills
                tns = Tensor(
                    ntuple(i -> Dense{Int}(nothing, size(dense, i)), N)...,
                    Element{fill_val,eltype(dense),Int}(),
                )

                full = zeros(eltype(dense), size(dense)...) .+ fill_val
                for c in coords
                    full[c] = dense[c]
                end

                elem = Element{fill_val,eltype(dense),Int}()
                shape = ntuple(i -> size(dense, i), N)
                coo_lvl = SparseCOO{N,NTuple{N,Int}}(elem, shape)
                tns = Tensor(coo_lvl)
                for c in coords
                    tns[Tuple(c)...] = dense[c]
                end
            end
        end
    end

    # Write using Finch bspwrite
    h5open(tensor_out, "w") do io
        Finch.bspwrite(io, tns)
    end

    return 0
end

# ─── binsparse_to_binsparse ──────────────────────────────────────────
# Read a Binsparse file with Finch (exercising the parser), then write
# it back out.  The roundtrip forces Finch to fully materialise the
# tensor through its own internal representation.

function cmd_binsparse_to_binsparse(args)
    if length(args) != 2
        println(stderr, "usage: binsparse_to_binsparse <tensor_in> <tensor_out>")
        return 2
    end
    tensor_in, tensor_out = args

    tns = h5open(tensor_in, "r") do io
        Finch.bspread(io)
    end

    h5open(tensor_out, "w") do io
        Finch.bspwrite(io, tns)
    end

    return 0
end

# ─── dispatch ─────────────────────────────────────────────────────────

function main()
    if isempty(ARGS)
        println(stderr, "usage: finch_compliance_cli.jl <command> [args...]")
        exit(2)
    end
    command = ARGS[1]
    rest = ARGS[2:end]

    rc = if command == "binsparse_to_npy"
        cmd_binsparse_to_npy(rest)
    elseif command == "npy_to_binsparse"
        cmd_npy_to_binsparse(rest)
    elseif command == "binsparse_to_binsparse"
        cmd_binsparse_to_binsparse(rest)
    else
        println(stderr, "unknown command: $command")
        2
    end
    exit(rc)
end

main()
