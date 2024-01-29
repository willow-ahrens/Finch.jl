abstract type AbstractDevice end
abstract type AbstractVirtualDevice end
abstract type AbstractTask end
abstract type AbstractVirtualTask end

struct CPU <: AbstractDevice
    n::Int
end
CPU() = CPU(Threads.nthreads())
@kwdef struct VirtualCPU <: AbstractVirtualDevice
    ex
    n
end
function virtualize(ex, ::Type{CPU}, ctx)
    sym = freshen(ctx, :cpu)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    VirtualCPU(sym, virtualize(:($sym.n), Int, ctx))
end
lower(device::VirtualCPU, ctx::AbstractCompiler, ::DefaultStyle) =
    something(device.ex, :(CPU($(ctx(device.n)))))

FinchNotation.finch_leaf(device::VirtualCPU) = virtual(device)

struct Serial <: AbstractTask end
const serial = Serial()
get_device(::Serial) = CPU(1)
get_task(::Serial) = nothing
struct VirtualSerial <: AbstractVirtualTask end
virtualize(ex, ::Type{Serial}, ctx) = VirtualSerial()
lower(task::VirtualSerial, ctx::AbstractCompiler, ::DefaultStyle) = :(Serial())
FinchNotation.finch_leaf(device::VirtualSerial) = virtual(device)
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
function virtualize(ex, ::Type{CPUThread{Parent}}, ctx) where {Parent}
    VirtualCPUThread(
        virtualize(:($sym.tid), Int, ctx),
        virtualize(:($sym.dev), CPU, ctx),
        virtualize(:($sym.parent), Parent, ctx)
    )
end
lower(task::VirtualCPUThread, ctx::AbstractCompiler, ::DefaultStyle) = :(CPUThread($(ctx(task.tid)), $(ctx(task.dev)), $(ctx(task.parent))))
FinchNotation.finch_leaf(device::VirtualCPUThread) = virtual(device)
virtual_get_device(task::VirtualCPUThread) = task.device
virtual_get_task(task::VirtualCPUThread) = task.parent

struct CPULocalMemory
    device::CPU
end
function moveto(vec::V, mem::CPULocalMemory) where {V <: Vector}
    CPULocalVector{V}(mem.device, [copy(vec) for _ in 1:mem.device.n])
end

struct CPULocalVector{V}
    device::CPU
    data::Vector{V}
end

CPULocalVector{V}(device::CPU) where {V} =
    CPULocalVector{V}(device, [V([]) for _ in 1:device.n])

Base.eltype(::Type{CPULocalVector{V}}) where {V} = eltype(V)
Base.ndims(::Type{CPULocalVector{V}}) where {V} = ndims(V)

function moveto(vec::Vector, device::CPU)
    return vec
end

function moveto(vec::Vector, task::CPUThread)
    return copy(vec)
end

function moveto(vec::CPULocalVector, task::CPUThread)
    return vec.data[task.tid]
end

## GPU part
struct GPUBlock <: AbstractDevice
    n::Int
end
GPUBlock() = GPUBlock(Threads.nthreads())
@kwdef struct VirtualGPUBlock <: AbstractVirtualDevice
    ex
    n
end
function virtualize(ex, ::Type{GPUBlock}, ctx)
    sym = freshen(ctx, :gpublock)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    VirtualGPUBlock(sym, virtualize(:($sym.n), Int, ctx))
end
lower(device::VirtualGPUBlock, ctx::AbstractCompiler, ::DefaultStyle) =
    something(device.ex, :(GPUBlock($(ctx(device.n)))))

FinchNotation.finch_leaf(device::VirtualGPUBlock) = virtual(device)

struct GPUThreadBlock{Parent} <: AbstractTask
    tid::Int
    dev::GPUBlock
    parent::Parent
end
get_device(task::GPUThreadBlock) = task.device
get_task(task::GPUThreadBlock) = task.parent
struct VirtualGPUThreadBlock <: AbstractVirtualTask
    tid
    dev::VirtualGPUBlock
    parent
end
function virtualize(ex, ::Type{GPUThreadBlock{Parent}}, ctx) where {Parent}
    VirtualGPUThreadBlock(
        virtualize(:($sym.tid), Int, ctx),
        virtualize(:($sym.dev), GPUBlock, ctx),
        virtualize(:($sym.parent), Parent, ctx)
    )
