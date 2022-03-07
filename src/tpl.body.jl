
__tName__Dict = Dict{Symbol, Any}()
_syms  = fieldnames(__tName__ReadOnly)
_types = Vector{DataType}(collect(__tName__ReadOnly.types))
@assert all(isprimitivetype.(_types))

# Mmap logic
	function Create!(numRows::Int)::Nothing
		# check params
		dataFolder = "__ConfigDataFolder__"
		dataFolder[end] !== '/' ? dataFolder = dataFolder*"/" : nothing
		isdir(dataFolder) || mkdir(dataFolder)
		for i in 1:length(_types)
			f = open(dataFolder*string(_syms[i])*".bin", "w+")
			openedFiles[_syms[i]] = f
			__tName__Dict[_syms[i]] = mmap(
				f, Vector{_types[i]}, numRows; grow=true, shared=true
				)
		end
		write(dataFolder*"_num_rows", string(numRows))
		return nothing
		end
	function Open(shared::Bool=true)::Nothing
		dataFolder = "__ConfigDataFolder__"
		# check params
		dataFolder[end] !== '/' ? dataFolder = dataFolder*"/" : nothing
		isdir(dataFolder) || mkdir(dataFolder)
		numRows = parse(Int, read(dataFolder*"_num_rows",String))
		for i in 1:length(_types)
			f = open(dataFolder*string(_syms[i])*".bin", "r+")
			openedFiles[_syms[i]] = f
			__tName__Dict[_syms[i]] = mmap(
				f, Vector{_types[i]}, numRows; grow=false, shared=shared
				)
		end
		return nothing
		end

# Memory logic
	function CreateMem(numRows::Int)::Nothing
		# check params
		for i in 1:length(_types)
			haskey(openedFiles, _syms[i]) && close(openedFiles[_syms[i]])
			__tName__Dict[_syms[i]] = zeros(_types[i], numRows)
		end
		return nothing
		end
	function SaveJLD(dataFolder::String="__ConfigDataFolder__")::Nothing
		# check params
		dataFolder[end] !== '/' ? dataFolder = dataFolder*"/" : nothing
		isdir(dataFolder) || mkdir(dataFolder)
		numRows = length(__tName__Dict[_syms[1]])
		for i in 1:length(_syms)
			JLD2.save(
				dataFolder * string(_syms[i]) * ".jld2",
				string(_syms[i]),
				__tName__Dict[_syms[i]]
			)
		end
		write(dataFolder*"_num_rows", string(numRows))
		return nothing
		end
	function OpenJLD(dataFolder::String="__ConfigDataFolder__")::Nothing
		dataFolder[end] !== '/' ? dataFolder = dataFolder*"/" : nothing
		isdir(dataFolder) || mkdir(dataFolder)
		for i in 1:length(_syms)
			__tName__Dict[_syms[i]] = JLD2.load(
				dataFolder * string(_syms[i]) * ".jld2",
			)[string(_syms[i])]
		end
		return nothing
		end




	function GetField(sym::Symbol, i)
		return __tName__[sym][i]
		end
	function GetField(sym::Symbol, ids::Vector)::Vector
		return __tName__[sym][ids]
		end
	function SetField(sym::Symbol, i, v)::Nothing
		__tName__[sym][i] = v
		return nothing
		end
	function SetFieldDiff(sym::Symbol, i, v)::Nothing
		__tName__[sym][i] += v
		return nothing
		end
