struct Null end

FinchNotation.finch_leaf(x::Null) = literal(x)
instantiate(tns::Null, ctx, mode, protos) = tns