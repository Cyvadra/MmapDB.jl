module Table__tName__
using Mmap; import Mmap:mmap
using JLD2
using ProgressMeter

Config      = Dict{String,Any}(
	"dataFolder" => "__ConfigDataFolder__" * "__tName__" * "/",
	"lastNewID"  => 0,
	"cacheModuleFile" => "__ConfigModuleFile__",
)
# openedFiles = Dict{Symbol, IOStream}()
openedFiles = IOStream[]
idLock      = Threads.SpinLock()

function _cleanCache()
	rm(Config["cacheModuleFile"])
	end
atexit(_cleanCache)
