# Finch

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://peterahrens.github.io/Finch.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://peterahrens.github.io/Finch.jl/dev)
[![Build Status](https://github.com/peterahrens/Finch.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/peterahrens/Finch.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/peterahrens/Finch.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/peterahrens/Finch.jl)

Finch is an adaptable compiler for loop nests over structured arrays. Finch can
specialize to tensors with runs of repeated values, or to tensors which are
sparse (mostly zero). Finch supports general sparsity as well as many
specialized sparsity patterns, like clustered nonzeros, diagonals, or triangles.
In addition to zero, Finch supports optimizations over arbitrary fill values and
operators.

At it's heart, Finch is powered by a domain specific language for coiteration,
breaking structured iterators into units we call Looplets. The Looplets are
lowered progressively, leaving several opportunities to rewrite and simplify
each intermediate expression.

