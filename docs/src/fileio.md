```@meta
CurrentModule = Finch
```
# Finch Tensor File Input/Output


## Binsparse Format (`.fbr`)

Finch supports the most recent revision of the
[Binsparse](https://github.com/GraphBLAS/binsparse-specification) binary sparse
tensor format, as well as the proposed [v2.0 tensor
extension](https://github.com/GraphBLAS/binsparse-specification/pull/20). This
is a good option for those who want an efficient way to transfer sparse tensors
between supporting libraries and languages. The Binsparse format represents the
tensor format as a JSON string in the underlying data container, which can be either
HDF5 or a combination of NPY or JSON files.
Binsparse arrays are stored 0-indexed.

```@docs
bspwrite
bspread
```

## TensorMarket (`.mtx`, `.ttx`)

Finch supports the [MatrixMarket](https://math.nist.gov/MatrixMarket/formats.html#MMformat) and [TensorMarket](https://github.com/willow-ahrens/TensorMarket.jl) formats, which prioritize readability and archiveability, storing matrices and tensors in plaintext.

```@docs
fttwrite
fttread
```