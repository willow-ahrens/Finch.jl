export walk

struct Walk
    name
end

Pigeon.getname(idx::Walk) = idx.name

walk(name::Name) = Walk(getname(name))

struct MesaWalk{name} end
mesawalk(name) = MesaWalk{name}()
walk(::MesaName{name}) where {name} = mesawalk(name)
virtualize(ex, ::Type{MesaWalk{name}}, ctx) where {name} = Walk(name)