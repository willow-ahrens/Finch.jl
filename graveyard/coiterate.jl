struct CoiterateStyle end

coiterator(idx, stmt) = stmt
function coiterator(idx, stmt::Access)
    if idx in stmt.idxs[1]
        coiterator_access(stmt.tns, idx, stmt.idxs)
    else
        stmt
    end
end

function lower_loop(stmt, idx, ::CoiterateStyle)
    lower_loop(Prewalk((stmt->coiterator(idx, stmt))(stmt), idx))
end