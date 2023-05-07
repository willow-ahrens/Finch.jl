```@meta
CurrentModule = Finch
```
# Finch Tensor File Input/Output

Finch supports many input/output tensor file formats.

## Finch Format (`.fbr`)

Finch's custom binary file format for fibers is best suited to users who plan to
exclusively use Finch in Julia (perhaps across different platforms). This format
straightforwardly maps the fields of Finch fiber formats to arrays in data
containers (currently Finch only supports HDF5, but if you file an issue someone
might add Numpy NPZ). Arrays are stored 1-indexed as they would be in memory.

```@docs
fbrwrite
fbrread
```

## Binsparse Format (`.fbr`)

Finch supports the most recent revision of the
[Binsparse](https://github.com/GraphBLAS/binsparse-specification) binary sparse
tensor format, as well as the proposed [v2.0 tensor
extension](https://github.com/GraphBLAS/binsparse-specification/pull/20). This
is a good option for those who want an efficient way to transfer sparse tensors
between supporting libraries and languages. The Binsparse format represents the
tensor format as a JSON string in the underlying data container (currently Finch
only supports HDF5, but if you file an issue someone might add Numpy NPZ).
Binsparse arrays are stored 0-indexed.

```@docs
bswrite
bsread
```

## TensorMarket (`.mtx`, `.ttx`)

Finch supports the [MatrixMarket](https://math.nist.gov/MatrixMarket/formats.html#MMformat) and [TensorMarket](https://github.com/willow-ahrens/TensorMarket.jl) formats, which prioritize readability and archiveability, storing matrices and tensors in plaintext.

```@docs
fttwrite
fttread
```