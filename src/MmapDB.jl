module MmapDB

	using Mmap; using Mmap: mmap
	using ProgressMeter
	using JSON

	# export something

	Config = Dict{String,Any}(
			"IsInitialized" => false,
			"DataFolder"    => "/tmp/Finance.jl/mmap/"
		)

	mutable struct Sequence
		name::String
		nrows_valid::Int64
		nrows_capacity::Int64
		elements_type::Vector{DataType}
		elements_size::Vector{Int32}
		elements_bytes::Int32
		end
	openedFiles = Dict{String, IOStream}()
	openedSequences = Dict{String, Sequence}()

	function Init(folderPath::String)::String
		if folderPath[end] !== '/'
			folderPath = folderPath * '/'
		end
		Config["DataFolder"] = folderPath
		if !isdir(folderPath)
			folderPath = mkdir(Config["DataFolder"])
		end
		Config["IsInitialized"] = true
		return folderPath
		end
	function initCheck()
		if !Config["IsInitialized"]; throw("SetDataFolder first!"); end
		end

	# Create
	function SaveSequence!(dataName::String, v::Vector)::Nothing
		# check
		initCheck()
		T = typeof(v[1])
		if isprimitivetype(T)
			throw("primitive types not implemented")
		end
		if !all(isprimitivetype.(T.types))
			throw("complex structures not implemented!")
		end
		# prepare for creating files
		if !isdir(Config["DataFolder"] * string(T))
			mkdir(Config["DataFolder"] * string(T))
		end
		fnameBase = Config["DataFolder"] * "$T/$dataName"
		fnameData = fnameBase * ".bin"
		fnameLayout = fnameBase * ".layout"
		# init io stream
		io    = open(fnameData, "w+")
		seq   = Sequence(
				dataName,
				length(v),
				length(v),
				collect(T.types),
				map(x->x.size, T.types),
				sum(map(x->x.size, T.types)),
			)
		# write layout file
			write(fnameLayout, JSON.json(seq))
		# write data
		openedFiles[dataName] = io
		prog = ProgressMeter.Progress(length(v); barlen=64)
		for element in v
			unsafe_write(io, convert(Ptr{T}, pointer_from_objref(element)), seq.elements_bytes)
			next!(prog)
		end
		openedSequences[dataName] = seq
		return nothing
		end

	# Debug
	function GetAllSequence(dataName::String, elementType::DataType)::Vector
		# check
		initCheck()
		T = elementType
		if isprimitivetype(T)
			throw("not implemented")
		end
		# load
		fnameBase = Config["DataFolder"] * "$T/$dataName"
		fnameData = fnameBase * ".bin"
		_sizes = map(x->x.size, T.types)
		_bytes = sum(_sizes)
		# load io
		io = open(fnameData, "r")
		vSize = round(Int, filesize(io) / _bytes)
		_len  = length(_sizes)
		vec   = Vector{T}(undef,vSize)
		for i in 1:vSize
			vec[i] = T(zeros(_len)...)
		end
		# load data
		prog  = ProgressMeter.Progress(vSize; barlen=64)
		for i in 1:vSize
			p = convert(Ptr{T}, pointer_from_objref(vec[i]))
			unsafe_read(io, p, _bytes)
			next!(prog)
		end
		return vec
		end

	# inner call
	function OpenSequence(dataName::String, elementType::DataType)::Sequence
		# check
		initCheck()
		T = elementType
		if isprimitivetype(T)
			throw("not implemented")
		end
		# load
		fnameBase = Config["DataFolder"] * "$T/$dataName"
		fnameData = fnameBase * ".bin"
		_sizes = map(x->x.size, T.types)
		_bytes = sum(_sizes)
		# load io
		io = open(fnameData, "r+")
		vSize = round(Int, filesize(io) / _bytes)
		_len  = length(_sizes)
		openedFiles[dataName] = io
		openedSequences[dataName] = Sequence(
				dataName,
				vSize,
				vSize,
				eval.(Symbol.(collect(T.types))),
				_sizes,
				_bytes,
			)
		return openedSequences[dataName]
		end

	# Get
	function GetI(dataName::String, T::DataType, i::Int)
		if !haskey(openedFiles, dataName)
			OpenSequence(dataName, T)
		end
		seq = openedSequences[dataName]
		io = openedFiles[dataName]
		numElements = round(Int, filesize(io)/seq.elements_bytes)
		if i <= 0 || i > numElements
			throw("i from 1 to $numElements")
		end
		seek(io, (i-1)*seq.elements_bytes)
		ret = T(zeros(length(T.types))...)
		p = convert(Ptr{T}, pointer_from_objref(ret))
		unsafe_read(io, p, seq.elements_bytes)
		return ret
		end
	function GetRange(dataName::String, T::DataType, nFrom::Int, nTo::Int)::Vector
		# load file
		if !haskey(openedFiles, dataName)
			OpenSequence(dataName, T)
		end
		seq = openedSequences[dataName]
		io = openedFiles[dataName]
		# check params
		numElements = round(Int, filesize(io)/seq.elements_bytes)
		if nFrom <= 0 || nTo <= 0
			throw("index incorrect! should start from one.")
		elseif nFrom > numElements && nTo > numElements
			throw("index out of range! max $numElements")
		end
		# set params
		nLen  = nTo - nFrom + 1
		nFrom = (nFrom-1)*seq.elements_bytes
		nTo   = (nTo-1)*seq.elements_bytes
		nBytes= nLen * seq.elements_bytes
		seek(io, nFrom)
		# init empty structures
		_len  = length(seq.elements_type)
		vec   = [ T(zeros(_len)...) for i in 1:nLen ]
		for i in 1:nLen
			p = convert(Ptr{T}, pointer_from_objref(vec[i]))
			unsafe_read(io, p, seq.elements_bytes)
		end
		return vec
		end
	function GetRange(dataName::String, T::DataType, r::UnitRange)::Vector
		return GetRange(dataName, T, r[1], r[end])
		end

	# Update
	function UpdateI(dataName::String, i::Int, v)
		T = typeof(v)
		seq = openedSequences[dataName]
		io = openedFiles[dataName]
		numElements = round(Int, filesize(io)/seq.elements_bytes)
		if i <= 0 || i > numElements
			throw("i from 1 to $numElements")
		end
		seek(io, (i-1)*seq.elements_bytes)
		ret = T(zeros(length(T.types))...)
		# p = convert(Ptr{T}, pointer_from_objref(ret))
		# unsafe_read(io, p, seq.elements_bytes)
		unsafe_write(io, convert(Ptr{T}, pointer_from_objref(v)), seq.elements_bytes)
		return v
		end


end # module
