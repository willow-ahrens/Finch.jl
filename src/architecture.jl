abstract type AbstractDevice end
abstract type AbstractVirtualDevice end
abstract type AbstractTask end
abstract type AbstractVirtualTask end

struct CPU <: AbstractDevice
    n::Int
end
CPU() = CPU(Threads.nthreads())

struct VirtualCPU <: AbstractVirtualDevice
    n
end
virtualize(ex, ::Type{CPU}, ctx) = VirtualCPU(virtualize(:($ex.n), Int, ctx))
FinchNotation.finch_leaf(device::VirtualCPU) = virtual(device)

struct Serial <: AbstractTask end
const serial = Serial()

struct VirtualSerial <: AbstractVirtualTask end
virtualize(ex, ::Type{Serial}, ctx) = VirtualSerial()
FinchNotation.finch_leaf(device::VirtualSerial) = virtual(device)

get_device(::Serial) = CPU(1)
get_task(::Serial) = nothing
virtual_get_device(::VirtualSerial) = VirtualCPU(1)
virtual_get_task(::VirtualSerial) = nothing

struct CPUThread{Parent} <: AbstractTask
    tid::Int
    dev::CPU
    parent::Parent
end

get_device(task::CPUThread) = task.device
get_task(task::CPUThread) = task.parent

struct VirtualCPUThread <: AbstractVirtualTask
    tid
    dev::VirtualCPU
    parent
end

virtualize(ex, ::Type{CPUThread{Parent}}, ctx) where {Parent} =
    VirtualCPUThread(
        virtualize(:($ex.tid), Int, ctx),
        virtualize(:($ex.dev), CPU, ctx),
        virtualize(:($ex.parent), Parent, ctx)
    )
FinchNotation.finch_leaf(device::VirtualCPUThread) = virtual(device)

virtual_get_device(task::VirtualCPUThread) = task.device
virtual_get_task(task::VirtualCPUThread) = task.parent

struct CPULocalVector{V}
    device::CPU
    data::Vector{V}
end

CPULocalVector{V}(device::CPU) where {V} =
    CPULocalVector{V}(device, [V([]) for _ in 1:device.n])

struct VirtualCPULocalVector
    ex
    tag
    V
end

function virtualize(ex, ::Type{CPULocalVector{V}}, ctx, tag) where {V}
    sym = freshen(ctx, tag)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    VirtualCPULocalVector(sym, tag, V)
end
FinchNotation.finch_leaf(device::VirtualCPULocalVector) = virtual(device)

function moveto(vec::Vector, device::CPU)
    return vec
end

function moveto(vec::Vector, task::CPUThread)
    return copy(vec)
end

function moveto(vec::CPULocalVector, task::CPUThread)
    return vec.data[task.tid]
end

function virtual_moveto(vec::VirtualCPULocalVector, ctx, dev::VirtualCPU)
    return virtualize(:($(vec.sym)[$(dev.tid)]), vec.V, ctx.code, Symbol(vec.tag, :_cpu)) 
end