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



export locate

struct Locate
    name
end

Pigeon.getname(idx::Locate) = idx.name

locate(name::Name) = Locate(getname(name))

struct MesaLocate{name} end
mesalocate(name) = MesaLocate{name}()
locate(::MesaName{name}) where {name} = mesalocate(name)
virtualize(ex, ::Type{MesaLocate{name}}, ctx) where {name} = Locate(name)