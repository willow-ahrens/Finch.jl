struct Walk end
const walk = Walk()
Base.show(io::IO, x::Walk) = print(io, "walk")
struct Gallop end
const gallop = Gallop()
Base.show(io::IO, x::Gallop) = print(io, "gallop")
struct Follow end
const follow = Follow()
Base.show(io::IO, x::Follow) = print(io, "follow")
struct Laminate end
const laminate = Laminate()
Base.show(io::IO, x::Laminate) = print(io, "laminate")
struct Extrude end
const extrude = Extrude()
Base.show(io::IO, x::Extrude) = print(io, "extrude")