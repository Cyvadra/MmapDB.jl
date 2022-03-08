# MmapDB.jl

## Usage
```julia
using MmapDB
# set data folder for storage
MmapDB.Init(homedir()*"/Desktop/test")

mutable struct Something
	region_id::UInt8
	longitude::Float64
	latitude::Float64
	timestamp::Int64
	end
t = MmapDB.GenerateCode(Something)
# auto generated TableSomething in Main module
# you can use TableSomething or your custom var name directly

# create a table for maximum 10000 rows
TableSomething.Create!(10000)
# use tab to show all generated methods!
# TableSomething.SetRow(i, any_struct_compatible)
# TableSomething.SetFieldTimestamp(i, ...)

# next time directly open db file
# files are loaded from the path initiated in mmap, can be over-written
TableSomething.Open()


```











## Todos

0. [x] Wrap into sub modules.
1. [x] Separate and migrate current(private) db service to here.
2. [ ] Split files into multiple, so as to prevent ssd write amplification.
3. [x] Support storage of different data types, may include non-primitive. (cancelled)
5. [x] Extract template file as an individual file to support better coding experience, consider using MVC?


99. [ ] Consider build a private layer of memory cache, then disable real-time synchronization on disk.

