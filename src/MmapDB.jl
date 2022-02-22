module MmapDB

using Mmap; using Mmap:mmap

Config = Dict{String,Any}(
	# mark
		"isInitiated" => false,
	# where db data shall be saved
		"dataFolder"  => "/mnt/data/test/",
	# where generated files are writed into
		"cacheFolder" => "/tmp/",
	)

function GenerateCode(T::DataType)
	if !IsInitiated()
		throw("Init data folder first!")
	end
	# base values
		tName = string(T)
		tmpNames = string.(fieldnames(T))
		tmpNamesU= uppercasefirst.(tmpNames)
		tmpTypes = string.(T.types)
	f = open(Config["cacheFolder"] * tName * ".jl", "w+")
	# module header
		write(f, "module Table$(tName)\n")
		write(f, "using Mmap; import Mmap:mmap\n\n")
	# copy config
		write(f, "Config = Dict{String,Any}(\"dataFolder\" => \"$(Config["dataFolder"]*tName*"/")\")\n")
		write(f, "openedFiles = Dict{Symbol, IOStream}()\n")
		write(f, "\n")
	# copy structure
		write(f, "mutable struct $(tName)ReadOnly\n")
		s = ""
		for i in 1:length(tmpTypes)
			s *= "\t$(tmpNames[i])::$(tmpTypes[i])\n"
		end
		s *= "end\n"
		write(f, s)
		s = ""
	# type definitions
		write(f, "$(tName)Dict = Dict{Symbol, Base.RefValue}()\n")
		write(f, "_syms  = fieldnames($(tName)ReadOnly)\n")
		write(f, "_types = Vector{DataType}(collect($(tName)ReadOnly.types))\n")
		write(f, "@assert all(isprimitivetype.(_types))\n")
		write(f, "\n")
	# basic functions
		write(f, """function Create!(numRows::Int)::Nothing
				# check params
				dataFolder = Config["dataFolder"]
				dataFolder[end] !== '/' ? dataFolder = dataFolder*"/" : nothing
				isdir(dataFolder) || mkdir(dataFolder)
				for i in 1:length(_types)
					f = open(dataFolder*string(_syms[i])*".bin", "w+")
					openedFiles[_syms[i]] = f
					$(tName)Dict[_syms[i]] = Ref(mmap(
						f, Vector{_types[i]}, numRows; grow=true, shared=false
						))
				end
				write(dataFolder*"_num_rows", string(numRows))
				return nothing
				end
			function Open(numRows::Int)::Nothing
				dataFolder = Config["dataFolder"]
				# check params
				dataFolder[end] !== '/' ? dataFolder = dataFolder*"/" : nothing
				isdir(dataFolder) || mkdir(dataFolder)
				for i in 1:length(_types)
					f = open(dataFolder*string(_syms[i])*".bin", "r+")
					openedFiles[_syms[i]] = f
					$(tName)Dict[_syms[i]] = Ref(mmap(
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
	# module end
		write(f, "\nend\n\n")
	close(f)
	@info "Loading module Table$(tName)"
	return Main.include(Config["cacheFolder"] * tName * ".jl")
	end

function Init(dataFolder::String, cacheFolder::String="/tmp/")::Bool
	dataFolder[end] !== '/' ? dataFolder *= "/" : nothing
	cacheFolder[end] !== '/' ? cacheFolder *= "/" : nothing
	isdir(dataFolder) || mkdir(dataFolder)
	isdir(cacheFolder) || mkdir(cacheFolder)
	Config["isInitiated"] = true
	Config["dataFolder"]  = dataFolder
	Config["cacheFolder"] = cacheFolder
	return true
	end

function IsInitiated()::Bool
	return Config["isInitiated"]
	end











end
