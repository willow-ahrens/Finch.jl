# Tensor Formats

Finch stores tensors in a variety of formats, each with its own advantages and
disadvantages. The following table summarizes the formats supported by Finch,
and some of their key properties.

# Custom Formats

Finch also supports custom tensor formats. Finch represents tensors
hierarchically in a tree, where each node in the tree is a vector of subtensors
and the leaves are the elements.  Thus, a matrix is analogous to a vector of
vectors, and a 3-tensor is analogous to a vector of vectors of vectors.  The
vectors at each level of the tensor all have the same structure, which can be
selected by the user. If the user wishes to 