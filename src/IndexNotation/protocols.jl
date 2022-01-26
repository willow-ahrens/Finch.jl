export walk

struct Walk
    name
end

Finch.getname(idx::Walk) = idx.name

walk(name::Name) = Walk(Finch.getname(name))

struct MesaWalk{name} end
@inline mesawalk(name) = MesaWalk{name}()
walk(::MesaName{name}) where {name} = mesawalk(name)



export follow

struct Follow
    name
end

Finch.getname(idx::Follow) = idx.name

follow(name::Name) = Follow(Finch.getname(name))

struct MesaFollow{name} end
@inline mesafollow(name) = MesaFollow{name}()
follow(::MesaName{name}) where {name} = mesafollow(name)

export extrude

struct Extrude
    name
end

Finch.getname(idx::Extrude) = idx.name

extrude(name::Name) = Extrude(Finch.getname(name))

struct MesaExtrude{name} end
@inline mesaextrude(name) = MesaExtrude{name}()
extrude(::MesaName{name}) where {name} = mesaextrude(name)

export laminate

struct Laminate
    name
end

Finch.getname(idx::Laminate) = idx.name

laminate(name::Name) = Laminate(Finch.getname(name))

struct MesaLaminate{name} end
@inline mesalaminate(name) = MesaLaminate{name}()
laminate(::MesaName{name}) where {name} = mesalaminate(name)