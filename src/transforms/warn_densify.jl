"""
    hollowable_rep(tns)

Return true if the data representation could be entirely default(tns)
"""
function hollowable_rep end

hollowable_rep(fbr::HollowData) = true
hollowable_rep(fbr::DenseData) = hollowable_rep(fbr.lvl)
hollowable_rep(fbr::ExtrudeData) = hollowable_rep(fbr.lvl)
hollowable_rep(fbr::SparseData) = true
hollowable_rep(fbr::RepeatData) = false
hollowable_rep(fbr::ElementData) = false

"""
    warn_densify(root, ctx)

Warn if a sparse fiber is accessed in a way that would cause it to be densified.
"""
function warn_densify(root, ctx::AbstractCompiler)
    sproot = Rewrite(Postwalk(Fixpoint(@rule access(~tns, reader(), ~i...) => begin
        if hollowable_rep(virtual_data_rep(tns, ctx))
            virtual_default(tns, ctx)
        end
    end)))(root)
    sproot = simplify(sproot, ctx)

    display(root)
    display(sproot)
end