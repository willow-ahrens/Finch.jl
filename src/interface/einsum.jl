using Finch.FinchNotation
using Finch.FinchNotation: FinchParserVisitor, index_instance, sieve_instance, define_instance,
    declare_instance, freeze_instance, thaw_instance, assign_instance, call_instance, access_instance,
    yieldbind_instance, literal_instance, variable_instance, tag_instance, finch_leaf_instance

const einsum_nodes = (
    index = index_instance,
    loop = (ex) -> throw(FinchSyntaxError("Einsum expressions don't support for loops.")),
    sieve = sieve_instance,
    block = (ex) -> throw(FinchSyntaxError("Einsum expressions don't support multiple statements")),
    define = define_instance,
    declare = declare_instance,
    freeze = freeze_instance,
    thaw = thaw_instance,
    assign = assign_instance,
    call = call_instance,
    access = access_instance,
    yieldbind = yieldbind_instance,
    reader = literal_instance(reader),
    updater = literal_instance(updater),
    variable = variable_instance,
    tag = (ex) -> :($tag_instance($(variable_instance(ex)), $finch_leaf_instance($(esc(ex))))),
    literal = literal_instance,
    leaf = (ex) -> :($finch_leaf_instance($(esc(ex)))),
    dimless = :($finch_leaf_instance(dimless))
)


# A valid einsum expression takes the form:
# C[idxs..] (+=||<<f>>=) FinchNotationExpr
# We would like to re-use the
function einsum_parser(expr::Expr)
    ctx = FinchParserVisitor(einsum_nodes)
    instance_nodes = ctx(expr)
    return instance_nodes
end

macro einsum_prgm(expr)
    println(einsum_parser(expr))
    return nothing
end
