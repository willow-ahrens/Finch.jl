struct Walk
    name
end

Pigeon.getname(idx::Walk) = idx.name

struct Skip
    name
end

Pigeon.getname(idx::Skip) = idx.name

struct Locate
    name
end

Pigeon.getname(idx::Locate) = idx.name