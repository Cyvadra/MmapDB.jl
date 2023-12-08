
__tName__Dict = Dict{Symbol, Any}()
_syms  = fieldnames(__tName__)
_types = Vector{DataType}(collect(__tName__.types))
@assert all(isprimitivetype.(_types))
dataFolder = "__ConfigDataFolder__"

# Mmap logic
	function UpdateCompatity()::Nothing
		write(dataFolder*"_types",
			join([ string(_syms[i]) * "," * string(_types[i]) for i in 1:length(_types) ], "\n")
		)
		return nothing
		end
	function calcChunkSize(t::DataType, sizeChunkGB::Int)::Int
		expBytes = trailing_zeros(sizeof(rand(t)))
		if !iszero(expBytes)
			capacityChunk = (sizeChunkGB << 30) >> expBytes
		else
			capacityChunk = round(Int, sizeChunkGB << 30 / sizeof(rand(t)))
		end
		end
	function genChunks(numRows::Int, capacityChunk::Int)::Vector{UnitRange{Int}}
		tmpInds = collect(1:capacityChunk:numRows)
		map(x->x:x+capacityChunk-1, tmpInds)
		end
	function Create!(numRows::Int, sizeChunkGB::Int=2)::Nothing
		for i in 1:length(_types)
			f = open(dataFolder*string(_syms[i])*".bin", "w+")
			push!(openedFiles,f)
			__tName__Dict[_syms[i]] = mmap(
				f, Vector{_types[i]}, numRows; grow=true, shared=true
				)
		end
		UpdateCompatity()
		write(dataFolder*"_num_rows", string(numRows))
		return nothing
		end
	function Open(shared::Bool=true)::Nothing
		numRows = parse(Int, read(dataFolder*"_num_rows",String))
		for i in 1:length(_types)
			f = open(dataFolder*string(_syms[i])*".bin", "r+")
			push!(openedFiles,f)
			__tName__Dict[_syms[i]] = mmap(
				f, Vector{_types[i]}, numRows; grow=true, shared=shared
				)
		end
		alignAI()
		return nothing
		end
	function Close()::Nothing
		close.(openedFiles); empty!(openedFiles)
		empty!(__tName__Dict)
		Config["lastNewID"] = 0
		return nothing
		end

# Memory logic
	function CreateMem(numRows::Int)::Nothing
		close.(openedFiles); empty!(openedFiles)
		for i in 1:length(_types)
			__tName__Dict[_syms[i]] = zeros(_types[i], numRows)
		end
		return nothing
		end
	function SaveMem(dataFolder::String="__ConfigDataFolder__")::Nothing
		dataFolder[end] !== '/' ? dataFolder *= "/" : nothing
		isdir(dataFolder) || mkdir(dataFolder)
		numRows = length(__tName__Dict[_syms[1]])
		write(dataFolder*"_num_rows", string(numRows))
		for i in 1:length(_syms)
			path = dataFolder * string(_syms[i]) * ".bin"
			f = open(path, "w+")
			m = mmap(f, Vector{_types[i]}, numRows; grow=true, shared=true)
			m .= __tName__Dict[_syms[i]]
			fz = Float16(filesize(path) / 1024^3)
			@info "written $(fz)GB to $path"
		end
		return nothing
		end
	function SaveCopy(dataFolder::String="__ConfigDataFolder___copy/")::Nothing # when Open(shared=false)
		dataFolder = replace(dataFolder, "/"=>"") * "/"
		isdir(dataFolder) || mkdir(dataFolder)
		numRows = length(__tName__Dict[_syms[1]])
		if filesize(dataFolder*"_num_rows") > 0
			@warn "file already exist! $dataFolder"
			@warn "press y and enter for confirmation"
			s = readline()
			if uppercase(s)[1] !== 'Y'
				@info "cancelled"
				return nothing
			end
		end
		write(dataFolder*"_num_rows", string(numRows))
		for i in 1:length(_syms)
			path = dataFolder * string(_syms[i]) * ".bin"
			f = open(path, "w+")
			m = mmap(f, Vector{_types[i]}, numRows; grow=true, shared=true)
			m .= __tName__Dict[_syms[i]]
			fz = Float16(filesize(path) / 1024^3)
			@info "written $(fz)GB to $path"
		end
		return nothing
		end		
	function SaveJLD(dataFolder::String="__ConfigDataFolder__")::Nothing
		dataFolder[end] !== '/' ? dataFolder *= "/" : nothing
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
		dataFolder[end] !== '/' ? dataFolder *= "/" : nothing
		for i in 1:length(_syms)
			__tName__Dict[_syms[i]] = JLD2.load(
				dataFolder * string(_syms[i]) * ".jld2",
			)[string(_syms[i])]
		end
		alignAI()
		return nothing
		end
	function alignAI()
		assumeI = findlast(x->!iszero(x), __tName__Dict[_syms[1]])
		if all(iszero.(
				map(s->__tName__Dict[s][assumeI+1], _syms)
			))
			Config["lastNewID"] = assumeI
		else
			assumeI = findlast(x->!iszero(x), __tName__Dict[_syms[end]])
			@assert all(iszero.(
				map(s->__tName__Dict[s][assumeI+1], _syms)
			))
			Config["lastNewID"] = assumeI
		end
		end




	function GetField(sym::Symbol, i)
		return __tName__Dict[sym][i]
		end
	function GetField(sym::Symbol, ids::Vector)::Vector
		return __tName__Dict[sym][ids]
		end
	function SetField(sym::Symbol, i, v)::Nothing
		__tName__Dict[sym][i] = v
		return nothing
		end
	function SetFieldDiff(sym::Symbol, i, v)::Nothing
		__tName__Dict[sym][i] += v
		return nothing
		end


	function FunctionOnField(f::Function, sym::Symbol)::Vector
		return f(__tName__Dict[sym])
		end
	function mapFunctionOnField(f::Function, sym::Symbol)::Vector
		return map(f, __tName__Dict[sym])
		end
	function mapFunctionOnFieldIds(f::Function, sym::Symbol, ids)::Vector
		return map(f, __tName__Dict[sym][ids])
		end

	function Findfirst(f, sym::Symbol)
		return findfirst(f, __tName__Dict[sym])
		end
	function Findlast(f, sym::Symbol)
		return findlast(f, __tName__Dict[sym])
		end
	function Findnext(f, sym::Symbol, n::Int)
		return findnext(f, __tName__Dict[sym], n)
		end

	function SearchSorted(v, sym::Symbol)
		return searchsorted(__tName__Dict[sym], v)
		end
	function SearchSortedFirst(v, sym::Symbol)
		return searchsortedfirst(__tName__Dict[sym], v)
		end
	function SearchSortedLast(v, sym::Symbol)
		return searchsortedlast(__tName__Dict[sym], v)
		end

