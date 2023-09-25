abstract type AbstractArchitecture end

struct Serial <: AbstractArchitecture end
const serial = Serial()
struct CPU <: AbstractArchitecture
    n::Int
end
CPU() = CPU(nthreads())

struct CPULocalVector{A}
    data::Vector{A}
end

struct CPUGlobalMemory end

function moveto!(vec::Vector, arch::CPUGlobalMemory)
    return vec
end

function moveto!(vec::Vector, arch::CPUThreadMemory)
    return copy(vec)
end

function moveto!(vec::CPULocalVector, arch::CPUThreadMemory)
    return vec.data[arch.tid]
end

global_device(arch::CPU) = arch

local_device(arch::CPU) = CPUThread()