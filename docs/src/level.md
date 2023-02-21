```@meta
CurrentModule = Finch
```

Finch implements a flexible array datastructure called a fiber. Fibers represent
arrays as rooted trees, where the child of each node is selected by array
indices. Finch is column major, so the rightmost index corresponds to the top
level of the tree. The tree has multiple levels, each corresponding to an index
in the array. We refer to a node in the tree as a subfiber. All of the nodes at
the same level are stored in the same datastructure, and disambiguated by an
integer `position` which describes the . There are several different
level formats:


We can represent a vector u

In Finch, each level is represented with a different format. Because the level
is responsible for representing all the nodes in a subfiber,

% Analogy to row/column majorness
% Represent a tensor as a vector of vectors
% This forms a trie
% Each level is a mode,
% Each node is a slice, etc.
% everything is a fiber.
% When nonzeros are sparse, don't store them.
% when entire rows are sparse, don't store those
% Dense, CSR, DCSR (dd, ds, ss)
% Different sparse formats can be understood as using different vector types at each level
% The levels are more efficiently stored contiguously, this is where pos and idx come from? <- maybe skip? not sure.
% Tensors are best access in the same order they are stored. concordant iteration
% Fibers are ROW MAJOR! 

%give examples of level formats
%give examples of how the formats can be expressed as levels

Give some examples of why we like COO or Hash, etc.

Give a list of the supported formats.

Give some examples of the formats and the things they support.

# Public Functions

```@docs
fiber
fiber!
sparse
sparse!
```