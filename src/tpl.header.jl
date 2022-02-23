module Table__tName__
using Mmap; import Mmap:mmap

Config      = Dict{String,Any}("dataFolder" => "__ConfigDataFolder__" * "__tName__" * "/" )
openedFiles = Dict{Symbol, IOStream}()
