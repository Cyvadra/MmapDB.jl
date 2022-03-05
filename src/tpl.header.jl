module Table__tName__
using Mmap; import Mmap:mmap
using JLD2

Config      = Dict{String,Any}("dataFolder" => "__ConfigDataFolder__" * "__tName__" * "/" )
openedFiles = Dict{Symbol, IOStream}()