end
lower(task::VirtualGPUThreadBlock, ctx::AbstractCompiler, ::DefaultStyle) = :(GPUThreadBlock($(ctx(task.tid)), $(ctx(task.dev)), $(ctx(task.parent))))
FinchNotation.finch_leaf(device::VirtualGPUThreadBlock) = virtual(device)
virtual_get_device(task::VirtualGPUThreadBlock) = task.device
virtual_get_task(task::VirtualGPUThreadBlock) = task.parent

struct GPUBlockLocalMemory
    device::GPUBlock
end
function moveto(vec::V, mem::GPUBlockLocalMemory) where {V <: Vector}
    GPUBlockLocalVector{V}(mem.device, [copy(vec) for _ in 1:mem.device.n])
end

struct GPUBlockLocalVector{V}
    device::GPUBlock
    data::Vector{V}
end

GPUBlockLocalVector{V}(device::GPUBlock) where {V} =
    GPUBlockLocalVector{V}(device, [V([]) for _ in 1:device.n])

Base.eltype(::Type{GPUBlockLocalVector{V}}) where {V} = eltype(V)
Base.ndims(::Type{GPUBlockLocalVector{V}}) where {V} = ndims(V)

function moveto(vec::Vector, device::GPUBlock)
    return vec
end

function moveto(vec::Vector, task::GPUThreadBlock)
    return copy(vec)
end

function moveto(vec::GPUBlockLocalVector, task::GPUThreadBlock)
    return vec.data[task.tid]
end


struct GPUThread <: AbstractDevice
    n::Int
end
GPUThread() = GPUThread(Threads.nthreads())
@kwdef struct VirtualGPUThread <: AbstractVirtualDevice
    ex
    n
end
function virtualize(ex, ::Type{GPUThread}, ctx)
    sym = freshen(ctx, :gputhread)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    VirtualGPUThread(sym, virtualize(:($sym.n), Int, ctx))
end
lower(device::VirtualGPUThread, ctx::AbstractCompiler, ::DefaultStyle) =
    something(device.ex, :(GPUThread($(ctx(device.n)))))

FinchNotation.finch_leaf(device::VirtualGPUThread) = virtual(device)

struct GPUThreadThread{Parent} <: AbstractTask
    tid::Int
    dev::GPUThread
    parent::Parent
end
get_device(task::GPUThreadThread) = task.device
get_task(task::GPUThreadThread) = task.parent
struct VirtualGPUThreadThread <: AbstractVirtualTask
    tid
    dev::VirtualGPUThread
    parent
end
function virtualize(ex, ::Type{GPUThreadThread{Parent}}, ctx) where {Parent}
    VirtualGPUThreadThread(
        virtualize(:($sym.tid), Int, ctx),
        virtualize(:($sym.dev), GPUThread, ctx),
        virtualize(:($sym.parent), Parent, ctx)
    )
end
lower(task::VirtualGPUThreadThread, ctx::AbstractCompiler, ::DefaultStyle) = :(GPUThreadThread($(ctx(task.tid)), $(ctx(task.dev)), $(ctx(task.parent))))
FinchNotation.finch_leaf(device::VirtualGPUThreadThread) = virtual(device)
virtual_get_device(task::VirtualGPUThreadThread) = task.device
virtual_get_task(task::VirtualGPUThreadThread) = task.parent

struct GPUThreadLocalMemory
    device::GPUThread
end
function moveto(vec::V, mem::GPUThreadLocalMemory) where {V <: Vector}
    GPUThreadLocalVector{V}(mem.device, [copy(vec) for _ in 1:mem.device.n])
end

struct GPUThreadLocalVector{V}
    device::GPUThread
    data::Vector{V}
end

GPUThreadLocalVector{V}(device::GPUThread) where {V} =
    GPUThreadLocalVector{V}(device, [V([]) for _ in 1:device.n])

Base.eltype(::Type{GPUThreadLocalVector{V}}) where {V} = eltype(V)
Base.ndims(::Type{GPUThreadLocalVector{V}}) where {V} = ndims(V)

function moveto(vec::Vector, device::GPUThread)
    return vec
end

function moveto(vec::Vector, task::GPUThreadThread)
    return copy(vec)
end

function moveto(vec::GPUThreadLocalVector, task::GPUThreadThread)
    return vec.data[task.tid]
end
