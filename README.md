# MmapDB.jl

[![Build Status](https://github.com/Cyvadra/MmapDB.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Cyvadra/MmapDB.jl/actions/workflows/CI.yml?query=branch%3Amain)

## Usage
```julia
using MmapDB

# set data folder for storage
MmapDB.Init(homedir()*"/Desktop/test")

mutable struct Something
	# all subtypes should be primitive
	region_id::UInt8
	longitude::Float64
	latitude::Float64
	timestamp::Int64
	end
t = MmapDB.GenerateCode(Something)
# auto generated TableSomething in Main module
# you can also use custom var name for convenience

# create a table for maximum 10000 rows
TableSomething.Create!(10000) # mmap generated
# TableSomething.		# use tab to show all generated methods
# TableSomething.SetRow(id, any_struct_compatible)
# TableSomething.SetFieldTimestamp(id, ...)
# TableSomething.GetRow(id)::Main.Something
# TableSomething.GetFieldTimestamp(id/range/vector)::Int64/Vector{Int64}

# next time directly open db file
TableSomething.Open(false) # using true for persistance, false for read only


```











## Todos

1. [ ] Support string field.
2. [ ] Split date files into multiple.

8. [ ] Time sequence optimization. (move to private repo)
99. [ ] Consider build a private layer of memory cache, then disable real-time synchronization on disk. (deprecated)

