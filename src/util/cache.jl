using Scratch
cache_dir = joinpath(Scratch.dir, "cache")
using Pkg.TOML, Scratch
using Fil

# This will be filled in by `__init__()`; it might change if we get deployed somewhere
const version_specific_scratch = Ref{String}()

function __init__()
    # This space will be unique between versions of my package that different major and
    # minor versions, but allows patch releases to share the same.
    scratch_name = "data_for_version-$(pkg_version.major).$(pkg_version.minor)"
    global version_specific_scratch[] = @get_scratch!(scratch_name)
end

# This space will be unique between versions of my package that different major and
# minor versions, but allows patch releases to share the same.
scratch_name = "finch-$(finch_version.major).$(finch_version.minor)"


const SHOULD_CACHE = @load_preference("should_cache", FINCH_INFO.is_tracking_registry)
const VERSION_DIR = joinpath("Finch-$(FINCH_VERSION.major).$(FINCH_VERSION.minor)", "Julia-$(VERSION.major).$(VERSION.minor)")
const CACHE_NAMESPACE = UUID("b4173593-7d23-4d3a-8434-dd65fc2d3186")
struct DiskCache{K, V}
    chip = Dict{K, Any}()
    path::String
end
CompileCache{String, V}(space) where {K, V} = DiskCache{K, V}(joinpath(
    @get_scratch!("compiled")
    "Finch-$(FINCH_VERSION.major).$(FINCH_VERSION.minor)",
    "Julia-$(VERSION.major).$(VERSION.minor)",
    space))


const on_chip = Dict{String, Any}()
function cache!(f, key)
    if !SHOULD_CACHE
        return f()
    end
    get!(on_chip, key) do
        cache_path = joinpath(@get_scratch!("cache"), VERSION_DIR)
        mkpath(cache_path)
        name = string(uuid5(CACHE_NAMESPACE, string(key)))
        lock_file = joinpath(cache_path, name * ".pid")
        data_file = joinpath(cache_path, name * ".jls")
        mkpidlock(lock_file, stale_age=10) do 
            if isfile(data_file)
                return deserialize(data_file)
            else
                result = f()
                serialize(data_file, result)
                return result
            end
        end
    end
end

end # module