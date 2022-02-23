export walk

struct Walk
    name
end

Finch.getname(idx::Walk) = idx.name

walk(name::Name) = Walk(Finch.getname(name))

struct WalkInstance{name} end
@inline walk_instance(name) = WalkInstance{name}()
walk(::NameInstance{name}) where {name} = walk_instance(name)



export gallop

struct Gallop
    name
end

Finch.getname(idx::Gallop) = idx.name

gallop(name::Name) = Gallop(Finch.getname(name))

struct GallopInstance{name} end
@inline gallop_instance(name) = GallopInstance{name}()
gallop(::NameInstance{name}) where {name} = gallop_instance(name)



export follow

struct Follow
    name
end

Finch.getname(idx::Follow) = idx.name

follow(name::Name) = Follow(Finch.getname(name))

struct FollowInstance{name} end
@inline follow_instance(name) = FollowInstance{name}()
follow(::NameInstance{name}) where {name} = follow_instance(name)

export extrude

struct Extrude
    name
end

Finch.getname(idx::Extrude) = idx.name

extrude(name::Name) = Extrude(Finch.getname(name))

struct ExtrudeInstance{name} end
@inline extrude_instance(name) = ExtrudeInstance{name}()
extrude(::NameInstance{name}) where {name} = extrude_instance(name)

export laminate

struct Laminate
    name
end

Finch.getname(idx::Laminate) = idx.name

laminate(name::Name) = Laminate(Finch.getname(name))

struct LaminateInstance{name} end
@inline laminate_instance(name) = LaminateInstance{name}()
laminate(::NameInstance{name}) where {name} = laminate_instance(name)