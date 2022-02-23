
__tName__Dict = Dict{Symbol, Base.RefValue}()
_syms  = fieldnames(__tName__ReadOnly)
_types = Vector{DataType}(collect(__tName__ReadOnly.types))
@assert all(isprimitivetype.(_types))

	function Create!(numRows::Int)::Nothing
		# check params
		dataFolder = __ConfigDataFolder__
		dataFolder[end] !== '/' ? dataFolder = dataFolder*"/" : nothing
		isdir(dataFolder) || mkdir(dataFolder)
		for i in 1:length(_types)
			f = open(dataFolder*string(_syms[i])*".bin", "w+")
			openedFiles[_syms[i]] = f
			__tName__Dict[_syms[i]] = Ref(mmap(
				f, Vector{_types[i]}, numRows; grow=true, shared=true
				))
		end
		write(dataFolder*"_num_rows", string(numRows))
		return nothing
		end
	function Open(numRows::Int)::Nothing
		dataFolder = __ConfigDataFolder__
		# check params
		dataFolder[end] !== '/' ? dataFolder = dataFolder*"/" : nothing
		isdir(dataFolder) || mkdir(dataFolder)
		for i in 1:length(_types)
			f = open(dataFolder*string(_syms[i])*".bin", "r+")
			openedFiles[_syms[i]] = f
			__tName__Dict[_syms[i]] = Ref(mmap(
				f, Vector{_types[i]}, numRows; grow=false, shared=true
				))
		end
		write(dataFolder*"_num_rows", string(numRows))
		return nothing
		end

	function GetField(sym::Symbol, i)
		return __tName__[sym][][i]
		end
	function GetField(sym::Symbol, ids::Vector)::Vector
		return __tName__[sym][][ids]
		end
	function SetField(sym::Symbol, i, v)::Nothing
		__tName__[sym][][i] = v
		return nothing
		end
	function SetFieldDiff(sym::Symbol, i, v)::Nothing
		__tName__[sym][][i] += v
		return nothing
		end
