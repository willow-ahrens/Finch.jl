struct Null end

FinchNotation.finch_leaf(x::Null) = literal(x)
instantiate(ctx, tns::Null, mode, protos) = tns