module MmapDB

	using Mmap; using Mmap:mmap

	Config = Dict{String,Any}(
		# where db data shall be saved
			"dataFolder"  => "/mnt/data/test/",
		# where generated files are writed into
			"cacheFolder" => "/tmp/",
		)
	openedFiles = Dict{Symbol, IOStream}()

	function GenerateCode(T::DataType)::String
		tName = string(T)
		f = open(Config["cacheFolder"] * tName * ".jl", "w+")
		# type definitions
		write(f, "$(tName)Dict = Dict{Symbol, Base.RefValue}()\n")
		write(f, "$(tName)ReadOnly = $(tName)\n")
		write(f, "_syms  = fieldnames($(tName)ReadOnly)\n")
		write(f, "_types = Vector{DataType}(collect($(tName)ReadOnly.types))\n")
		write(f, "@assert all(isprimitivetype.(_types)\n")
		write(f, "\n")
		# basic functions
		write(f, """function Create!(dataFolder::String=Config["dataFolder"], numRows::Int=Config["dataLength"])::Nothing
				# check params
				dataFolder[end] !== '/' ? dataFolder = dataFolder*"/" : nothing
				isdir(dataFolder) || mkdir(dataFolder)
				for i in 1:length(_types)
					f = open(dataFolder*string(_syms[i])*".bin", "w+")
					openedFiles[_syms[i]] = f
					$(tName)[_syms[i]] = Ref(mmap(
						f, Vector{_types[i]}, numRows; grow=true, shared=false
						))
				end
				write(dataFolder*"_num_rows", string(numRows))
				return nothing
				end
			function Open(dataFolder::String=Config["dataFolder"], numRows::Int=Config["dataLength"])::Nothing
				# check params
				dataFolder[end] !== '/' ? dataFolder = dataFolder*"/" : nothing
				isdir(dataFolder) || mkdir(dataFolder)
				for i in 1:length(_types)
					f = open(dataFolder*string(_syms[i])*".bin", "r+")
					openedFiles[_syms[i]] = f
					$(tName)[_syms[i]] = Ref(mmap(
						f, Vector{_types[i]}, numRows; grow=false, shared=false
						))
				end
				write(dataFolder*"_num_rows", string(numRows))
				return nothing
				end

			function GetField(sym::Symbol, i)
				return $(tName)[sym][][i]
				end
			function GetField(sym::Symbol, ids::Vector)::Vector
				return $(tName)[sym][][ids]
				end
			function SetField(sym::Symbol, i, v)::Nothing
				$(tName)[sym][][i] = v
				return nothing
				end
			function SetFieldDiff(sym::Symbol, i, v)::Nothing
				$(tName)[sym][][i] += v
				return nothing
				end

			""")
		# restore structure
		s = "
			function GetRow(i)::$(tName)ReadOnly
				$(tName)ReadOnly("
		tmpNames = string.(fieldnames(T))
		tmpNamesU= uppercasefirst.(tmpNames)
		tmpTypes = string.(T.types)
		for i in 1:length(T.types)
			s *= "
					$(tName)Dict[:$(tmpNames[i])][][i],"
		end
		s *= "
					)
				end"
		write(f, s)
		# extensive
		s = ""
		for i in 1:length(T.types)
			s *= "

			function GetField$(tmpNamesU[i])(i)::$(tmpTypes[i])
				return $(tName)Dict[:$(tmpNames[i])][][i]
				end
			function SetField$(tmpNamesU[i])(i, v)::Nothing
				$(tName)Dict[:$(tmpNames[i])][][i] = v
				return nothing
				end
			function SetFieldDiff$(tmpNamesU[i])(i, v)::Nothing
				$(tName)Dict[:$(tmpNames[i])][][i] += v
				return nothing
				end
			"
		end
		write(f, s)
		close(f)
		return Config["cacheFolder"] * tName * ".jl"
	end















end
