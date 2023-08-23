abstract type AbstractArchitecture end

struct Serial <: AbstractArchitecture end
const serial = Serial()
struct Threaded <: AbstractArchitecture end
const threaded = Threaded()
struct NvidiaGPU <: AbstractArchitecture end
const nvidiagpu = NvidiaGPU()

is_serial(arch::Serial) = true
is_serial(arch::Threaded) = false

struct FinchArchitectureError msg end