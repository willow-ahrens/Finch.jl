export walk

struct Walk
    name
end

Pigeon.getname(idx::Walk) = idx.name

walk(name::Name) = Walk(getname(name))

struct MesaWalk{name} end
@inline mesawalk(name) = MesaWalk{name}()
walk(::MesaName{name}) where {name} = mesawalk(name)
virtualize(ex, ::Type{MesaWalk{name}}, ctx) where {name} = Walk(name)



export follow

struct Follow
    name
end

Pigeon.getname(idx::Follow) = idx.name

follow(name::Name) = Follow(getname(name))

struct MesaFollow{name} end
@inline mesafollow(name) = MesaFollow{name}()
follow(::MesaName{name}) where {name} = mesafollow(name)
virtualize(ex, ::Type{MesaFollow{name}}, ctx) where {name} = Follow(name)

export extrude

struct Extrude
    name
end

Pigeon.getname(idx::Extrude) = idx.name

extrude(name::Name) = Extrude(getname(name))

struct MesaExtrude{name} end
@inline mesaextrude(name) = MesaExtrude{name}()
extrude(::MesaName{name}) where {name} = mesaextrude(name)
virtualize(ex, ::Type{MesaExtrude{name}}, ctx) where {name} = Extrude(name)

export laminate

struct Laminate
    name
end

Pigeon.getname(idx::Laminate) = idx.name

laminate(name::Name) = Laminate(getname(name))

struct MesaLaminate{name} end
@inline mesalaminate(name) = MesaLaminate{name}()
laminate(::MesaName{name}) where {name} = mesalaminate(name)
virtualize(ex, ::Type{MesaLaminate{name}}, ctx) where {name} = Laminate(name)