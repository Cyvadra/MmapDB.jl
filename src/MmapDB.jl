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

function GenerateCode(T::DataType)::Module
	if !IsInitiated()
		throw("Init data folder first!")
	end
	# base values
		tName = string(T)
		tmpNames = string.(fieldnames(T))
		tmpNamesU= uppercasefirst.(tmpNames)
		tmpTypes = string.(T.types)
	f = open(Config["cacheFolder"] * tName * ".jl", "w+")
	# header
	s = read("./tpl.header.jl", String)
	s = replace(s, "__tName__" => tName)
	s = replace(s, "__ConfigDataFolder__" => Config["dataFolder"])
	write(f, s)
	# generate structure
		write(f, "mutable struct $(tName)ReadOnly\n")
		s = ""
		for i in 1:length(tmpTypes)
			s *= "\t$(tmpNames[i])::$(tmpTypes[i])\n"
		end
		s *= "end\n"
		write(f, s)
		s = ""
	# body
	s = read("./tpl.body.jl", String)
	s = replace(s, "__tName__" => tName)
	s = replace(s, "__ConfigDataFolder__" => Config["dataFolder"])
	write(f, s)
	# get function
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
	# extensive functions
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
