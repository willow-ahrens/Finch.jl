using HDF5
function fbrwrite(fname, fbr::Fiber)
    h5open(fname, "w") do f
        fbrwrite_level(f, fbr.lvl)
    end
    fname
end

function fbrread(fname)
    h5open(fname, "r") do f
        Fiber(fbrread_level(f))
    end
end
fbrread_level(f) = fbrread_level(f, Val(Symbol(read(f["code"]))))

function fbrwrite_level(f, lvl::ElementLevel{D}) where {D}
    f["code"] = "element"
    f["default"] = D
    f["val"] = lvl.val
end
function fbrread_level(f, ::Val{:element})
    D = read(f["default"])
    val = read(f["val"])
    ElementLevel(D, val)
end

function fbrwrite_level(f, lvl::DenseLevel)
    f["code"] = "dense"
    f["size"] = lvl.shape
    fbrwrite_level(create_group(f, "lvl"), lvl.lvl)
end
function fbrread_level(f, ::Val{:dense})
    shape = read(f["size"])
    lvl = fbrread_level(f["lvl"])
    DenseLevel(lvl, shape)
end

function fbrwrite_level(f, lvl::SparseListLevel)
    f["code"] = "sparse_list"
    f["size"] = lvl.shape
    f["ptr"] = lvl.ptr
    f["idx"] = lvl.idx
    fbrwrite_level(create_group(f, "lvl"), lvl.lvl)
end
function fbrread_level(f, ::Val{:sparse_list})
    shape = read(f["size"])
    ptr = read(f["ptr"])
    idx = read(f["idx"])
    lvl = fbrread_level(f["lvl"])
    SparseListLevel(lvl, shape, ptr, idx)
end

function fbrwrite_level(f, lvl::SparseCOOLevel{N}) where {N}
    f["code"] = "sparse_coo"
    f["size"] = [lvl.shape...,]
    f["ndim"] = N
    f["ptr"] = lvl.ptr
    for n = 1:N
        f["idx_$n"] = lvl.tbl[n]
    end
    fbrwrite_level(create_group(f, "lvl"), lvl.lvl)
end
function fbrread_level(f, ::Val{:sparse_coo})
    shape = (read(f["size"])...,)
    N = read(f["ndim"])
    ptr = read(f["ptr"])
    tbl = ([read(f["idx_$n"]) for n in 1:N]...,)
    lvl = fbrread_level(f["lvl"])
    SparseCOOLevel{N}(lvl, shape, tbl, ptr)
end